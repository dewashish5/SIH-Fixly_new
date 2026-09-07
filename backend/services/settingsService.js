import Settings from '../models/Settings.js';
import redis from '../config/redis.js';

const SETTINGS_CACHE_KEY = 'app:platform:settings';
const CACHE_TTL_SECONDS = 86400; // 24 hours

export const getPlatformSettings = async () => {
    try {
        if (redis) {
            const cached = await redis.get(SETTINGS_CACHE_KEY);
            if (cached) {
                return JSON.parse(cached);
            }
        }
    } catch (err) {
        console.warn('Redis settings cache error:', err.message);
    }

    let settings = await Settings.findOne().lean();
    if (!settings) {
        const created = await Settings.create({
            customerPlatformFee: 0,
            workerCommissionPercent: 5,
            platformCommissionPercent: 5,
            cooperativeWelfarePercent: 5,
            workerSearchRadiusKm: 15,
            defaultLaborRatePerHour: 350,
            autoDispatchEnabled: true,
            emergencyHotline: '+91 98765 43210',
        });
        settings = created.toObject ? created.toObject() : created;
    }

    try {
        if (redis) {
            await redis.setex(SETTINGS_CACHE_KEY, CACHE_TTL_SECONDS, JSON.stringify(settings));
        }
    } catch (err) {
        console.warn('Redis cache set error:', err.message);
    }

    return settings;
};

export const invalidatePlatformSettings = async () => {
    try {
        if (redis) {
            await redis.del(SETTINGS_CACHE_KEY);
        }
    } catch (err) {
        console.warn('Redis cache invalidate error:', err.message);
    }
};

export default {
    getPlatformSettings,
    invalidatePlatformSettings
};
