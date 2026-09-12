import { Worker } from 'bullmq';

import redis from '../config/redis.js';
import Notification from '../models/Notification.js';
import PushToken from '../models/PushToken.js';
import { isPermanentTokenError, sendToTopic, sendToTokens } from '../services/fcmService.js';

const maskToken = (token) => {
    if (!token || token.length < 8) return '[token]';
    return `${token.slice(0, 4)}…${token.slice(-4)}`;
};

const stringifyData = (data = {}, notification) => {
    const payload = {
        notificationId: String(notification._id),
        eventType: notification.eventType || '',
        entityType: notification.entityType || '',
        entityId: notification.entityId || '',
        bookingId: notification.bookingId || '',
        action: notification.data?.action || '',
        version: notification.data?.version || '1',
        ...data,
    };
    return Object.fromEntries(
        Object.entries(payload)
            .filter(([, value]) => value != null)
            .map(([key, value]) => [key, String(value)]),
    );
};

const notificationWorker = new Worker('notificationQueue', async (job) => {
    const started = Date.now();
    const notification = await Notification.findById(job.data.notificationId);
    if (!notification) return;

    await notification.updateOne({ $inc: { deliveryAttempts: 1 } });
    try {
        if (job.name === 'send-topic-push') {
            await sendToTopic({
                topic: job.data.topic,
                title: notification.title,
                body: notification.body || notification.message,
                data: stringifyData({ eventType: job.data.eventType }, notification),
            });
            await notification.updateOne({ deliveryStatus: 'SENT', sentAt: new Date(), deliveredAt: new Date() });
            console.log('[notifications]', JSON.stringify({
                notificationId: String(notification._id),
                eventType: notification.eventType,
                channel: 'TOPIC',
                topic: job.data.topic,
                status: 'SENT',
                attempt: notification.deliveryAttempts + 1,
                latencyMs: Date.now() - started,
            }));
            return;
        }

        const recipientUserId = job.data.recipientUserId || notification.recipient;
        const tokens = await PushToken.find({ user: recipientUserId, isActive: true }).select('token').lean();
        if (!tokens.length) {
            await notification.updateOne({ deliveryStatus: 'SKIPPED', lastDeliveryError: 'No active push tokens' });
            return;
        }

        const tokenValues = tokens.map(({ token }) => token);
        const result = await sendToTokens({
            tokens: tokenValues,
            title: notification.title,
            body: notification.body || notification.message,
            data: stringifyData({}, notification),
        });

        const invalidTokens = result.responses
            .map((response, index) => ({ response, token: tokenValues[index] }))
            .filter(({ response }) => !response.success && isPermanentTokenError(response.error))
            .map(({ token }) => token);
        if (invalidTokens.length) {
            await PushToken.updateMany({ token: { $in: invalidTokens } }, { isActive: false });
        }

        const status = result.failureCount
            ? (result.successCount ? 'PARTIAL' : 'FAILED')
            : 'SENT';
        await notification.updateOne({
            deliveryStatus: status,
            sentAt: new Date(),
            deliveredAt: result.successCount ? new Date() : null,
            lastDeliveryError: result.failureCount ? 'One or more push tokens failed.' : null,
        });
        console.log('[notifications]', JSON.stringify({
            notificationId: String(notification._id),
            eventType: notification.eventType,
            recipientUserId: String(recipientUserId),
            channel: 'PUSH',
            tokens: tokenValues.map(maskToken),
            status,
            attempt: notification.deliveryAttempts + 1,
            latencyMs: Date.now() - started,
        }));
    } catch (error) {
        await notification.updateOne({ deliveryStatus: 'FAILED', lastDeliveryError: error.message });
        console.error('[notifications]', JSON.stringify({
            notificationId: String(notification._id),
            eventType: notification.eventType,
            status: 'FAILED',
            error: error.message,
            latencyMs: Date.now() - started,
        }));
        throw error;
    }
}, { connection: redis, concurrency: 10 });

notificationWorker.on('completed', (job) => console.log(`Notification job ${job.id} completed.`));
notificationWorker.on('failed', (job, error) => console.error(`Notification job ${job?.id} failed:`, error.message));

export default notificationWorker;
