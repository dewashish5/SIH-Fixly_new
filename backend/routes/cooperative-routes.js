import express from 'express';
import { protect, authorize } from '../middleware/authMiddleware.js';
import {
    getCooperativeInfo,
    getMyMembership,
    listSocieties,
    getSocietyById,
    workerJoinSociety,
    getPublicFederations
} from '../controllers/cooperativeController.js';

const router = express.Router();

router.get('/federations', getPublicFederations);
router.get('/info', protect, getCooperativeInfo);
router.get('/societies', listSocieties);
router.get('/societies/:id', getSocietyById);
router.get('/my-society', protect, authorize('worker'), getMyMembership);
router.post('/join', protect, authorize('worker'), workerJoinSociety);

export default router;
