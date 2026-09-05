import Notification from '../models/Notification.js';
import PushToken from '../models/PushToken.js';
import { notificationQueue } from '../queues/notificationQueue.js';

export const notifyUser = async ({
    recipient,
    title,
    body,
    eventType,
    category = 'SYSTEM',
    priority = 'Normal',
    entityType = null,
    entityId = null,
    bookingId = null,
    data = {},
    dedupeKey = null,
    channel = 'MULTI',
}) => {
    if (dedupeKey) {
        const existing = await Notification.findOne({ dedupeKey });
        if (existing) return existing;
    }

    const notification = await Notification.create({
        recipient,
        title,
        message: body,
        body,
        eventType,
        category,
        priority,
        entityType,
        entityId,
        bookingId,
        dedupeKey,
        channel,
        data: { ...data, eventType, entityType, entityId, bookingId },
        deliveryStatus: channel === 'IN_APP' ? 'SKIPPED' : 'PENDING',
    });

    if (channel !== 'IN_APP') {
        const tokens = await PushToken.find({ user: recipient, isActive: true }).select('token').lean();
        if (tokens.length) {
            await notification.updateOne({ deliveryStatus: 'QUEUED' });
            await notificationQueue.add('send-push', {
                notificationId: notification.id,
                tokens: tokens.map(({ token }) => token),
            }, { jobId: `notification:${notification.id}` });
        } else {
            await notification.updateOne({ deliveryStatus: 'SKIPPED' });
        }
    }

    return notification;
};

export const notifyTopic = async ({
    topic,
    title,
    body,
    eventType = 'SYSTEM_ANNOUNCEMENT',
    category = 'SYSTEM',
    priority = 'Normal',
    data = {},
}) => {
    const notification = await Notification.create({
        title,
        message: body,
        body,
        eventType,
        category,
        priority,
        channel: 'PUSH',
        deliveryStatus: 'QUEUED',
        data: { ...data, eventType },
    });
    await notificationQueue.add('send-topic-push', {
        notificationId: notification.id,
        topic,
    }, { jobId: `notification:${notification.id}` });
    return notification;
};