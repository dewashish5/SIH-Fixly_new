import express from 'express';
import { protect, authorize } from '../middleware/authMiddleware.js';
import upload from '../middleware/uploadMiddleware.js';
import {
    adminLogin,
    adminMe,
    updateAdminMe,
    getDashboard,
    listCustomers,
    getCustomerById,
    toggleCustomerStatus,
    listWorkers,
    getWorkerById,
    updateWorker,
    updateWorkerStatus,
    addWorker,
    listBookings,
    getBookingById,
    assignWorkerToBooking,
    updateBookingStatus,
    listServices,
    createServiceAdmin,
    updateServiceAdmin,
    deleteServiceAdmin,
    listPayments,
    paymentStats,
    listReviews,
    deleteReview,
    getNotifications,
    broadcastNotification,
    markNotificationsRead,
    deleteNotification,
    getAnalytics,
    getAIInsights,
    getReports,
    getSettings,
    updateSettings,
    adminUpload,
} from '../controllers/adminController.js';

const router = express.Router();

router.post('/login', adminLogin);

router.use(protect, authorize('admin'));

router.get('/me', adminMe);
router.put('/me', updateAdminMe);
router.get('/dashboard', getDashboard);

router.get('/customers', listCustomers);
router.get('/customers/:id', getCustomerById);
router.patch('/customers/:id/status', toggleCustomerStatus);

router.get('/workers', listWorkers);
router.get('/workers/:id', getWorkerById);
router.put('/workers/:id', updateWorker);
router.patch('/workers/:id/status', updateWorkerStatus);
router.post('/workers', addWorker);

router.get('/bookings', listBookings);
router.get('/bookings/:id', getBookingById);
router.patch('/bookings/:bookingId/assign', assignWorkerToBooking);
router.patch('/bookings/:bookingId/status', updateBookingStatus);

router.get('/services', listServices);
router.post('/services', createServiceAdmin);
router.put('/services/:id', updateServiceAdmin);
router.delete('/services/:id', deleteServiceAdmin);

router.get('/payments', listPayments);
router.get('/payments/stats', paymentStats);

router.get('/reviews', listReviews);
router.delete('/reviews/:id', deleteReview);

router.get('/notifications', getNotifications);
router.post('/notifications/broadcast', broadcastNotification);
router.put('/notifications/mark-read', markNotificationsRead);
router.delete('/notifications/:id', deleteNotification);

router.get('/analytics', getAnalytics);
router.get('/ai-insights', getAIInsights);
router.get('/reports', getReports);

router.get('/settings', getSettings);
router.put('/settings', updateSettings);

router.post('/upload', upload.single('file'), adminUpload);

export default router;
