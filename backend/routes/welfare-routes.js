import express from 'express';
import { protect, authorize, optionalProtect } from '../middleware/authMiddleware.js';
import {
    getWelfare,
    getWelfareTransactions,
    getInsurance,
    getInsuranceClaims,
    createInsuranceClaim,
    getWelfareResources,
} from '../controllers/welfareController.js';

const router = express.Router();

// Allow optional auth for welfare resources so public / unauthenticated or workers can fetch them
router.get('/resources', optionalProtect, getWelfareResources);

// Worker-protected routes
router.use(protect, authorize('worker'));
router.get('/', getWelfare);
router.get('/transactions', getWelfareTransactions);
router.get('/insurance', getInsurance);
router.get('/insurance/claims', getInsuranceClaims);
router.post('/insurance/claims', createInsuranceClaim);

export default router;
