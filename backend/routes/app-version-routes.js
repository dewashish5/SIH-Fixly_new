import express from 'express';
import {
    checkAppVersion,
    updateAppVersion,
    getAppVersionAdmin,
    getAllVersions,
    clearRedisCache
} from '../controllers/appVersionController.js';

const router = express.Router();

// Public route: Mobile (Flutter) splash screen check
router.get('/', checkAppVersion);
router.get('/check', checkAppVersion);

// Version configuration endpoints
router.get('/admin', getAppVersionAdmin);
router.get('/all', getAllVersions);
router.put('/', updateAppVersion);
router.post('/', updateAppVersion);

// Redis Cache Management endpoints (e.g. /api/version/redis/clear/user, /booking, /all)
router.all('/redis/clear', clearRedisCache);
router.all('/redis/clear/:type', clearRedisCache);
router.all('/redis/flush-all', (req, res) => {
    req.params.type = 'all';
    return clearRedisCache(req, res);
});

export default router;
