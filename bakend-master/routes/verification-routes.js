import express from 'express';
import { protect, authorize } from '../middleware/authMiddleware.js';
import {
    submitVerification,
    getMyVerification,
    resubmitVerification,
} from '../controllers/verificationController.js';

const router = express.Router();
router.use(protect, authorize('worker'));
router.post('/submit', submitVerification);
router.get('/me', getMyVerification);
router.post('/resubmit', resubmitVerification);
export default router;
