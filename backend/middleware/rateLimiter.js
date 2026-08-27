import rateLimit from 'express-rate-limit';

// 1. Strict Limiter for Auth Routes (Login, Register, OTP)
export const authLimiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 Minutes
    max: 5, // Ek IP se 15 minutes mein maximum 5 requests allow hongi
    message: {
        success: false,
        message: 'Too many requests from this IP, please try again after 15 minutes'
    },
    standardHeaders: true, // Return rate limit info in the `RateLimit-*` headers
    legacyHeaders: false, // Disable the `X-RateLimit-*` headers
});

// 2. General Limiter for Other APIs
export const apiLimiter = rateLimit({
    windowMs: 1 * 60 * 1000, // 1 Minute
    max: 60, // 1 minute mein 60 requests
    message: {
        success: false,
        message: 'Too many requests, please slow down.'
    }
});