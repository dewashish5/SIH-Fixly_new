import express from 'express';
import { protect } from '../middleware/authMiddleware.js';
import {
    listMyNotifications,
    markNotificationRead,
    markAllNotificationsRead,
    deleteMyNotification,
    registerDeviceToken,
    removeDeviceToken,
} from '../controllers/notificationController.js';

const router = express.Router();
router.use(protect);
router.get('/', listMyNotifications);
router.patch('/read-all', markAllNotificationsRead);
router.patch('/:id/read', markNotificationRead);
router.delete('/:id', deleteMyNotification);
router.post('/device-token', registerDeviceToken);
router.delete('/device-token', removeDeviceToken);
export default router;
