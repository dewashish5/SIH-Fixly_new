import express from 'express';
import { protect, authorize } from '../middleware/authMiddleware.js';
import {
    getCooperativeInfo,
    getMyMembership,
    listSocieties,
    getSocietyById
} from '../controllers/cooperativeController.js';

const router = express.Router();

router.get('/info', protect, getCooperativeInfo);
router.get('/societies', protect, listSocieties);
router.get('/societies/:id', protect, getSocietyById);
router.get('/my-society', protect, authorize('worker'), getMyMembership);

export default router;
