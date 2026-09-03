import express from 'express';
import { protect } from '../middleware/authMiddleware.js';
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
import { updateMyProfile } from '../controllers/userController.js';

const router = express.Router();

router.get('/me', protect, getMe);
router.patch('/me', protect, updateMyProfile);
router.put('/me', protect, updateMyProfile);
router.post('/register', registerUser);
router.post('/verify-otp', verifyOTP);
router.post('/login', loginUser);
router.post('/refresh-token', refreshToken);
router.post('/google', googleLogin);
router.post('/forgot-password', forgotPassword);
router.post('/reset-password', resetPassword);
router.post('/logout', logoutUser);

export default router;