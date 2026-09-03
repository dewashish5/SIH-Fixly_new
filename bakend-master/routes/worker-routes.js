import express from 'express';
import {
    getNearbyWorkers,
    getWorkerProfile,
    setupWorkerProfile,
} from '../controllers/workerController.js';
import { protect } from '../middleware/authMiddleware.js';

const router = express.Router();

router.get('/', protect, getNearbyWorkers);
router.put('/setup-profile', protect, setupWorkerProfile);
router.get('/:workerId', protect, getWorkerProfile);

export default router;
