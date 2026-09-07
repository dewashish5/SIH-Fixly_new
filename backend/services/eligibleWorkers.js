import Booking from '../models/Booking.js';
import User from '../models/User.js';
import { getPlatformSettings } from './settingsService.js';

const BUSY_STATUSES = ['APPROVED', 'ACCEPTED', 'ARRIVED', 'IN_PROGRESS'];

const haversineKm = (lat1, lon1, lat2, lon2) => {
    const toRad = (deg) => (deg * Math.PI) / 180;
    const dLat = toRad(lat2 - lat1);
    const dLon = toRad(lon2 - lon1);
    const a =
        Math.sin(dLat / 2) ** 2 +
        Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLon / 2) ** 2;
    return 6371 * (2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a)));
};

const workerCoords = (worker) => {
    if (Array.isArray(worker.location?.coordinates) && worker.location.coordinates.length === 2) {
        return worker.location.coordinates;
    }
    const saved = worker.savedAddresses?.[0]?.location?.coordinates;
    if (Array.isArray(saved) && saved.length === 2) return saved;
    return null;
};

export const findEligibleWorkerIds = async (booking, serviceCategory = null) => {
    if (booking.worker) return [String(booking.worker)];

    const jobCoords = booking.serviceAddress?.location?.coordinates;
    if (!Array.isArray(jobCoords) || jobCoords.length !== 2) return [];

    const [jobLng, jobLat] = jobCoords;
    const settings = await getPlatformSettings();
    const defaultRadius = Number(settings.workerSearchRadiusKm) || 10;
    const busyWorkers = await Booking.distinct('worker', {
        status: { $in: BUSY_STATUSES },
        worker: { $ne: null },
    });

    const workers = await User.find({
        role: 'worker',
        isVerified: true,
        workerProfile: { $exists: true },
        'workerProfile.isOnline': true,
        _id: { $nin: busyWorkers.filter(Boolean) },
    }).select('location savedAddresses workerProfile').lean();

    return workers
        .filter((worker) => {
            const coords = workerCoords(worker);
            if (!coords) return false;
            const radius = worker.workerProfile?.serviceRadiusKm || defaultRadius;
            const distance = haversineKm(jobLat, jobLng, coords[1], coords[0]);
            if (distance > radius) return false;
            if (!serviceCategory) return true;
            const targetCat = String(serviceCategory).toLowerCase().trim();
            const primaryCat = String(worker.workerProfile?.category || '').toLowerCase().trim();
            if (primaryCat && (primaryCat === targetCat || primaryCat.includes(targetCat) || targetCat.includes(primaryCat))) {
                return true;
            }
            const categories = (worker.workerProfile?.categories || []).map((c) => String(c).toLowerCase().trim());
            if (categories.some((c) => c === targetCat || c.includes(targetCat) || targetCat.includes(c))) {
                return true;
            }
            const skills = (worker.workerProfile?.skills || []).map((s) => String(s).toLowerCase().trim());
            if (skills.length && skills.some((s) => s === targetCat || s.includes(targetCat) || targetCat.includes(s))) {
                return true;
            }
            // If worker has no category or skills specified, allow as fallback
            return !primaryCat && !categories.length && !skills.length;
        })
        .map((worker) => String(worker._id));
};
