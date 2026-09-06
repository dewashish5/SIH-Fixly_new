import User from '../models/User.js';
import PushToken from '../models/PushToken.js';
import Notification from '../models/Notification.js';
import { fail, ok, isObjectId } from '../utils/http.js';

export const listMyNotifications = async (req, res) => {
    try {
        const page = Math.max(1, Number(req.query.page) || 1);
        const limit = Math.min(50, Math.max(1, Number(req.query.limit) || 20));
        const query = { recipient: req.user.id };
        const [items, total] = await Promise.all([
            Notification.find(query).sort({ createdAt: -1 }).skip((page - 1) * limit).limit(limit),
            Notification.countDocuments(query),
        ]);
        return ok(res, { data: items, page, limit, total });
    } catch (error) {
        return fail(res, 500, 'INTERNAL_ERROR', error.message);
    }
};

export const markNotificationRead = async (req, res) => {
    try {
        if (!isObjectId(req.params.id)) return fail(res, 400, 'VALIDATION_ERROR', 'Invalid id');
        const item = await Notification.findOneAndUpdate(
            { _id: req.params.id, recipient: req.user.id },
            { isRead: true, unread: false },
            { returnDocument: 'after' },
        );
        if (!item) return fail(res, 404, 'NOT_FOUND', 'Notification not found');
        return ok(res, { data: item });
    } catch (error) {
        return fail(res, 500, 'INTERNAL_ERROR', error.message);
    }
};

export const markAllNotificationsRead = async (req, res) => {
    try {
        await Notification.updateMany(
            { recipient: req.user.id, isRead: false },
            { isRead: true, unread: false },
        );
        return ok(res, { data: { updated: true } });
    } catch (error) {
        return fail(res, 500, 'INTERNAL_ERROR', error.message);
    }
};

export const deleteMyNotification = async (req, res) => {
    try {
        const item = await Notification.findOneAndDelete({
            _id: req.params.id,
            recipient: req.user.id,
        });
        if (!item) return fail(res, 404, 'NOT_FOUND', 'Notification not found');
        return ok(res, { data: { deleted: true } });
    } catch (error) {
        return fail(res, 500, 'INTERNAL_ERROR', error.message);
    }
};

export const registerDeviceToken = async (req, res) => {
    try {
        const token = req.body.token || req.body.deviceToken;
        if (!token) return fail(res, 400, 'VALIDATION_ERROR', 'token required');
        const deviceId = req.body.deviceId || req.headers['x-device-id'];
        if (!deviceId) return fail(res, 400, 'VALIDATION_ERROR', 'deviceId required');
        const updateDoc = {
            deviceId,
            platform: req.body.platform || 'unknown',
            appVersion: req.body.appVersion || null,
            locale: req.body.locale || 'en',
            isActive: true,
            lastSeenAt: new Date(),
        };
        if (req.user?.id) {
            updateDoc.user = req.user.id;
        }
        await PushToken.findOneAndUpdate(
            { token },
            updateDoc,
            { upsert: true, new: true, setDefaultsOnInsert: true },
        );
        if (req.user?.id) {
            await User.findByIdAndUpdate(req.user.id, { $addToSet: { pushTokens: token } });
        }
        return ok(res, { data: { registered: true } });
    } catch (error) {
        return fail(res, 500, 'INTERNAL_ERROR', error.message);
    }
};

export const removeDeviceToken = async (req, res) => {
    try {
        const token = req.body.token || req.body.deviceToken;
        if (!token) return fail(res, 400, 'VALIDATION_ERROR', 'token required');
        await PushToken.findOneAndUpdate(
            { user: req.user.id, token },
            { isActive: false, lastSeenAt: new Date() },
        );
        await User.findByIdAndUpdate(req.user.id, { $pull: { pushTokens: token } });
        return ok(res, { data: { removed: true } });
    } catch (error) {
        return fail(res, 500, 'INTERNAL_ERROR', error.message);
    }
};

export const sendTestNotification = async (req, res) => {
    try {
        if (process.env.NODE_ENV === 'production') {
            return fail(res, 404, 'NOT_FOUND', 'Not found');
        }
        const { notifyUser } = await import('../services/notificationService.js');
        const item = await notifyUser({
            recipient: req.user.id,
            eventType: req.body.eventType || 'SYSTEM_ANNOUNCEMENT',
            title: req.body.title || 'Fixly test notification',
            body: req.body.body || 'FCM test from the Fixly backend.',
            entityId: req.user.id,
            dedupeKey: `TEST:${req.user.id}:${Date.now()}`,
        });
        return ok(res, { data: item });
    } catch (error) {
        return fail(res, 500, 'INTERNAL_ERROR', error.message);
    }
};
