import AppVersion from '../models/AppVersion.js';
import redis from '../config/redis.js';

const VERSION_CACHE_PREFIX = 'app:version:';

/**
 * Helper to scan and delete keys by pattern in Redis safely
 */
const scanAndDeleteKeys = async (patterns) => {
    const patternList = Array.isArray(patterns) ? patterns : [patterns];
    let totalDeleted = 0;

    for (const pattern of patternList) {
        let cursor = '0';
        do {
            const [nextCursor, keys] = await redis.scan(cursor, 'MATCH', pattern, 'COUNT', 200);
            cursor = nextCursor;
            if (keys && keys.length > 0) {
                const deleted = await redis.del(...keys);
                totalDeleted += deleted;
            }
        } while (cursor !== '0');
    }

    return totalDeleted;
};

/**
 * Public Route: Check / Get App Version
 * Reads from Redis cache first; falls back to MongoDB if not cached.
 * Compares client version against active DB/Redis version.
 */
export const checkAppVersion = async (req, res) => {
    try {
        const clientVersion = (
            req.query.version ||
            req.query.apiVersion ||
            req.query.appVersion ||
            req.headers['x-app-version'] ||
            req.headers['x-api-version'] ||
            ''
        ).toString().trim();

        const platform = (req.query.platform || req.headers['x-platform'] || 'all').toString().trim().toLowerCase();
        const cacheKey = `${VERSION_CACHE_PREFIX}${platform}`;

        let versionDoc = null;
        let isFromCache = false;

        // 1. Try Redis cache first
        try {
            const cached = await redis.get(cacheKey);
            if (cached) {
                versionDoc = JSON.parse(cached);
                isFromCache = true;
            }
        } catch (redisErr) {
            // Redis unavailable, will fallback to MongoDB
        }

        // 2. If not in Redis, fetch from MongoDB
        if (!versionDoc) {
            versionDoc = await AppVersion.findOne({
                isActive: true,
                platform: { $in: [platform, 'all'] }
            })
                .sort({ platform: platform === 'all' ? 1 : -1, updatedAt: -1 })
                .lean();

            if (!versionDoc) {
                // Fallback to any active record
                versionDoc = await AppVersion.findOne({ isActive: true }).sort({ updatedAt: -1 }).lean();
            }

            if (!versionDoc) {
                return res.status(404).json({
                    success: false,
                    message: 'No active app version found in database'
                });
            }

            // 3. Cache into Redis for 24 hours (86400 seconds)
            try {
                await redis.set(cacheKey, JSON.stringify(versionDoc), 'EX', 86400);
            } catch (redisErr) {
                // Ignore redis write errors
            }
        }

        const currentApiVersion = versionDoc.apiVersion || '';
        const currentAppVersion = versionDoc.appVersion || '';
        const minSupportedVersion = versionDoc.minVersion || currentApiVersion;

        let isMatch = null;
        let isUpdateAvailable = false;
        let isForceUpdate = Boolean(versionDoc.forceUpdate);

        if (clientVersion) {
            isMatch = clientVersion.toLowerCase() === currentApiVersion.toLowerCase();
            isUpdateAvailable = !isMatch;

            if (minSupportedVersion && clientVersion.toLowerCase() !== minSupportedVersion.toLowerCase()) {
                isForceUpdate = Boolean(versionDoc.forceUpdate) || true;
            }
        }

        return res.status(200).json({
            success: true,
            apiVersion: currentApiVersion,
            appVersion: currentAppVersion,
            minVersion: minSupportedVersion,
            forceUpdate: isForceUpdate,
            isUpdateAvailable,
            isMatch,
            clientVersion: clientVersion || null,
            updateTitle: versionDoc.updateTitle || 'Update Available',
            updateMessage: versionDoc.updateMessage || '',
            updateUrl: versionDoc.updateUrl || '',
            platform: versionDoc.platform || 'all',
            source: isFromCache ? 'redis' : 'database',
            lastUpdated: versionDoc.updatedAt
        });
    } catch (error) {
        console.error('Error in checkAppVersion:', error);
        return res.status(500).json({
            success: false,
            message: error.message || 'Failed to check app version'
        });
    }
};

/**
 * Update App Version
 * Used by Admin Panel Settings. Updates DB & synchronizes / flushes Redis cache.
 */
export const updateAppVersion = async (req, res) => {
    try {
        const {
            apiVersion,
            appVersion,
            minVersion,
            forceUpdate,
            updateTitle,
            updateMessage,
            updateUrl,
            platform,
            isActive
        } = req.body;

        const targetPlatform = platform || 'all';

        let versionDoc = await AppVersion.findOne({ platform: targetPlatform });

        if (versionDoc) {
            if (apiVersion !== undefined) versionDoc.apiVersion = apiVersion.trim();
            if (appVersion !== undefined) versionDoc.appVersion = appVersion.trim();
            if (minVersion !== undefined) versionDoc.minVersion = minVersion.trim();
            if (forceUpdate !== undefined) versionDoc.forceUpdate = Boolean(forceUpdate);
            if (updateTitle !== undefined) versionDoc.updateTitle = updateTitle.trim();
            if (updateMessage !== undefined) versionDoc.updateMessage = updateMessage.trim();
            if (updateUrl !== undefined) versionDoc.updateUrl = updateUrl.trim();
            if (isActive !== undefined) versionDoc.isActive = Boolean(isActive);

            await versionDoc.save();
        } else {
            versionDoc = await AppVersion.create({
                apiVersion: apiVersion || 'V1',
                appVersion: appVersion || '1.0.0',
                minVersion: minVersion || apiVersion || 'V1',
                forceUpdate: forceUpdate !== undefined ? Boolean(forceUpdate) : false,
                updateTitle: updateTitle || 'Update Available',
                updateMessage: updateMessage || 'A new version of Fixly is available. Please update the app to continue.',
                updateUrl: updateUrl || '',
                platform: targetPlatform,
                isActive: isActive !== undefined ? Boolean(isActive) : true
            });
        }

        // Synchronize Redis: Invalidate old caches and pre-warm current
        try {
            await scanAndDeleteKeys([`${VERSION_CACHE_PREFIX}*`]);
            await redis.set(
                `${VERSION_CACHE_PREFIX}${versionDoc.platform || 'all'}`,
                JSON.stringify(versionDoc),
                'EX',
                86400
            );
        } catch (redisErr) {
            console.warn('Redis cache sync warning:', redisErr.message);
        }

        return res.status(200).json({
            success: true,
            message: `App version successfully updated to ${versionDoc.apiVersion} and Redis cache refreshed`,
            version: versionDoc
        });
    } catch (error) {
        console.error('Error in updateAppVersion:', error);
        return res.status(500).json({
            success: false,
            message: error.message || 'Failed to update app version'
        });
    }
};

/**
 * Admin: Get active version for Settings View
 */
export const getAppVersionAdmin = async (req, res) => {
    try {
        const platform = (req.query.platform || 'all').toString().trim().toLowerCase();
        let versionDoc = await AppVersion.findOne({ platform: { $in: [platform, 'all'] } })
            .sort({ platform: platform === 'all' ? 1 : -1, updatedAt: -1 })
            .lean();

        if (!versionDoc) {
            versionDoc = await AppVersion.findOne().sort({ updatedAt: -1 }).lean();
        }

        return res.status(200).json({
            success: true,
            version: versionDoc || null
        });
    } catch (error) {
        return res.status(500).json({
            success: false,
            message: error.message || 'Failed to fetch app version'
        });
    }
};

/**
 * Admin: Get all configured versions
 */
export const getAllVersions = async (req, res) => {
    try {
        const versions = await AppVersion.find().sort({ updatedAt: -1 }).lean();
        return res.status(200).json({
            success: true,
            count: versions.length,
            versions
        });
    } catch (error) {
        return res.status(500).json({
            success: false,
            message: error.message || 'Failed to fetch versions'
        });
    }
};

/**
 * Redis Cache Manager: Flush / Clear Keys
 * Route supports:
 *   - /api/version/redis/clear/:type
 *   - /api/admin/redis/clear/:type
 *   - /api/admin/redis/flush-all
 *
 * Supported types:
 *   - 'user': Clears user:*, session:*, otp:*, reset_otp:*
 *   - 'booking': Clears booking:*, scheduled_booking:*
 *   - 'worker': Clears worker:*
 *   - 'version': Clears app:version:*
 *   - 'categories' or 'services': Clears app:categories:*, app:services:*, app:home:*
 *   - 'settings': Clears app:platform:settings
 *   - 'all' or 'flush': FLUSHDB (resets entire Redis database)
 */
export const clearRedisCache = async (req, res) => {
    try {
        const type = (
            req.params.type ||
            req.query.type ||
            req.body.type ||
            'all'
        ).toString().trim().toLowerCase();

        let deletedCount = 0;
        let clearScope = '';

        if (type === 'all' || type === 'flush' || type === 'reset') {
            await redis.flushdb();
            return res.status(200).json({
                success: true,
                message: 'All Redis cache flushed completely (FLUSHDB executed)',
                type: 'all',
                deletedCount: 'ALL'
            });
        }

        switch (type) {
            case 'user':
            case 'users':
                clearScope = 'User sessions, profiles, and OTPs';
                deletedCount = await scanAndDeleteKeys([
                    'user:*',
                    'session:*',
                    'otp:*',
                    'reset_otp:*'
                ]);
                break;

            case 'booking':
            case 'bookings':
                clearScope = 'Booking and scheduled bookings';
                deletedCount = await scanAndDeleteKeys([
                    'booking:*',
                    'scheduled_booking:*'
                ]);
                break;

            case 'worker':
            case 'workers':
                clearScope = 'Worker profiles and metrics';
                deletedCount = await scanAndDeleteKeys(['worker:*']);
                break;

            case 'version':
            case 'app-version':
                clearScope = 'Mobile app version cache';
                deletedCount = await scanAndDeleteKeys([`${VERSION_CACHE_PREFIX}*`]);
                break;

            case 'categories':
            case 'services':
            case 'catalog':
                clearScope = 'Categories, service catalog, and home dashboard';
                deletedCount = await scanAndDeleteKeys([
                    'app:categories:*',
                    'app:services:*',
                    'app:home:*'
                ]);
                break;

            case 'settings':
                clearScope = 'Platform governance settings';
                deletedCount = await scanAndDeleteKeys(['app:platform:settings']);
                break;

            default:
                // If custom pattern provided
                clearScope = `Pattern '${type}:*'`;
                deletedCount = await scanAndDeleteKeys([`${type}:*`]);
                break;
        }

        return res.status(200).json({
            success: true,
            message: `Redis cache cleared successfully for ${clearScope}`,
            type,
            deletedCount
        });
    } catch (error) {
        console.error('Error clearing Redis cache:', error);
        return res.status(500).json({
            success: false,
            message: `Failed to clear Redis cache: ${error.message}`
        });
    }
};
