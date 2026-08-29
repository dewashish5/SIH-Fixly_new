import dotenv from 'dotenv';
dotenv.config();

import User from '../models/User.js';
import redis from '../config/redis.js';

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

        // Optional Category Filter
        if (category) {
            queryFilter['workerProfile.category'] = category;
        }

        // Sorting by nested workerProfile fields
        let sortOption = {};
        if (sortBy === 'top_rated') {
            sortOption = { 'workerProfile.rating': -1 };
        } else if (sortBy === 'jobs') {
            sortOption = { 'workerProfile.totalJobs': -1 };
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

        await redis.set(cacheKey, JSON.stringify(worker), 'EX', ttl);

        return res.status(200).json({ success: true, source: 'db', worker });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};



// import dotenv from 'dotenv';
// dotenv.config();

// import User from '../models/User.js';
// import redis from '../config/redis.js';

// // Screen 7: Get GeoJSON Nearby Workers (Indexed 2dsphere Query)
// export const getNearbyWorkers = async (req, res) => {
//     try {
//         const defaultRadius = process.env.WORKER_SEARCH_RADIUS_KM || 10;
//         const { lng, lat, sortBy = 'nearest', radiusInKm = defaultRadius } = req.query;

//         if (!lng || !lat) {
//             return res.status(400).json({ success: false, message: 'Coordinates (lng, lat) mandatory hain' });
//         }

//         const longitude = parseFloat(lng);
//         const latitude = parseFloat(lat);
//         const searchRadius = parseInt(radiusInKm, 10);

//         let sortOption = {};
//         if (sortBy === 'top_rated') {
//             sortOption = { rating: -1 };
//         }

//         const workers = await User.find({
//             role: 'worker',
//             isVerified: true,
//             location: {
//                 $near: {
//                     $geometry: { type: 'Point', coordinates: [longitude, latitude] },
//                     $maxDistance: searchRadius * 1000 // meters conversion
//                 }
//             }
//         })
//             .select('-password')
//             .sort(sortOption)
//             .lean();

//         return res.status(200).json({ success: true, count: workers.length, searchRadiusKm: searchRadius, workers });
//     } catch (error) {
//         return res.status(500).json({ success: false, message: error.message });
//     }
// };

// // Screen 8: Worker Profile Details
// export const getWorkerProfile = async (req, res) => {
//     try {
//         const { workerId } = req.params;
//         const cacheKey = `worker:profile:${workerId}`;

//         const cachedProfile = await redis.get(cacheKey);
//         if (cachedProfile) {
//             return res.status(200).json({ success: true, source: 'cache', worker: JSON.parse(cachedProfile) });
//         }

//         const ttl = parseInt(process.env.CACHE_TTL_WORKER_PROFILE, 10) || 600;

//         const worker = await User.findOne({ _id: workerId, role: 'worker' }).select('-password').lean();
//         if (!worker) return res.status(404).json({ success: false, message: 'Worker profile nahi milaa' });

//         await redis.set(cacheKey, JSON.stringify(worker), 'EX', ttl);

//         return res.status(200).json({ success: true, source: 'db', worker });
//     } catch (error) {
//         return res.status(500).json({ success: false, message: error.message });
//     }
// };