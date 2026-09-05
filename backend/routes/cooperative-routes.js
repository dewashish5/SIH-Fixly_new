import express from 'express';
import { protect } from '../middleware/authMiddleware.js';
import { getCooperativeInfo } from '../controllers/cooperativeController.js';

const router = express.Router();
router.get('/info', protect, getCooperativeInfo);
export default router;
