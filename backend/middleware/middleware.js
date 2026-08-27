import jwt from 'jsonwebtoken';
import redis from '../config/redis.js';

export const protect = async (req, res, next) => {
    try {
        let token;

        // 1. Check if Authorization header exists and starts with Bearer
        if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
            token = req.headers.authorization.split(' ')[1];
        }

        if (!token) {
            return res.status(401).json({ success: false, message: 'Not authorized, token missing' });
        }

        // 2. Verify Access Token
        const decoded = jwt.verify(token, process.env.JWT_SECRET);

        // 3. Optional Performance Check: Check if user session/cache is valid or fetch user ID

        req.user = {
            id: decoded.id,
            role: decoded.role
        };

        next(); // Agle controller ya route par bhej do
    } catch (error) {
        if (error.name === 'TokenExpiredError') {
            return res.status(401).json({ success: false, message: 'Token expired, please refresh' });
        }
        return res.status(401).json({ success: false, message: 'Not authorized, token failed' });
    }
};