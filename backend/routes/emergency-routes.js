import express from 'express';
import { getEmergencyContacts, seedDefaultContacts } from '../controllers/emergencyController.js';
import { protect, authorize } from '../middleware/authMiddleware.js';

const router = express.Router();

router.get('/contacts', protect, getEmergencyContacts);
router.post('/seed', protect, authorize('admin', 'super_admin'), seedDefaultContacts);

export default router;
