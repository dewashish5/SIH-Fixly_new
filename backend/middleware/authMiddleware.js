import jwt from 'jsonwebtoken';
import redis from '../config/redis.js';

// ==========================================
// 1. PROTECT MIDDLEWARE (Auth + Single Device Security)
// ==========================================
export const protect = async (req, res, next) => {
    try {
        let token;

        // 1. Extract Bearer Token from Authorization Header
        if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
            token = req.headers.authorization.split(' ')[1];
        }

        if (!token) {
            return res.status(401).json({ success: false, message: 'Not authorized, token missing' });
        }

        // 2. Verify JWT Access Token
        const decoded = jwt.verify(token, process.env.JWT_SECRET);

        // 3. Single-Device Check (Headers me x-device-id pass karein)
        const deviceId = req.headers['x-device-id'];
        if (deviceId) {
            const activeDeviceId = await redis.get(`user:active-device:${decoded.id}`);
            if (activeDeviceId && activeDeviceId !== deviceId) {
                return res.status(401).json({
                    success: false,
                    message: 'Session expired. Account logged in on another device.'
                });
            }
        }

        // 4. Attach decoded payload to req object
        req.user = {
            id: decoded.id,
            role: decoded.role
        };

        next();
    } catch (error) {
        if (error.name === 'TokenExpiredError') {
            return res.status(401).json({ success: false, message: 'Token expired, please refresh' });
        }
        return res.status(401).json({ success: false, message: 'Not authorized, token failed' });
    }
};

// ==========================================
// 2. ROLE AUTHORIZATION MIDDLEWARE
// ==========================================
export const authorize = (...allowedRoles) => {
    return (req, res, next) => {
        if (!req.user || !allowedRoles.includes(req.user.role)) {
            return res.status(403).json({
                success: false,
                message: `Access denied. Role '${req.user?.role}' is not allowed.`
            });
        }
        next();
    };
};