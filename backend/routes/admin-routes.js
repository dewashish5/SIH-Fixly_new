import express from 'express';
import jwt from 'jsonwebtoken';
import upload from '../middleware/uploadMiddleware.js';
import {
    adminLogin,
    getAdminProfile,
    updateAdminMe,
    getDashboardStats,
    getCustomers,
    getCustomerById,
    toggleCustomerStatus,
    getWorkers,
    getWorkerById,
    updateWorkerById,
    updateWorkerStatus,
    addWorker,
    getBookings,
    getBookingById,
    assignWorkerToBooking,
    updateBookingStatus,
    getServices,
    getAdminCategories,
    createCategory,
    createService,
    updateService,
    deleteService,
    getPayments,
    getPaymentStats,
    getReviews,
    deleteReview,
    sendAdminNotification,
    getNotifications,
    markAllNotificationsRead,
    deleteNotification,
    getAnalytics,
    getAIInsights,
    uploadAdminFile,
    getReportsData,
    getSettings,
    updateSettings,
} from '../controllers/adminController.js';
import {
    adminGetWorkerVerification,
    adminReviewWorkerVerification,
    adminListCertificates,
    adminReviewCertificate,
} from '../controllers/workerCertificateController.js';
import {
    adminListTickets,
    getTicket,
    adminPatchTicket,
    addTicketMessage,
} from '../controllers/supportController.js';
import {
    adminGetCooperative,
    adminUpdateCooperative,
    adminCooperativeMembers,
} from '../controllers/cooperativeController.js';
import { adminWelfareSummary } from '../controllers/welfareController.js';
import { adminListPayouts } from '../controllers/workerWalletController.js';

const router = express.Router();

// ==========================================
// ADMIN AUTH MIDDLEWARE
// ==========================================
export const adminProtect = (req, res, next) => {
    try {
        let token;
        if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
            token = req.headers.authorization.split(' ')[1];
        }

        if (!token) {
            return res.status(401).json({ success: false, message: 'Admin authentication required, token missing' });
        }

        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        if (decoded.role !== 'admin') {
            return res.status(403).json({ success: false, message: 'Forbidden. Access restricted to admin users.' });
        }

        req.user = decoded;
        next();
    } catch (error) {
        if (error.name === 'TokenExpiredError') {
            return res.status(401).json({ success: false, message: 'Admin token expired, please login again' });
        }
        return res.status(401).json({ success: false, message: 'Invalid admin authentication token' });
    }
};

// ==========================================
// PUBLIC ADMIN ROUTES
// ==========================================
router.post('/login', adminLogin);

// ==========================================
// PROTECTED ADMIN ROUTES
// ==========================================
router.use(adminProtect);

// Profile & Dashboard
router.get('/me', getAdminProfile);
router.put('/me', updateAdminMe);
router.get('/dashboard', getDashboardStats);

// Customers
router.get('/customers', getCustomers);
router.get('/customers/:id', getCustomerById);
router.patch('/customers/:id/status', toggleCustomerStatus);

// Workers
router.get('/workers', getWorkers);
router.get('/workers/:id', getWorkerById);
router.post('/workers', addWorker);
router.put('/workers/:id', updateWorkerById);
router.patch('/workers/:id/status', updateWorkerStatus);

// Bookings (supports both :id and :bookingId)
router.get('/bookings', getBookings);
router.get('/bookings/:id', getBookingById);
router.patch('/bookings/:id/assign', assignWorkerToBooking);
router.patch('/bookings/:id/status', updateBookingStatus);
router.patch('/bookings/:bookingId/assign', assignWorkerToBooking);
router.patch('/bookings/:bookingId/status', updateBookingStatus);

// Categories & Services Management with Image Upload & Redis Push
const uploadCategoryMedia = (req, res, next) => {
    upload.fields([{ name: 'image', maxCount: 1 }, { name: 'file', maxCount: 1 }])(req, res, (err) => {
        if (err) return res.status(400).json({ success: false, message: err.message });
        if (req.files) {
            req.file = req.files['image']?.[0] || req.files['file']?.[0] || null;
        }
        next();
    });
};

router.get('/categories', getAdminCategories);
router.post('/categories', uploadCategoryMedia, createCategory);
router.get('/services', getServices);
router.post('/services', uploadCategoryMedia, createService);
router.put('/services/:id', updateService);
router.delete('/services/:id', deleteService);
router.post('/upload', upload.single('file'), uploadAdminFile);

// Payments & Financials
router.get('/payments', getPayments);
router.get('/payments/stats', getPaymentStats);

// Reviews Moderation
router.get('/reviews', getReviews);
router.delete('/reviews/:id', deleteReview);

// Notifications & Broadcast
router.get('/notifications', getNotifications);
router.post('/notifications/broadcast', sendAdminNotification);
router.put('/notifications/mark-read', markAllNotificationsRead);
router.delete('/notifications/:id', deleteNotification);

// Analytics & AI Insights
router.get('/analytics', getAnalytics);
router.get('/ai-insights', getAIInsights);
router.get('/reports', getReportsData);

// Platform Governance Settings
router.get('/settings', getSettings);
router.put('/settings', updateSettings);

// Worker KYC Verification & Certificates
router.get('/workers/:id/verification', adminGetWorkerVerification);
router.patch('/workers/:id/verification', adminReviewWorkerVerification);
router.get('/workers/:workerId/certificates', adminListCertificates);
router.patch('/workers/:workerId/certificates/:certificateId', adminReviewCertificate);

// Support Management
router.get('/support/tickets', adminListTickets);
router.get('/support/tickets/:id', getTicket);
router.patch('/support/tickets/:id', adminPatchTicket);
router.post('/support/tickets/:id/messages', addTicketMessage);

// Cooperative & Welfare Governance
router.get('/cooperative', adminGetCooperative);
router.put('/cooperative', adminUpdateCooperative);
router.get('/cooperative/members', adminCooperativeMembers);
router.get('/welfare/summary', adminWelfareSummary);
router.get('/worker-payouts', adminListPayouts);

export default router;
