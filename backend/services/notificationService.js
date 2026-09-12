import Notification from '../models/Notification.js';
import User from '../models/User.js';
import redis from '../config/redis.js';
import { notificationQueue } from '../queues/notificationQueue.js';
import { mapPriorityForStorage, resolveTemplate } from './notificationTemplates.js';

const stringifyIds = (value) => (value == null ? null : String(value));

export const safeNotify = (task) => {
    Promise.resolve()
        .then(task)
        .catch((error) => {
            console.error('[notifications]', error.message);
        });
};

export const notifyUser = async ({
    recipient,
    eventType,
    locale = null,
    entityId = null,
    bookingId = null,
    data = {},
    dedupeKey = null,
    title,
    body,
    category,
    priority,
    entityType,
    action,
    channel,
}) => {
    if (!recipient) return null;

    let userLocale = locale;
    if (!userLocale) {
        try {
            const cachedLang = await redis.get(`user:lang:${recipient}`);
            if (cachedLang) {
                userLocale = cachedLang;
            } else {
                const u = await User.findById(recipient).select('preferredLanguage').lean();
                if (u?.preferredLanguage) {
                    userLocale = u.preferredLanguage;
                    await redis.set(`user:lang:${recipient}`, u.preferredLanguage, 'EX', 86400 * 30);
                }
            }
        } catch (_) {}
    }
    userLocale = userLocale || 'en';

    const template = eventType ? resolveTemplate(eventType, userLocale) : null;
    const resolvedTitle = title || template?.title;
    const resolvedBody = body || template?.body;
    const resolvedCategory = category || template?.category || 'SYSTEM';
    const resolvedPriority = mapPriorityForStorage(priority || template?.priority || 'NORMAL');
    const resolvedEntityType = entityType || template?.entityType || null;
    const resolvedAction = action || template?.action || 'system';
    const resolvedChannel = channel || template?.channel || 'MULTI';
    const resolvedBookingId = stringifyIds(bookingId || (resolvedEntityType === 'booking' ? entityId : null));
    const resolvedEntityId = stringifyIds(entityId || resolvedBookingId);

    if (!resolvedTitle || !resolvedBody) {
        throw new Error('Notification title and body are required');
    }

    if (dedupeKey) {
        const existing = await Notification.findOne({ dedupeKey });
        if (existing) return existing;
    }

    const payload = {
        eventType: eventType || null,
        entityType: resolvedEntityType,
        entityId: resolvedEntityId,
        bookingId: resolvedBookingId,
        action: resolvedAction,
        version: '1',
        ...data,
    };

    const notification = await Notification.create({
        recipient,
        title: resolvedTitle,
        message: resolvedBody,
        body: resolvedBody,
        eventType: eventType || null,
        category: resolvedCategory,
        priority: resolvedPriority,
        entityType: resolvedEntityType,
        entityId: resolvedEntityId,
        bookingId: resolvedBookingId,
        ...(dedupeKey ? { dedupeKey } : {}),
        channel: resolvedChannel,
        data: payload,
        deliveryStatus: resolvedChannel === 'IN_APP' ? 'SKIPPED' : 'PENDING',
    });

    if (resolvedChannel !== 'IN_APP') {
        await notification.updateOne({ deliveryStatus: 'QUEUED' });
        try {
            await notificationQueue.add('send-push', {
                notificationId: notification.id,
                recipientUserId: String(recipient),
                eventType: eventType || null,
                channel: 'PUSH',
            }, { jobId: `notification_${notification.id}` });
        } catch (error) {
            await notification.updateOne({
                deliveryStatus: 'FAILED',
                lastDeliveryError: error.message,
            });
            console.error('[notifications] queue failed', error.message);
        }
    }

    return notification;
};

export const notifyUsers = async (recipients, options) => {
    const unique = [...new Set(recipients.filter(Boolean).map((id) => String(id)))];
    const results = [];
    for (let i = 0; i < unique.length; i += 50) {
        const batch = unique.slice(i, i + 50);
        const created = await Promise.allSettled(
            batch.map((recipient) => notifyUser({
                ...options,
                recipient,
                dedupeKey: options.dedupeKeyFor
                    ? options.dedupeKeyFor(recipient)
                    : options.dedupeKey,
            })),
        );
        results.push(...created);
    }
    return results;
};

export const notifyTopic = async ({
    topic,
    eventType = 'SYSTEM_ANNOUNCEMENT',
    locale = 'en',
    title,
    body,
    category,
    priority,
    data = {},
}) => {
    const template = resolveTemplate(eventType, locale);
    const notification = await Notification.create({
        title: title || template.title,
        message: body || template.body,
        body: body || template.body,
        eventType,
        category: category || template.category,
        priority: mapPriorityForStorage(priority || template.priority),
        channel: 'PUSH',
        deliveryStatus: 'QUEUED',
        data: { eventType, action: template.action, version: '1', ...data },
    });
    await notificationQueue.add('send-topic-push', {
        notificationId: notification.id,
        topic,
        eventType,
        channel: 'PUSH',
    }, { jobId: `notification_${notification.id}` });
    return notification;
};
