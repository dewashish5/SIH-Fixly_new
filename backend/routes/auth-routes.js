import express from 'express';
import { protect } from '../middleware/authMiddleware.js';
import { upload } from '../utils/upload.js';
import {
    registerUser,
    verifyOTP,
    loginUser,
    googleLogin,
    refreshToken,
    forgotPassword,
    resetPassword,
    logoutUser,
    getMe,
    updateUserProfile,
    registerFederation
} from '../controllers/authController.js';
import { updateMyProfile } from '../controllers/userController.js';

const router = express.Router();

router.get('/me', protect, getMe);
router.put('/profile', protect, upload.any(), updateUserProfile);
router.patch('/me', protect, updateMyProfile);
router.put('/me', protect, updateMyProfile);
router.post('/register', registerUser);
router.post('/register-federation', registerFederation);
router.post('/verify-otp', verifyOTP);
router.post('/login', loginUser);
router.post('/google', googleLogin);
router.post('/refresh-token', refreshToken);
router.post('/forgot-password', forgotPassword);
router.post('/reset-password', resetPassword);
router.post('/logout', logoutUser);

export default router;