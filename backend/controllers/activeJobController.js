import Booking from '../models/Booking.js';
import User from '../models/User.js';
import redis from '../config/redis.js';
import { notifyUser, safeNotify } from '../services/notificationService.js';
import { getTargetBookingRooms } from '../sockets/tracking.js';

// 1. Worker Accepts Booking Request (transitions SEARCHING -> ACCEPTED with Distributed Lock & Concurrency Control)
export const acceptBooking = async (req, res) => {
    // #swagger.tags = ['Active Jobs']
    // #swagger.description = 'Worker accepts booking request with Redis distributed lock & atomic concurrency control'
    // #swagger.parameters['bookingId'] = { in: 'path', description: 'Booking ID', required: true, type: 'string' }
    const { bookingId } = req.params;
    const workerId = req.user.id; // From protect middleware
    const lockKey = `lock:booking:accept:${bookingId}`;
    let lockAcquired = false;

    try {
        // Step 1: Ensure this worker is not already on another active booking
        const alreadyBusy = await Booking.findOne({
            worker: workerId,
            status: { $in: ['APPROVED', 'ACCEPTED', 'ARRIVED', 'IN_PROGRESS'] },
            _id: { $ne: bookingId }
        });
        if (alreadyBusy) {
            return res.status(400).json({
                success: false,
                code: 'WORKER_ALREADY_BUSY',
                message: 'Aap pehle se ek doosre customer ke active kaam par vyast hain. Kripya pehle use poora karein.'
            });
        }

        // Step 2: Distributed Lock via Redis (Microsecond mutex across all AWS clustered instances)
        try {
            const acquired = await redis.set(lockKey, workerId, 'NX', 'EX', 5);
            if (!acquired) {
                return res.status(409).json({
                    success: false,
                    code: 'BOOKING_ALREADY_CLAIMED',
                    message: 'Yeh booking kisi doosre worker ne pehle hi accept kar li hai.'
                });
            }
            lockAcquired = true;
        } catch (redisErr) {
            console.warn('Redis locking bypassed, relying on MongoDB atomic update:', redisErr.message);
        }

        // Step 3: Atomic Database Update (transitions PENDING / SEARCHING -> APPROVED)
        const booking = await Booking.findOneAndUpdate(
            {
                _id: bookingId,
                status: { $in: ['PENDING', 'SEARCHING'] },
                $or: [{ worker: null }, { worker: workerId }]
            },
            {
                $set: {
                    worker: workerId,
                    status: 'APPROVED'
                }
            },
            { returnDocument: 'after' }
        );

        if (!booking) {
            return res.status(409).json({
                success: false,
                code: 'BOOKING_ALREADY_CLAIMED',
                message: 'Yeh booking kisi doosre worker ne pehle hi accept kar li hai.'
            });
        }

        // Step 4: Real-time Broadcast via Socket.io
        const io = req.app.get('io');
        if (io) {
            // A. Notify specific booking room (customer & accepted worker)
            io.to(`booking_${bookingId}`).emit('booking_status_update', {
                bookingId,
                status: 'APPROVED',
                workerId
            });

            // B. Broadcast to ALL workers in real-time so their UI instantly drops/hides this booking card
            io.emit('booking:claimed', {
                bookingId,
                status: 'APPROVED',
                claimedBy: workerId
            });

            // C. Broadcast availability change: this worker is now BUSY
            io.emit('worker:availability_changed', {
                workerId: String(workerId),
                isAvailable: false,
                status: 'BUSY'
            });
        }

        safeNotify(() => notifyUser({
            recipient: booking.customer,
            eventType: 'BOOKING_ACCEPTED',
            entityId: booking._id,
            bookingId: booking._id,
            dedupeKey: `BOOKING_ACCEPTED:${booking._id}:${workerId}`,
        }));

        return res.status(200).json({ success: true, message: 'Booking accepted successfully', booking });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    } finally {
        // Step 5: Cleanly release Redis lock
        if (lockAcquired) {
            try {
                await redis.del(lockKey);
            } catch (_) {}
        }
    }
};

// 2. Verify Worker Arrival (OTP) (transitions ACCEPTED -> ARRIVED)
export const verifyArrivalOtp = async (req, res) => {
    // #swagger.tags = ['Active Jobs']
    // #swagger.parameters['body'] = { in: 'body', description: 'Verify OTP Input', required: true, schema: { $ref: '#/definitions/VerifyArrivalOtpInput' } }
    try {
        const { bookingId } = req.params;
        const { otp } = req.body;

        const booking = await Booking.findById(bookingId);
        if (!booking) return res.status(404).json({ success: false, message: 'Booking not found' });

        // OTP verification logic (with fallback for testing)
        const testOtp = process.env.TEST_ARRIVAL_OTP || '8492';
        const otpStr = otp ? otp.toString() : '';
        const bookingOtpStr = booking.arrivalOtp ? booking.arrivalOtp.toString() : '';
        if (otpStr !== testOtp && otpStr !== bookingOtpStr) {
            return res.status(400).json({ success: false, message: 'Invalid Secure PIN' });
        }

        booking.status = 'IN_PROGRESS';
        booking.jobStartedAt = booking.jobStartedAt || Date.now();
        await booking.save();

        // Notify client via Socket.io
        const io = req.app.get('io');
        if (io) {
            const targetRooms = [
                ...getTargetBookingRooms(bookingId),
                ...getTargetBookingRooms(booking.bookingId),
            ];
            io.to(targetRooms).emit('booking_status_update', {
                bookingId: booking._id,
                canonicalBookingId: booking.bookingId,
                status: 'IN_PROGRESS',
                jobStartedAt: booking.jobStartedAt,
            });
        }

        safeNotify(() => notifyUser({
            recipient: booking.customer,
            eventType: 'JOB_STARTED',
            entityId: booking._id,
            bookingId: booking._id,
            dedupeKey: `JOB_STARTED:${booking._id}`,
        }));

        return res.status(200).json({ success: true, message: 'Worker arrival verified & job started', booking });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

// 3. Worker Starts the Job (transitions ARRIVED -> IN_PROGRESS)
export const startJob = async (req, res) => {
    try {
        const { bookingId } = req.params;

        const booking = await Booking.findById(bookingId);
        if (!booking) return res.status(404).json({ success: false, message: 'Booking not found' });

        if (booking.status !== 'ARRIVED') {
            return res.status(400).json({ success: false, message: 'Job can only start after worker has arrived' });
        }

        booking.status = 'IN_PROGRESS';
        booking.jobStartedAt = Date.now();
        await booking.save();

        // Notify client via Socket.io
        const io = req.app.get('io');
        if (io) {
            io.to(`booking_${bookingId}`).emit('booking_status_update', {
                bookingId,
                status: 'IN_PROGRESS',
                jobStartedAt: booking.jobStartedAt
            });
        }

        safeNotify(() => notifyUser({
            recipient: booking.customer,
            eventType: 'JOB_STARTED',
            entityId: booking._id,
            bookingId: booking._id,
            dedupeKey: `JOB_STARTED:${booking._id}`,
        }));

        return res.status(200).json({ success: true, message: 'Job started successfully', booking });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

// 4. Add Extra Parts/Services (Schema-compliant)
export const addExtraParts = async (req, res) => {
    // #swagger.tags = ['Active Jobs']
    // #swagger.parameters['body'] = { in: 'body', description: 'Add Extra Parts Input', required: true, schema: { $ref: '#/definitions/AddExtraPartsInput' } }
    try {
        const { bookingId } = req.params;
        const { extraItems } = req.body; // Array: [{ title: 'U-bend Pipe', price: 25 }]

        const booking = await Booking.findById(bookingId);
        if (!booking) return res.status(404).json({ success: false, message: 'Booking not found' });

        // Update addOns array in Booking schema
        booking.addOns = [...(booking.addOns || []), ...extraItems];

        // Recalculate extraPartsTotal and totalAmount
        const extraPartsTotal = booking.addOns.reduce((sum, item) => sum + item.price, 0);
        booking.invoice.extraPartsTotal = extraPartsTotal;
        booking.invoice.totalAmount = booking.invoice.baseServiceFee + extraPartsTotal + booking.invoice.platformFee;

        await booking.save();

        // Notify client via Socket.io
        const io = req.app.get('io');
        if (io) {
            io.to(`booking_${bookingId}`).emit('booking_status_update', {
                bookingId,
                status: booking.status,
                addOns: booking.addOns,
                invoice: booking.invoice
            });
        }

        safeNotify(() => notifyUser({
            recipient: booking.customer,
            eventType: 'INVOICE_UPDATED',
            entityId: booking._id,
            bookingId: booking._id,
            dedupeKey: `INVOICE_UPDATED:${booking._id}:${booking.updatedAt?.getTime?.() || Date.now()}`,
        }));

        return res.status(200).json({ success: true, addOns: booking.addOns, invoice: booking.invoice });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

// 5. Job Completed & Payment Generation (Schema-compliant)
export const completeJob = async (req, res) => {
    try {
        const { bookingId } = req.params;

        const booking = await Booking.findById(bookingId);
        if (!booking) return res.status(404).json({ success: false, message: 'Booking not found' });

        booking.invoice = booking.invoice || {};
        const extraPartsTotal = (booking.addOns || []).reduce((sum, item) => sum + item.price, 0);
        booking.invoice.extraPartsTotal = extraPartsTotal;
        booking.invoice.totalAmount = (booking.invoice.baseServiceFee || 0) + extraPartsTotal + (booking.invoice.platformFee || 0) + (booking.invoice.urgentFee || 0);
        await booking.save();

        if (!booking.completionOtpVerified) {
            // Worker marked done, but OTP not verified yet
            const io = req.app.get('io');
            if (io) {
                const targetRooms = [
                    ...getTargetBookingRooms(bookingId),
                    ...getTargetBookingRooms(booking.bookingId),
                ];
                io.to(targetRooms).emit('booking_completion_otp_required', {
                    bookingId: booking._id,
                    message: 'Worker has marked job done. Please provide completion OTP.'
                });
            }

            safeNotify(async () => {
                await notifyUser({
                    recipient: booking.customer,
                    eventType: 'COMPLETION_OTP_SENT',
                    entityId: booking._id,
                    bookingId: booking._id,
                    dedupeKey: `COMPLETION_OTP_SENT:${booking._id}`,
                });
            });

            return res.status(200).json({
                success: true,
                status: 'AWAITING_OTP',
                message: 'Work marked done. Awaiting customer completion OTP.',
            });
        }

        if (booking.invoice.paymentStatus !== 'PAID') {
            booking.status = 'PAYMENT_PENDING';
            await booking.save();

            const io = req.app.get('io');
            if (io) {
                const targetRooms = [
                    ...getTargetBookingRooms(bookingId),
                    ...getTargetBookingRooms(booking.bookingId),
                ];
                io.to(targetRooms).emit('booking_status_update', {
                    bookingId: booking._id,
                    canonicalBookingId: booking.bookingId,
                    status: 'PAYMENT_PENDING',
                    invoice: booking.invoice,
                });
            }

            safeNotify(async () => {
                await notifyUser({
                    recipient: booking.customer,
                    eventType: 'INVOICE_UPDATED',
                    entityId: booking._id,
                    bookingId: booking._id,
                    dedupeKey: `PAYMENT_PENDING:${booking._id}`,
                });
            });

            return res.status(200).json({
                success: true,
                status: 'PAYMENT_PENDING',
                message: 'Work completed. Awaiting customer payment.',
                booking,
            });
        }

        booking.status = 'COMPLETED';
        booking.jobCompletedAt = booking.jobCompletedAt || Date.now();
        await booking.save();

        if (booking.worker && booking.serviceAddress?.location?.coordinates?.length === 2) {
            await User.findByIdAndUpdate(booking.worker, {
                $set: {
                    location: {
                        type: 'Point',
                        coordinates: booking.serviceAddress.location.coordinates,
                    },
                },
            });
        }

        // Purge temporary live tracking cache from Redis immediately
        try {
            await redis.del(`tracking:booking:${bookingId}`);
        } catch (_) {}

        // Notify client via Socket.io
        const io = req.app.get('io');
        if (io) {
            const targetRooms = [
                ...getTargetBookingRooms(bookingId),
                ...getTargetBookingRooms(booking.bookingId),
            ];
            io.to(targetRooms).emit('booking_status_update', {
                bookingId: booking._id,
                canonicalBookingId: booking.bookingId,
                status: 'COMPLETED',
                paymentStatus: 'PAID',
                invoice: booking.invoice
            });
            // Broadcast availability change: worker has completed the job and is now FREE/AVAILABLE
            if (booking.worker) {
                io.emit('worker:availability_changed', {
                    workerId: String(booking.worker),
                    isAvailable: true,
                    status: 'AVAILABLE'
                });
            }
        }

        safeNotify(async () => {
            await notifyUser({
                recipient: booking.customer,
                eventType: 'JOB_COMPLETED',
                entityId: booking._id,
                bookingId: booking._id,
                dedupeKey: `JOB_COMPLETED:${booking._id}`,
            });
            if (booking.worker) {
                await notifyUser({
                    recipient: booking.worker,
                    eventType: 'JOB_COMPLETED',
                    entityId: booking._id,
                    bookingId: booking._id,
                    dedupeKey: `JOB_COMPLETED:${booking._id}:${booking.worker}`,
                });
            }
        });

        return res.status(200).json({ success: true, message: 'Job completed successfully', invoice: booking.invoice });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};
export const verifyCompletionOtp = async (req, res) => {
    try {
        const { bookingId } = req.params;
        const { otp } = req.body;

        const booking = await Booking.findById(bookingId);
        if (!booking) return res.status(404).json({ success: false, message: 'Booking not found' });

        if (booking.status !== 'IN_PROGRESS') {
            return res.status(400).json({ success: false, message: 'Invalid booking status for completion OTP' });
        }

        if (String(booking.completionOtp) !== String(otp)) {
            return res.status(400).json({ success: false, message: 'Invalid completion OTP' });
        }

        booking.completionOtpVerified = true;
        await booking.save();

        return res.status(200).json({ success: true, message: 'Completion OTP verified successfully' });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

export const startNavigation = async (req, res) => {
    try {
        const { bookingId } = req.params;
        const booking = await Booking.findById(bookingId);
        
        if (!booking) return res.status(404).json({ success: false, message: 'Booking not found' });
        
        if (String(booking.worker) !== String(req.user.id)) {
            return res.status(403).json({ success: false, message: 'Only assigned worker can start navigation' });
        }
        
        if (booking.status !== 'ACCEPTED') {
            return res.status(400).json({ success: false, message: 'Cannot start navigation unless booking is ACCEPTED' });
        }
        
        booking.workerNavigationStartedAt = new Date();
        await booking.save();
        
        return res.status(200).json({ success: true, message: 'Navigation started', booking });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

export const submitPriceEstimation = async (req, res) => {
    try {
        const { bookingId } = req.params;
        const { laborCost, partsEstimate, serviceCharge, notes } = req.body;
        
        const booking = await Booking.findById(bookingId);
        if (!booking) return res.status(404).json({ success: false, message: 'Booking not found' });
        
        if (String(booking.worker) !== String(req.user.id)) {
            return res.status(403).json({ success: false, message: 'Only assigned worker can submit estimation' });
        }
        
        if (booking.status !== 'ARRIVED') {
            return res.status(400).json({ success: false, message: 'Cannot submit estimation unless status is ARRIVED' });
        }
        
        const estimatedTotal = (Number(laborCost) || 0) + (Number(partsEstimate) || 0) + (Number(serviceCharge) || 0);
        
        booking.workerEstimation = {
            estimatedTotal,
            laborCost: Number(laborCost) || 0,
            partsEstimate: Number(partsEstimate) || 0,
            serviceCharge: Number(serviceCharge) || 0,
            notes,
            submittedAt: new Date()
        };
        booking.status = 'ESTIMATION_GIVEN';
        
        await booking.save();
        
        const io = req.app.get('io');
        if (io) {
            io.to(`booking_${booking._id}`).emit('booking_status_update', {
                bookingId: booking._id,
                status: 'ESTIMATION_GIVEN',
                estimation: booking.workerEstimation
            });
        }
        
        return res.status(200).json({ success: true, message: 'Estimation submitted', estimation: booking.workerEstimation });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

export const acceptEstimation = async (req, res) => {
    try {
        const { bookingId } = req.params;
        
        const booking = await Booking.findById(bookingId);
        if (!booking) return res.status(404).json({ success: false, message: 'Booking not found' });
        
        if (String(booking.customer) !== String(req.user.id)) {
            return res.status(403).json({ success: false, message: 'Only customer can accept estimation' });
        }
        
        if (booking.status !== 'ESTIMATION_GIVEN') {
            return res.status(400).json({ success: false, message: 'Booking is not awaiting estimation acceptance' });
        }
        
        booking.workerEstimation.customerAccepted = true;
        booking.workerEstimation.customerAcceptedAt = new Date();
        booking.status = 'READY_TO_START';
        
        await booking.save();
        
        const io = req.app.get('io');
        if (io) {
            io.to(`booking_${booking._id}`).emit('booking_status_update', {
                bookingId: booking._id,
                status: 'READY_TO_START'
            });
        }
        
        return res.status(200).json({ success: true, message: 'Estimation accepted', booking });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};
