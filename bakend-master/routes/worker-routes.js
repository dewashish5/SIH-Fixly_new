import express from 'express';
import { getNearbyWorkers, getWorkerProfile } from '../controllers/workerController.js';
import { protect } from '../middleware/authMiddleware.js';

const router = express.Router();

// Nearby workers search & worker detail profile
router.get('/', protect, getNearbyWorkers);
router.get('/:workerId', protect, getWorkerProfile);

export default router;