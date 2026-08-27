import express from 'express';
import {
    registerUser,
    verifyOTP,
    loginUser,
    refreshToken,
    googleLogin,
    forgotPassword,
    resetPassword,
    logoutUser
} from '../controllers/authController.js';

const router = express.Router();

// 1. Local Auth Routes
router.post('/register', registerUser);
router.post('/verify-otp', verifyOTP);
router.post('/login', loginUser);
router.post('/refresh-token', refreshToken);

// 2. Google Firebase Auth Route
router.post('/google', googleLogin);

// 3. Password Reset Routes
router.post('/forgot-password', forgotPassword);
router.post('/reset-password', resetPassword);

// 4. Session Routes
router.post('/logout', logoutUser);

export default router;