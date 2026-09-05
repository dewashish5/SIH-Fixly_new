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
    unread: { type: Boolean, default: true },
    isRead: { type: Boolean, default: false },
    data: { type: mongoose.Schema.Types.Mixed, default: {} },
}, { timestamps: true });

notificationSchema.index({ recipient: 1, createdAt: -1 });

export default mongoose.model('Notification', notificationSchema);
