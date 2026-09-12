import express from 'express';
import { protect, authorize } from '../middleware/authMiddleware.js';
import {
    getWallet,
    getEarnings,
    getEarningsSummary,
    getTransactions,
    listPayouts,
    requestWithdraw,
} from '../controllers/workerWalletController.js';

const router = express.Router();
router.use(protect, authorize('worker'));
router.get('/wallet', getWallet);
router.get('/earnings', getEarnings);
router.get('/earnings/summary', getEarningsSummary);
router.get('/transactions', getTransactions);
router.get('/payouts', listPayouts);
router.post('/withdraw', requestWithdraw);
export default router;
