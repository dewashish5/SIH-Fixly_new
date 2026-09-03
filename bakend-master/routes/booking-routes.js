import express from 'express';
import {
    calculateEstimate,
    createBooking,
    getBookingDetails,
    cancelBooking,
    getLiveTracking,
    getBookingInvoice,
    triggerSosAlert,
    getBookingHistory
} from '../controllers/bookingController.js';
import {
    verifyArrivalOtp,
    addExtraParts,
    completeJob,
    acceptBooking,
    startJob
} from '../controllers/activeJobController.js';
import { protect } from '../middleware/authMiddleware.js';
import upload from '../middleware/uploadMiddleware.js';

const router = express.Router();

// Search & Booking Creation
router.get('/history', protect, getBookingHistory);
router.post('/estimate', protect, calculateEstimate);
router.post('/', protect, upload.array('photos', 5), createBooking);
router.get('/:bookingId', protect, getBookingDetails);
router.patch('/:bookingId/cancel', protect, cancelBooking);

// Verification & Live Tracking
router.get('/:bookingId/track', protect, getLiveTracking);
router.post('/:bookingId/accept', protect, acceptBooking);
router.post('/:bookingId/verify-otp', protect, verifyArrivalOtp);
router.post('/:bookingId/start-job', protect, startJob);

// Job Execution & Extra Parts
router.patch('/:bookingId/add-parts', protect, addExtraParts);
router.post('/:bookingId/complete', protect, completeJob);
router.post('/:bookingId/sos', protect, triggerSosAlert);

// Billing & Invoice
router.get('/:bookingId/invoice', protect, getBookingInvoice);

export default router;