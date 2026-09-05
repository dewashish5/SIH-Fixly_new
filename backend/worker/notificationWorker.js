import { Worker } from 'bullmq';

import redis from '../config/redis.js';
import Notification from '../models/Notification.js';
import { isPermanentTokenError, sendToTopic, sendToTokens } from '../services/fcmService.js';
import PushToken from '../models/PushToken.js';

const notificationWorker = new Worker('notificationQueue', async (job) => {
    const notification = await Notification.findById(job.data.notificationId);
    if (!notification) return;

    await notification.updateOne({ $inc: { deliveryAttempts: 1 } });
    try {
        if (job.name === 'send-topic-push') {
            await sendToTopic({
                topic: job.data.topic,
                title: notification.title,
                body: notification.body || notification.message,
                data: { notificationId: notification.id, ...notification.data },
            });
            await notification.updateOne({ deliveryStatus: 'SENT', sentAt: new Date(), deliveredAt: new Date() });
            return;
        }

        const result = await sendToTokens({
            tokens: job.data.tokens,
            title: notification.title,
            body: notification.body || notification.message,
            data: { notificationId: notification.id, ...notification.data },
        });

        const invalidTokens = result.responses
            .map((response, index) => ({ response, token: job.data.tokens[index] }))
            .filter(({ response }) => !response.success && isPermanentTokenError(response.error))
            .map(({ token }) => token);
        if (invalidTokens.length) {
            await PushToken.updateMany({ token: { $in: invalidTokens } }, { isActive: false });
        }
        await notification.updateOne({
            deliveryStatus: result.failureCount ? 'PARTIAL' : 'SENT',
            sentAt: new Date(),
            deliveredAt: result.successCount ? new Date() : null,
            lastDeliveryError: result.failureCount ? 'One or more push tokens failed.' : null,
        });
    } catch (error) {
        await notification.updateOne({ deliveryStatus: 'FAILED', lastDeliveryError: error.message });
        throw error;
    }
}, { connection: redis, concurrency: 10 });

notificationWorker.on('completed', (job) => console.log(`Notification job ${job.id} completed.`));
notificationWorker.on('failed', (job, error) => console.error(`Notification job ${job?.id} failed:`, error.message));

export default notificationWorker;