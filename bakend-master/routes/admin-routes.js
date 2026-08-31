import express from 'express';
import { protect, authorize } from '../middleware/authMiddleware.js';
import {
    getAdminStats,
    listWorkers,
    updateWorkerKyc,
    listCustomers,
    listBookings,
    listServices,
    createAdminService,
    updateAdminService
} from '../controllers/adminController.js';

const router = express.Router();

router.use(protect, authorize('admin'));

router.get('/stats', getAdminStats);
router.get('/workers', listWorkers);
router.patch('/workers/:id/kyc', updateWorkerKyc);
router.get('/customers', listCustomers);
router.get('/bookings', listBookings);
router.get('/services', listServices);
router.post('/services', createAdminService);
router.patch('/services/:id', updateAdminService);

export default router;
