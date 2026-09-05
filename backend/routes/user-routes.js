import express from 'express';
import { protect } from '../middleware/authMiddleware.js';
import {
    getMyProfile,
    updateMyProfile,
    updateLanguage,
    updateLocation,
    updateEmergencyContact,
    listAddresses,
    addAddress,
    updateAddress,
    deleteAddress,
} from '../controllers/userController.js';

const router = express.Router();
router.use(protect);
router.get('/me', getMyProfile);
router.put('/me', updateMyProfile);
router.patch('/me', updateMyProfile);
router.patch('/me/language', updateLanguage);
router.patch('/me/location', updateLocation);
router.patch('/me/emergency-contact', updateEmergencyContact);
router.get('/me/addresses', listAddresses);
router.post('/me/addresses', addAddress);
router.put('/me/addresses/:id', updateAddress);
router.delete('/me/addresses/:id', deleteAddress);
export default router;
