import express from 'express';
import { protect, optionalProtect } from '../middleware/authMiddleware.js';
import {
    listMyNotifications,
    markNotificationRead,
    markAllNotificationsRead,
    deleteMyNotification,
    registerDeviceToken,
    removeDeviceToken,
    sendTestNotification,
} from '../controllers/notificationController.js';

const router = express.Router();
router.post('/device-token', optionalProtect, registerDeviceToken);
router.use(protect);
router.get('/', listMyNotifications);
router.patch('/read-all', markAllNotificationsRead);
router.patch('/:id/read', markNotificationRead);
router.delete('/:id', deleteMyNotification);
router.delete('/device-token', removeDeviceToken);
router.post('/test', sendTestNotification);
export default router;
