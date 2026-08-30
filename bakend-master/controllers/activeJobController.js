import Booking from '../models/Booking.js';

// 1. Worker Accepts Booking Request (transitions SEARCHING -> ACCEPTED)
export const acceptBooking = async (req, res) => {
    try {
        const { bookingId } = req.params;
        const workerId = req.user.id; // From protect middleware

        const booking = await Booking.findById(bookingId);
        if (!booking) return res.status(404).json({ success: false, message: 'Booking not found' });

        if (booking.status !== 'SEARCHING') {
            return res.status(400).json({ success: false, message: 'Booking is already accepted or cancelled' });
        }

        booking.worker = workerId;
        booking.status = 'ACCEPTED';
        await booking.save();

        // Notify client via Socket.io
        const io = req.app.get('io');
        if (io) {
            io.to(`booking_${bookingId}`).emit('booking_status_update', {
                bookingId,
                status: 'ACCEPTED',
                workerId
            });
        }

        return res.status(200).json({ success: true, message: 'Booking accepted successfully', booking });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
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

        booking.status = 'ARRIVED';
        await booking.save();

        // Notify client via Socket.io
        const io = req.app.get('io');
        if (io) {
            io.to(`booking_${bookingId}`).emit('booking_status_update', {
                bookingId,
                status: 'ARRIVED'
            });
        }

        return res.status(200).json({ success: true, message: 'Worker arrival verified', booking });
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

        booking.status = 'COMPLETED';
        booking.jobCompletedAt = Date.now();

        // Recalculate invoice based on Booking schema fields
        const extraPartsTotal = booking.addOns.reduce((sum, item) => sum + item.price, 0);
        booking.invoice.extraPartsTotal = extraPartsTotal;
        booking.invoice.totalAmount = booking.invoice.baseServiceFee + extraPartsTotal + booking.invoice.platformFee;

        await booking.save();

        // Notify client via Socket.io
        const io = req.app.get('io');
        if (io) {
            io.to(`booking_${bookingId}`).emit('booking_status_update', {
                bookingId,
                status: 'COMPLETED',
                invoice: booking.invoice
            });
        }

        return res.status(200).json({ success: true, message: 'Job completed successfully', invoice: booking.invoice });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};