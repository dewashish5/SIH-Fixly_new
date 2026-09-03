import express from 'express';
import { protect, authorize } from '../middleware/authMiddleware.js';
import {
    getWelfare,
    getWelfareTransactions,
    getInsurance,
    getInsuranceClaims,
    createInsuranceClaim,
} from '../controllers/welfareController.js';

const router = express.Router();
router.use(protect, authorize('worker'));
router.get('/', getWelfare);
router.get('/transactions', getWelfareTransactions);
router.get('/insurance', getInsurance);
router.get('/insurance/claims', getInsuranceClaims);
router.post('/insurance/claims', createInsuranceClaim);
export default router;
