import dotenv from 'dotenv';
dotenv.config();

import User from '../models/User.js';
import Booking from '../models/Booking.js';
import Review from '../models/Review.js';
import redis from '../config/redis.js';
import { uploadDataUriOrUrl } from '../utils/cloudinary.js';
import { updateUserProfile } from './authController.js';

// Screen 7: Get GeoJSON Nearby Workers with Embedded workerProfile
export const getNearbyWorkers = async (req, res) => {
    try {
        const defaultRadius = process.env.WORKER_SEARCH_RADIUS_KM || 10;
        const { lng, lat, category, sortBy = 'nearest', radiusInKm = defaultRadius } = req.query;

        if (!lng || !lat) {
            return res.status(400).json({ success: false, message: 'Coordinates (lng, lat) mandatory hain' });
        }

        const longitude = parseFloat(lng);
        const latitude = parseFloat(lat);
        const searchRadius = parseInt(radiusInKm, 10);

        // Base Filter: Only active workers with setup profiles
        const queryFilter = {
            role: 'worker',
            isVerified: true,
            workerProfile: { $ne: null },
            location: {
                $near: {
                    $geometry: { type: 'Point', coordinates: [longitude, latitude] },
                    $maxDistance: searchRadius * 1000
                }
            }
        };

        // Optional Category Filter (matches primary category, categories list, or categoryRates)
        if (category) {
            queryFilter.$or = [
                { 'workerProfile.category': category },
                { 'workerProfile.categories': category },
                { 'workerProfile.categoryRates.category': category }
            ];
        }

        // Sorting by nested workerProfile fields
        let sortOption = {};
        if (sortBy === 'top_rated') {
            sortOption = { 'workerProfile.rating': -1 };
        } else if (sortBy === 'jobs') {
            sortOption = { 'workerProfile.totalJobs': -1 };
        } else if (sortBy === 'price_low') {
            sortOption = { 'workerProfile.rate': 1 };
        } else if (sortBy === 'price_high') {
            sortOption = { 'workerProfile.rate': -1 };
        }

        const workers = await User.find(queryFilter)
            .select('-password -activeDeviceId')
            .sort(sortOption)
            .lean();

        return res.status(200).json({
            success: true,
            count: workers.length,
            searchRadiusKm: searchRadius,
            workers
        });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

// Screen 8: Worker Profile Details
export const getWorkerProfile = async (req, res) => {
    try {
        const { workerId } = req.params;
        const cacheKey = `worker:profile:${workerId}`;

        const cachedProfile = await redis.get(cacheKey);
        if (cachedProfile) {
            return res.status(200).json({ success: true, source: 'cache', worker: JSON.parse(cachedProfile) });
        }

        const ttl = parseInt(process.env.CACHE_TTL_WORKER_PROFILE, 10) || 600;

        const worker = await User.findOne({ _id: workerId, role: 'worker' })
            .select('-password -activeDeviceId')
            .lean();

        if (!worker || !worker.workerProfile) {
            return res.status(404).json({ success: false, message: 'Worker profile nahi milaa' });
        }

        const [completed, cancelled, reviews] = await Promise.all([
            Booking.countDocuments({ worker: workerId, status: 'COMPLETED' }),
            Booking.countDocuments({ worker: workerId, status: 'CANCELLED' }),
            Review.find({ worker: workerId }).select('rating'),
        ]);
        const total = completed + cancelled;
        const completionRate = total === 0 ? 0 : Math.round((completed / total) * 100);
        const avgRating = reviews.length
            ? reviews.reduce((s, r) => s + r.rating, 0) / reviews.length
            : 0;
        worker.reliability = {
            score: Math.round(
                (completionRate * 0.4) + (Math.round((avgRating / 5) * 100) * 0.35) + ((total === 0 ? 100 : Math.round((1 - cancelled / total) * 100)) * 0.25),
            ),
            onTimeArrival: completionRate,
            completionRate,
            customerFeedback: Math.round((avgRating / 5) * 100),
            cancellationRate: total === 0 ? 100 : Math.round((1 - cancelled / total) * 100),
            responseTime: completionRate,
            rating: Number(avgRating.toFixed(1)),
            completedJobs: completed,
        };

        await redis.set(cacheKey, JSON.stringify(worker), 'EX', ttl);

        return res.status(200).json({ success: true, source: 'db', worker });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

export const setupWorkerProfile = async (req, res) => {
    // If multipart files or complex structure, delegate to updateUserProfile
    if (req.files || (req.file) || (req.body && (req.body.avatar || req.body.aadhaarFrontPhoto || req.body.panFrontPhoto))) {
        return updateUserProfile(req, res);
    }
    return updateUserProfile(req, res);
};

export const getMyAvailability = async (req, res) => {
    try {
        if (req.user.role !== 'worker') {
            return res.status(403).json({ success: false, code: 'FORBIDDEN', message: 'Worker role required' });
        }
        const user = await User.findById(req.user.id).select('workerProfile');
        const p = user?.workerProfile || {};
        return res.status(200).json({
            success: true,
            data: {
                isOnline: Boolean(p.isOnline),
                lastActiveAt: p.lastActiveAt || null,
                serviceRadiusKm: p.serviceRadiusKm || 10,
                availabilitySchedule: p.availabilitySchedule || { days: [], startTime: '09:00', endTime: '18:00' },
            },
        });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

export const patchMyAvailability = async (req, res) => {
    try {
        if (req.user.role !== 'worker') {
            return res.status(403).json({ success: false, code: 'FORBIDDEN', message: 'Worker role required' });
        }
        const user = await User.findById(req.user.id);
        if (!user.workerProfile) user.workerProfile = {};
        if (typeof req.body.isOnline === 'boolean') {
            user.workerProfile.isOnline = req.body.isOnline;
            user.workerProfile.lastActiveAt = new Date();
        }
        if (req.body.serviceRadiusKm != null) {
            user.workerProfile.serviceRadiusKm = Number(req.body.serviceRadiusKm);
        }
        await user.save();
        const io = req.app.get('io');
        if (io) {
            io.emit('worker:availability-changed', {
                workerId: String(user._id),
                isOnline: user.workerProfile.isOnline,
            });
        }
        return res.status(200).json({
            success: true,
            data: {
                isOnline: user.workerProfile.isOnline,
                lastActiveAt: user.workerProfile.lastActiveAt,
                serviceRadiusKm: user.workerProfile.serviceRadiusKm,
            },
        });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

export const putAvailabilitySchedule = async (req, res) => {
    try {
        if (req.user.role !== 'worker') {
            return res.status(403).json({ success: false, code: 'FORBIDDEN', message: 'Worker role required' });
        }
        const { days, startTime, endTime } = req.body || {};
        const user = await User.findById(req.user.id);
        if (!user.workerProfile) user.workerProfile = {};
        user.workerProfile.availabilitySchedule = {
            days: Array.isArray(days) ? days : [],
            startTime: startTime || '09:00',
            endTime: endTime || '18:00',
        };
        await user.save();
        return res.status(200).json({ success: true, data: user.workerProfile.availabilitySchedule });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

export const computeReliability = async (workerId) => {
    const [completed, cancelled, reviews] = await Promise.all([
        Booking.countDocuments({ worker: workerId, status: 'COMPLETED' }),
        Booking.countDocuments({ worker: workerId, status: 'CANCELLED' }),
        Review.find({ worker: workerId }).select('rating'),
    ]);
    const total = completed + cancelled;
    const completionRate = total === 0 ? 0 : Math.round((completed / total) * 100);
    const avgRating = reviews.length
        ? reviews.reduce((s, r) => s + r.rating, 0) / reviews.length
        : 0;
    const customerFeedback = Math.round((avgRating / 5) * 100);
    const cancellationRate = total === 0 ? 100 : Math.round((1 - cancelled / total) * 100);
    const score = Math.round(
        (completionRate * 0.4) + (customerFeedback * 0.35) + (cancellationRate * 0.25),
    );
    return {
        score,
        onTimeArrival: completionRate,
        completionRate,
        customerFeedback,
        cancellationRate,
        responseTime: completionRate,
        rating: Number(avgRating.toFixed(1)),
        completedJobs: completed,
    };
};

export const getWorkerReliability = async (req, res) => {
    try {
        const reliability = await computeReliability(req.params.workerId);
        return res.status(200).json({ success: true, reliability, data: reliability });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};
