import mongoose from 'mongoose';

const notificationSchema = new mongoose.Schema({
    title: { type: String, required: true },
    message: { type: String, required: true },
    body: { type: String, default: null },
    category: {
        type: String,
        enum: [
            'BOOKING', 'PAYMENT', 'VERIFICATION', 'SUPPORT', 'SAFETY', 'SYSTEM', 'PROMOTION',
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
    dedupeKey: { type: String, default: null, unique: true, sparse: true },
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

export default mongoose.model('Notification', notificationSchema);
