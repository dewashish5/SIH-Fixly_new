import express from 'express';
import {
    getNearbyWorkers,
    getWorkerProfile,
    setupWorkerProfile,
    getMyAvailability,
    patchMyAvailability,
    putAvailabilitySchedule,
    getWorkerReliability,
} from '../controllers/workerController.js';
import {
    createCertificate,
    listMyCertificates,
    getCertificate,
    deleteCertificate,
} from '../controllers/workerCertificateController.js';
import {
    getWallet,
    getEarnings,
    getEarningsSummary,
    getTransactions,
    listPayouts,
    requestWithdraw,
} from '../controllers/workerWalletController.js';
import { getMyMembership } from '../controllers/cooperativeController.js';
import {
    getWelfare,
    getWelfareTransactions,
    getInsurance,
    getInsuranceClaims,
    createInsuranceClaim,
} from '../controllers/welfareController.js';
import { getWorkerReviews } from '../controllers/reviewController.js';
import { protect, authorize } from '../middleware/authMiddleware.js';
import { upload } from '../utils/upload.js';

const router = express.Router();

router.get('/', protect, getNearbyWorkers);
router.put('/setup-profile', protect, upload.any(), setupWorkerProfile);

router.get('/me/availability', protect, authorize('worker'), getMyAvailability);
router.patch('/me/availability', protect, authorize('worker'), patchMyAvailability);
router.put('/me/availability/schedule', protect, authorize('worker'), putAvailabilitySchedule);

router.post('/me/certificates', protect, authorize('worker'), createCertificate);
router.get('/me/certificates', protect, authorize('worker'), listMyCertificates);
router.get('/me/certificates/:id', protect, authorize('worker'), getCertificate);
router.delete('/me/certificates/:id', protect, authorize('worker'), deleteCertificate);

router.get('/me/wallet', protect, authorize('worker'), getWallet);
router.get('/me/earnings', protect, authorize('worker'), getEarnings);
router.get('/me/earnings/summary', protect, authorize('worker'), getEarningsSummary);
router.get('/me/transactions', protect, authorize('worker'), getTransactions);
router.get('/me/payouts', protect, authorize('worker'), listPayouts);
router.post('/me/withdraw', protect, authorize('worker'), requestWithdraw);
router.get('/me/membership', protect, authorize('worker'), getMyMembership);
router.get('/me/welfare', protect, authorize('worker'), getWelfare);
router.get('/me/welfare/transactions', protect, authorize('worker'), getWelfareTransactions);
router.get('/me/insurance', protect, authorize('worker'), getInsurance);
router.get('/me/insurance/claims', protect, authorize('worker'), getInsuranceClaims);
router.post('/me/insurance/claims', protect, authorize('worker'), createInsuranceClaim);

router.get('/:workerId/reliability', protect, getWorkerReliability);
router.get('/:workerId/reviews', protect, getWorkerReviews);
router.get('/:workerId', protect, getWorkerProfile);

export default router;
