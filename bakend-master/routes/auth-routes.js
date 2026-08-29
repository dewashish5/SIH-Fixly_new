import express from 'express';
import {
    registerUser,
    verifyOTP,
    loginUser,
    refreshToken,
    googleLogin,
    forgotPassword,
    resetPassword,
    logoutUser,
    getMe
} from '../controllers/authController.js';

const router = express.Router();

router.get('/me', getMe);
router.post('/register', registerUser);
router.post('/verify-otp', verifyOTP);
router.post('/login', loginUser);
router.post('/refresh-token', refreshToken);
router.post('/google', googleLogin);
router.post('/forgot-password', forgotPassword);
router.post('/reset-password', resetPassword);
router.post('/logout', logoutUser);

export default router;