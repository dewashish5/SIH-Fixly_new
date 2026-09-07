import dotenv from 'dotenv';
dotenv.config();

import Booking from '../models/Booking.js';
import Service from '../models/Service.js';
import User from '../models/User.js';
import redis from '../config/redis.js';
import { uploadMulterFiles } from '../utils/cloudinary.js';
import { notifyUser, notifyUsers, safeNotify } from '../services/notificationService.js';
import { findEligibleWorkerIds } from '../services/eligibleWorkers.js';

// Screen 5 & 6: Estimate Price Breakdown
export const calculateEstimate = async (req, res) => {
    // #swagger.tags = ['Bookings']
    // #swagger.parameters['body'] = { in: 'body', description: 'Estimate Input', required: true, schema: { serviceId: '64f1bc000000000000000002', estimatedHours: 2 } }
    try {
        const { serviceId, estimatedHours = 1 } = req.body;

        const defaultLaborRate = parseFloat(process.env.DEFAULT_LABOR_RATE_PER_HR) || 45;
        const platformFee = parseFloat(process.env.DEFAULT_PLATFORM_FEE) || 15;

        const service = await Service.findById(serviceId);
        const basePrice = service ? service.basePrice : defaultLaborRate;

        const laborMin = basePrice * estimatedHours;
        const laborMax = laborMin + 45;
        const materialsMin = 20;
        const materialsMax = 40;

        return res.status(200).json({
            success: true,
            estimate: {
                laborEstimate: { min: laborMin, max: laborMax },
                materialsParts: { min: materialsMin, max: materialsMax },
                serviceFee: platformFee,
                totalEstimate: {
                    min: laborMin + materialsMin + platformFee,
                    max: laborMax + materialsMax + platformFee
                },
                baseServiceFee: laborMin,
                demandAdjustment: 0,
                urgentFee: 0,
                estimatedTotal: laborMin + materialsMin + platformFee,
                currency: 'INR',
                isEstimate: true,
            }
        });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

// Screen 8: Create New Booking (Customer creates booking; Initial status: PENDING)
export const createBooking = async (req, res) => {
    // #swagger.tags = ['Bookings']
    // #swagger.description = 'Customer creates a new booking request without invoice or schedule time (Status starts as PENDING until worker approves)'
    try {
        const { serviceId, workerId, problemDescription, problemPhotos, addressLine, coordinates } = req.body;

        if (!serviceId) {
            return res.status(400).json({ success: false, message: 'serviceId is required' });
        }
        if (!addressLine) {
            return res.status(400).json({ success: false, message: 'addressLine is required' });
        }

        let coords = coordinates;
        if (typeof coords === 'string') {
            try { coords = JSON.parse(coords); } catch { /* keep */ }
        }
        if (!coords || !Array.isArray(coords) || coords.length !== 2) {
            return res.status(400).json({ success: false, message: 'Valid coordinates [longitude, latitude] are required' });
        }

        let photoUrls = [];
        if (Array.isArray(problemPhotos)) {
            photoUrls = problemPhotos.filter(Boolean);
        } else if (typeof problemPhotos === 'string' && problemPhotos.trim()) {
            try {
                const parsed = JSON.parse(problemPhotos);
                photoUrls = Array.isArray(parsed) ? parsed : [problemPhotos];
            } catch {
                photoUrls = [problemPhotos];
            }
        }

        if (req.files?.length) {
            const uploaded = await uploadMulterFiles(req.files, 'gigconnect/bookings');
            photoUrls = [...photoUrls, ...uploaded];
        }

        // Fetch service to get baseline pricing
        const service = await Service.findById(serviceId);
        let baseFee = service ? (service.basePrice || 100) : 100;

        if (workerId) {
            const activeBooking = await Booking.findOne({
                worker: workerId,
                status: { $in: ['APPROVED', 'ACCEPTED', 'ARRIVED', 'IN_PROGRESS'] }
            });
            if (activeBooking) {
                return res.status(400).json({
                    success: false,
                    code: 'WORKER_BUSY',
                    message: 'Yeh worker abhi doosre customer ke kaam par vyast hai. Kripya doosra worker chunein ya unke kaam poora hone ka intezaar karein.'
                });
            }

            const worker = await User.findById(workerId).lean();
            if (worker?.workerProfile?.rate) {
                baseFee = worker.workerProfile.rate;
            }
        }

        const platformFee = parseFloat(process.env.DEFAULT_PLATFORM_FEE) || 15;
        const totalAmount = baseFee + platformFee;

        // Create booking with initial status: 'PENDING'
        const booking = await Booking.create({
            customer: req.user.id,
            worker: workerId || null,
            service: serviceId,
            problemDescription: problemDescription || null,
            problemPhotos: photoUrls,
            serviceAddress: {
                addressLine,
                location: { type: 'Point', coordinates: coords }
            },
            scheduledTime: Date.now(),
            status: 'PENDING', // Initial phase is always PENDING
            invoice: {
                baseServiceFee: baseFee,
                extraPartsTotal: 0,
                platformFee: platformFee,
                totalAmount: totalAmount,
                paymentStatus: 'PENDING',
                paymentMethod: 'UPI'
            }
        });

        // Populate service & worker details for response
        const populatedBooking = await Booking.findById(booking._id)
            .populate('service', 'name category icon basePrice')
            .populate('worker', 'name phone avatar workerProfile rating')
            .populate('customer', 'name phone')
            .lean();

        const io = req.app.get('io');
        if (io) {
            if (workerId) {
                io.emit('worker:booking_requested', {
                    workerId: String(workerId),
                    booking: populatedBooking
                });
            } else {
                io.emit('booking:new_available', {
                    bookingId: booking._id,
                    coordinates: coords,
                    category: service?.category
                });
            }
        }

        safeNotify(async () => {
            if (workerId) {
                await notifyUser({
                    recipient: workerId,
                    eventType: 'BOOKING_ASSIGNED',
                    entityId: booking._id,
                    bookingId: booking._id,
                    dedupeKey: `BOOKING_ASSIGNED:${booking._id}:${workerId}`,
                });
                return;
            }
            const workerIds = await findEligibleWorkerIds(booking, service?.category);
            await notifyUsers(workerIds, {
                eventType: 'NEW_BOOKING_AVAILABLE',
                entityId: booking._id,
                bookingId: booking._id,
                dedupeKeyFor: (id) => `NEW_BOOKING_AVAILABLE:${booking._id}:${id}`,
            });
        });

        return res.status(201).json({
            success: true,
            message: 'Booking created successfully. Waiting for worker approval.',
            booking: populatedBooking
        });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

// Screen 9: Get Booking Confirmation & Status
export const getBookingDetails = async (req, res) => {
    try {
        const { bookingId } = req.params;

        const booking = await Booking.findById(bookingId)
            .populate('service')
            .populate('worker', 'name phone avatar rating')
            .populate('customer', 'name phone')
            .lean();

        if (!booking) {
            return res.status(404).json({ success: false, message: 'Booking not found' });
        }

        return res.status(200).json({ success: true, booking });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

// Customer edits the problem details of an existing booking.
export const updateBooking = async (req, res) => {
    try {
        const { bookingId } = req.params;
        const { problemDescription, scheduledTime, serviceAddress } = req.body || {};
        const booking = await Booking.findById(bookingId);

        if (!booking) {
            return res.status(404).json({ success: false, message: 'Booking not found' });
        }
        if (String(booking.customer) !== String(req.user.id)) {
            return res.status(403).json({ success: false, message: 'You can only edit your own booking' });
        }
        if (['COMPLETED', 'CANCELLED'].includes(booking.status)) {
            return res.status(400).json({ success: false, message: 'Completed or cancelled bookings cannot be edited' });
        }

        if (problemDescription !== undefined) {
            booking.problemDescription = String(problemDescription).trim() || null;
        }
        if (scheduledTime !== undefined) {
            const parsedTime = new Date(scheduledTime);
            if (Number.isNaN(parsedTime.getTime())) {
                return res.status(400).json({ success: false, message: 'Invalid scheduledTime' });
            }
            booking.scheduledTime = parsedTime;
        }
        if (serviceAddress !== undefined) {
            if (!serviceAddress || typeof serviceAddress !== 'object') {
                return res.status(400).json({ success: false, message: 'Invalid serviceAddress' });
            }
            if (serviceAddress.addressLine !== undefined) {
                const addressLine = String(serviceAddress.addressLine).trim();
                if (!addressLine) {
                    return res.status(400).json({ success: false, message: 'addressLine cannot be empty' });
                }
                booking.serviceAddress.addressLine = addressLine;
            }
            if (Array.isArray(serviceAddress.coordinates)) {
                if (serviceAddress.coordinates.length !== 2 || serviceAddress.coordinates.some((value) => Number.isNaN(Number(value)))) {
                    return res.status(400).json({ success: false, message: 'Invalid service coordinates' });
                }
                booking.serviceAddress.location = {
                    type: 'Point',
                    coordinates: serviceAddress.coordinates.map(Number),
                };
            }
        }

        // Editing reopens the request so available workers can receive it again.
        booking.status = 'PENDING';
        booking.worker = null;
        booking.declinedBy = null;
        booking.declineReason = null;
        await booking.save();

        const populatedBooking = await Booking.findById(booking._id)
            .populate('service', 'name title category icon basePrice')
            .populate('worker', 'name phone avatar workerProfile rating')
            .populate('customer', 'name phone')
            .lean();
        const service = populatedBooking?.service;
        const category = service?.category;

        const io = req.app.get('io');
        if (io) {
            io.emit('booking:updated', { bookingId: booking._id, booking: populatedBooking });
        }
        safeNotify(async () => {
            if (!category) return;
            const workerIds = await findEligibleWorkerIds(booking, category);
            await notifyUsers(workerIds, {
                eventType: 'NEW_BOOKING_AVAILABLE',
                entityId: booking._id,
                bookingId: booking._id,
                dedupeKeyFor: (id) => `NEW_BOOKING_AVAILABLE:${booking._id}:${id}`,
            });
        });

        return res.status(200).json({
            success: true,
            message: 'Booking updated successfully',
            booking: populatedBooking,
        });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

// Cancel Booking
export const cancelBooking = async (req, res) => {
    try {
        const { bookingId } = req.params;

        const booking = await Booking.findById(bookingId);
        if (!booking) return res.status(404).json({ success: false, message: 'Booking not found' });

        if (['COMPLETED', 'CANCELLED'].includes(booking.status)) {
            return res.status(400).json({ success: false, message: 'Cannot cancel an already completed/cancelled booking' });
        }

        booking.status = 'CANCELLED';
        await booking.save();

        // Purge temporary live tracking cache from Redis immediately
        try {
            await redis.del(`tracking:booking:${bookingId}`);
        } catch (_) {}

        const io = req.app.get('io');
        if (io) {
            io.to(`booking_${bookingId}`).emit('booking_status_update', {
                bookingId,
                status: 'CANCELLED'
            });
            if (booking.worker) {
                io.emit('worker:availability_changed', {
                    workerId: String(booking.worker),
                    isAvailable: true,
                    status: 'AVAILABLE'
                });
            }
        }

        safeNotify(async () => {
            const actorId = String(req.user.id);
            const customerId = String(booking.customer);
            const workerId = booking.worker ? String(booking.worker) : null;
            if (workerId && actorId !== workerId) {
                await notifyUser({
                    recipient: workerId,
                    eventType: 'BOOKING_CANCELLED',
                    entityId: booking._id,
                    bookingId: booking._id,
                    dedupeKey: `BOOKING_CANCELLED:${booking._id}:${workerId}`,
                });
            }
            if (actorId !== customerId) {
                await notifyUser({
                    recipient: customerId,
                    eventType: 'BOOKING_CANCELLED',
                    entityId: booking._id,
                    bookingId: booking._id,
                    dedupeKey: `BOOKING_CANCELLED:${booking._id}:${customerId}`,
                });
            }
        });

        return res.status(200).json({ success: true, message: 'Booking cancelled successfully', booking });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};


export const getBookingHistory = async (req, res) => {
    try {
        const userId = req.user.id;
        const role = req.user.role;

        let query = {};
        if (role === 'worker') {
            query = { worker: userId };
        } else {
            query = { customer: userId };
        }

        const bookings = await Booking.find(query)
            .populate('service')
            .populate('worker', 'name phone avatar workerProfile')
            .populate('customer', 'name phone avatar')
            .sort({ createdAt: -1 });

        return res.status(200).json({
            success: true,
            message: 'Booking history fetched successfully',
            bookings,
            data: bookings,
        });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

export const getBookingInvoice = async (req, res) => {
    try {
        const { bookingId } = req.params;

        const booking = await Booking.findById(bookingId)
            .populate('service')
            .populate('customer', 'name email phone')
            .populate('worker', 'name phone avatar workerProfile')
            .lean();

        if (!booking) {
            return res.status(404).json({ success: false, message: 'Booking not found' });
        }

        return res.status(200).json({
            success: true,
            message: 'Booking invoice fetched successfully',
            invoice: booking.invoice,
            bookingDetails: {
                bookingId: booking.bookingId,
                customer: booking.customer,
                worker: booking.worker,
                service: booking.service,
                addOns: booking.addOns,
                jobStartedAt: booking.jobStartedAt,
                jobCompletedAt: booking.jobCompletedAt,
                status: booking.status
            }
        });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

export const getLiveTracking = async (req, res) => {
    // #swagger.tags = ['Bookings']
    // #swagger.description = 'Get live real-time GPS tracking coordinates for an active booking (Cached in Redis <1ms, 0 DB load)'
    // #swagger.parameters['bookingId'] = { in: 'path', description: 'Booking ID', required: true, type: 'string' }
    try {
        const { bookingId } = req.params;

        // 1. Ultra-fast Redis in-memory cache check (<1ms response, 0 DB load)
        try {
            const cachedTracking = await redis.get(`tracking:booking:${bookingId}`);
            if (cachedTracking) {
                const parsed = JSON.parse(cachedTracking);
                return res.status(200).json({
                    success: true,
                    source: 'redis_live',
                    message: 'Live tracking data fetched successfully',
                    location: {
                        longitude: parsed.lng,
                        latitude: parsed.lat,
                        heading: parsed.heading || 0,
                        updatedAt: parsed.timestamp || Date.now()
                    }
                });
            }
        } catch (redisErr) {
            console.warn('Redis live tracking lookup warning:', redisErr.message);
        }

        // 2. Fallback if worker has not started moving yet
        const booking = await Booking.findById(bookingId).populate('worker');
        if (!booking) {
            return res.status(404).json({ success: false, message: 'Booking not found' });
        }

        if (!booking.worker) {
            return res.status(400).json({ success: false, message: 'No worker assigned to this booking yet' });
        }

        const worker = booking.worker;
        const coords = (worker.location && worker.location.coordinates)
            ? worker.location.coordinates
            : (worker.savedAddresses?.[0]?.location?.coordinates);

        if (!coords || coords.length !== 2) {
            return res.status(404).json({ success: false, message: 'Worker location not available' });
        }

        return res.status(200).json({
            success: true,
            source: 'base_location',
            message: 'Live tracking data fetched successfully',
            location: {
                longitude: coords[0],
                latitude: coords[1],
                heading: 0,
                updatedAt: Date.now()
            }
        });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

export const triggerSosAlert = async (req, res) => {
    try {
        const { bookingId } = req.params;

        const booking = await Booking.findById(bookingId);
        if (!booking) return res.status(404).json({ success: false, message: 'Booking not found' });

        // Broadcast SOS event to the specific booking room
        const io = req.app.get('io');
        if (io) {
            io.to(`booking_${bookingId}`).emit('sos_alert', {
                bookingId,
                message: 'EMERGENCY: SOS has been triggered!',
                timestamp: Date.now()
            });
        }

        safeNotify(async () => {
            const actorId = String(req.user.id);
            const counterpart = String(booking.customer) === actorId
                ? booking.worker
                : booking.customer;
            if (counterpart) {
                await notifyUser({
                    recipient: counterpart,
                    eventType: 'SOS_ALERT',
                    entityId: booking._id,
                    bookingId: booking._id,
                    dedupeKey: `SOS_ALERT:${booking._id}:${counterpart}:${Math.floor(Date.now() / 60000)}`,
                });
            }
        });

        return res.status(200).json({
            success: true,
            message: 'SOS alert triggered successfully. Emergency contacts and socket room notified.'
        });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

const populateBooking = (q) => q
    .populate('service')
    .populate('worker', 'name phone avatar workerProfile')
    .populate('customer', 'name phone avatar');

const paginate = (req) => {
    const page = Math.max(1, Number(req.query.page) || 1);
    const limit = Math.min(50, Math.max(1, Number(req.query.limit) || 20));
    return { page, limit, skip: (page - 1) * limit };
};

const calculateHaversineDistanceKm = (lat1, lon1, lat2, lon2) => {
    const R = 6371; // Earth's radius in kilometers
    const dLat = (lat2 - lat1) * (Math.PI / 180);
    const dLon = (lon2 - lon1) * (Math.PI / 180);
    const a =
        Math.sin(dLat / 2) * Math.sin(dLat / 2) +
        Math.cos(lat1 * (Math.PI / 180)) * Math.cos(lat2 * (Math.PI / 180)) *
        Math.sin(dLon / 2) * Math.sin(dLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
};

export const listWorkerIncoming = async (req, res) => {
    // #swagger.tags = ['Bookings']
    // #swagger.description = 'List incoming available jobs for worker within 10km radius from current / last completed job location'
    // #swagger.parameters['lng'] = { in: 'query', description: 'Worker current longitude (optional, falls back to worker.location in DB)', type: 'number' }
    // #swagger.parameters['lat'] = { in: 'query', description: 'Worker current latitude (optional, falls back to worker.location in DB)', type: 'number' }
    // #swagger.parameters['radiusInKm'] = { in: 'query', description: 'Search radius in km (default 10)', type: 'number', default: 10 }
    // #swagger.parameters['page'] = { in: 'query', description: 'Page number', type: 'integer', default: 1 }
    // #swagger.parameters['limit'] = { in: 'query', description: 'Limit per page', type: 'integer', default: 20 }
    try {
        if (req.user.role !== 'worker') {
            return res.status(403).json({ success: false, code: 'FORBIDDEN', message: 'Worker role required' });
        }

        const workerId = req.user.id;
        const defaultRadius = parseFloat(process.env.WORKER_SEARCH_RADIUS_KM) || 10;
        const radiusInKm = parseFloat(req.query.radiusInKm) || defaultRadius;

        // Fetch worker profile to get current location & skills
        const worker = await User.findById(workerId).lean();
        if (!worker) {
            return res.status(404).json({ success: false, message: 'Worker not found' });
        }

        // Determine worker's effective current coordinates:
        // Priority 1: Query params (lat, lng from mobile GPS)
        // Priority 2: worker.location (dynamically updated from last completed job or GPS)
        // Priority 3: worker.savedAddresses[0].location (fallback default registration address)
        let workerLng = parseFloat(req.query.lng);
        let workerLat = parseFloat(req.query.lat);

        if (isNaN(workerLng) || isNaN(workerLat)) {
            const coords = (worker.location && Array.isArray(worker.location.coordinates) && worker.location.coordinates.length === 2)
                ? worker.location.coordinates
                : (worker.savedAddresses && worker.savedAddresses[0]?.location?.coordinates?.length === 2)
                    ? worker.savedAddresses[0].location.coordinates
                    : null;

            if (coords) {
                workerLng = coords[0];
                workerLat = coords[1];
            }
        } else {
            // Background sync of worker live location if provided in query
            User.findByIdAndUpdate(workerId, {
                location: { type: 'Point', coordinates: [workerLng, workerLat] }
            }).catch(() => {});
        }

        const { page, limit, skip } = paginate(req);

        // Fetch open bookings waiting for workers (open pool or assigned to this worker)
        const query = {
            status: { $in: ['PENDING', 'SEARCHING'] },
            $or: [{ worker: null }, { worker: workerId }]
        };
        const openBookings = await populateBooking(
            Booking.find(query).sort({ createdAt: -1 })
        ).lean();

        // If coordinates could not be resolved at all, fallback to un-filtered pagination
        if (isNaN(workerLng) || isNaN(workerLat)) {
            const paginated = openBookings.slice(skip, skip + limit);
            return res.status(200).json({
                success: true,
                data: paginated,
                bookings: paginated,
                page,
                limit,
                total: openBookings.length,
                hasMore: (skip + limit) < openBookings.length
            });
        }

        // Filter bookings within the 10km radius from worker's current location
        const nearbyJobs = [];
        for (const b of openBookings) {
            const jobCoords = b.serviceAddress?.location?.coordinates;
            if (!jobCoords || jobCoords.length !== 2) continue;

            const [jobLng, jobLat] = jobCoords;
            if (isNaN(jobLng) || isNaN(jobLat)) continue;

            const dist = calculateHaversineDistanceKm(workerLat, workerLng, jobLat, jobLng);
            if (dist <= radiusInKm) {
                const roundedDist = parseFloat(dist.toFixed(1));
                nearbyJobs.push({
                    ...b,
                    distanceKm: roundedDist,
                    distanceFormatted: `${roundedDist} km`,
                    distanceDisplay: `${roundedDist}m`
                });
            }
        }

        // Sort by nearest distance
        nearbyJobs.sort((a, b) => a.distanceKm - b.distanceKm);

        const total = nearbyJobs.length;
        const paginatedBookings = nearbyJobs.slice(skip, skip + limit);
        const hasMore = (skip + limit) < total;

        return res.status(200).json({
            success: true,
            workerCurrentCoordinates: [workerLng, workerLat],
            searchRadiusKm: radiusInKm,
            data: paginatedBookings,
            bookings: paginatedBookings,
            page,
            limit,
            total,
            hasMore
        });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

export const listWorkerActive = async (req, res) => {
    try {
        if (req.user.role !== 'worker') {
            return res.status(403).json({ success: false, code: 'FORBIDDEN', message: 'Worker role required' });
        }
        const { page, limit, skip } = paginate(req);
        const query = {
            worker: req.user.id,
            status: { $in: ['APPROVED', 'ACCEPTED', 'ARRIVED', 'IN_PROGRESS', 'PAYMENT_PENDING'] },
        };
        const [bookings, total] = await Promise.all([
            populateBooking(Booking.find(query).sort({ updatedAt: -1 }).skip(skip).limit(limit)),
            Booking.countDocuments(query),
        ]);
        return res.status(200).json({ success: true, data: bookings, bookings, page, limit, total });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

export const listWorkerCompleted = async (req, res) => {
    try {
        if (req.user.role !== 'worker') {
            return res.status(403).json({ success: false, code: 'FORBIDDEN', message: 'Worker role required' });
        }
        const { page, limit, skip } = paginate(req);
        const query = { worker: req.user.id, status: 'COMPLETED' };
        const [bookings, total] = await Promise.all([
            populateBooking(Booking.find(query).sort({ jobCompletedAt: -1 }).skip(skip).limit(limit)),
            Booking.countDocuments(query),
        ]);
        return res.status(200).json({ success: true, data: bookings, bookings, page, limit, total });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

export const declineBooking = async (req, res) => {
    try {
        if (req.user.role !== 'worker') {
            return res.status(403).json({ success: false, code: 'FORBIDDEN', message: 'Worker role required' });
        }
        const allowed = new Set(['TOO_FAR', 'UNAVAILABLE', 'WRONG_SKILL', 'CUSTOMER_REQUEST', 'OTHER']);
        const reason = allowed.has(req.body?.reason) ? req.body.reason : 'OTHER';
        const booking = await Booking.findById(req.params.bookingId);
        if (!booking) return res.status(404).json({ success: false, code: 'NOT_FOUND', message: 'Booking not found' });
        if (!['PENDING', 'SEARCHING'].includes(booking.status)) {
            return res.status(400).json({ success: false, code: 'VALIDATION_ERROR', message: 'Booking cannot be declined' });
        }
        booking.declineReason = reason;
        booking.declinedBy = req.user.id;
        await booking.save();
        const io = req.app.get('io');
        if (io) {
            io.to(`booking_${booking._id}`).emit('booking:declined', {
                bookingId: booking._id,
                reason,
                workerId: req.user.id,
            });
        }
        return res.status(200).json({ success: true, data: { declined: true, reason } });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};
