import mongoose from 'mongoose';

const notificationSchema = new mongoose.Schema({
    title: { type: String, required: true },
    message: { type: String, required: true },
    body: { type: String, default: null },
    category: {
        type: String,
        enum: [
            'BOOKING', 'PAYMENT', 'VERIFICATION', 'SUPPORT', 'SAFETY', 'SYSTEM', 'PROMOTION',
            'WALLET', 'PAYOUT',
            'Emergency', 'Payments', 'System', 'Surge', 'General',
        ],
        default: 'SYSTEM',
    },
    targetAudience: {
        type: String,
        enum: ['All Users', 'Workers Only', 'Customers Only', 'Specific Email', 'Workers', 'Customers', 'Emergency Staff'],
        default: 'All Users',
    },
    recipient: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null, index: true },
    role: { type: String, enum: ['customer', 'worker', 'admin'], default: null },
    recipientEmail: { type: String, default: null },
    sendEmail: { type: Boolean, default: false },
    priority: { type: String, enum: ['High', 'Medium', 'Normal', 'Urgent', 'Emergency', 'Low'], default: 'Normal' },
    eventType: { type: String, default: null, index: true },
    entityType: { type: String, default: null },
    entityId: { type: String, default: null },
    bookingId: { type: String, default: null },
    // Omit when unused — unique+sparse still indexes explicit null and blocks 2nd insert.
    dedupeKey: { type: String },
    channel: { type: String, enum: ['IN_APP', 'PUSH', 'EMAIL', 'MULTI'], default: 'IN_APP' },
    deliveryStatus: {
        type: String,
        enum: ['PENDING', 'QUEUED', 'SENT', 'FAILED', 'PARTIAL', 'SKIPPED'],
        default: 'PENDING',
    },
    deliveryAttempts: { type: Number, default: 0 },
    lastDeliveryError: { type: String, default: null },
    sentAt: { type: Date, default: null },
    deliveredAt: { type: Date, default: null },
    unread: { type: Boolean, default: true },
    isRead: { type: Boolean, default: false },
    data: { type: mongoose.Schema.Types.Mixed, default: {} },
}, { timestamps: true });

notificationSchema.index({ recipient: 1, createdAt: -1 });
notificationSchema.index({ deliveryStatus: 1, createdAt: -1 });
// Only unique when a real string key exists (null/missing allowed many times).
notificationSchema.index(
    { dedupeKey: 1 },
    {
        unique: true,
        name: 'dedupeKey_partial_unique',
        partialFilterExpression: { dedupeKey: { $type: 'string' } },
    },
);

export default mongoose.model('Notification', notificationSchema);

/**
 * AWS/prod: drop legacy unique index on null dedupeKey, clear nulls, ensure partial index.
 * Safe to call on every boot (idempotent).
 */
export async function ensureNotificationDedupeIndex() {
    const coll = mongoose.connection.collection('notifications');
    try {
        await coll.updateMany(
            { dedupeKey: null },
            { $unset: { dedupeKey: '' } },
        );
        const indexes = await coll.indexes();
        const legacy = indexes.find(
            (idx) => idx.name === 'dedupeKey_1' || (idx.key?.dedupeKey === 1 && !idx.partialFilterExpression),
        );
        if (legacy) {
            await coll.dropIndex(legacy.name);
            console.log(`[notifications] dropped legacy index ${legacy.name}`);
        }
        await mongoose.model('Notification').syncIndexes();
        console.log('[notifications] dedupeKey partial unique index ready');
    } catch (err) {
        console.warn('[notifications] ensureNotificationDedupeIndex:', err.message);
    }
}
