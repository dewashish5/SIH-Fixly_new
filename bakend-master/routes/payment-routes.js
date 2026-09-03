import express from 'express';
import {
    createOrder,
    verifyPayment,
    getCustomerWalletAndHistory,
    getWorkerWalletAndHistory
} from '../controllers/paymentController.js';
import { protect } from '../middleware/authMiddleware.js';

const router = express.Router();

router.post('/create-order', protect, createOrder);
router.post('/verify', protect, verifyPayment);
router.get('/wallet-history', protect, getCustomerWalletAndHistory);
router.get('/worker-wallet', protect, getWorkerWalletAndHistory);

export default router;