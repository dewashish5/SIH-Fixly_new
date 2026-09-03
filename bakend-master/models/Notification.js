import mongoose from 'mongoose';

const notificationSchema = new mongoose.Schema({
    title: { type: String, required: true },
    message: { type: String, required: true },
    category: { type: String, enum: ['Emergency', 'Payments', 'System', 'Surge', 'General'], default: 'System' },
    targetAudience: { type: String, enum: ['All Users', 'Workers Only', 'Customers Only', 'Specific Email', 'Workers', 'Customers', 'Emergency Staff'], default: 'All Users' },
    recipientEmail: { type: String, default: null }, // Personal/Custom target email
    sendEmail: { type: Boolean, default: false },
    priority: { type: String, enum: ['High', 'Medium', 'Normal', 'Urgent', 'Emergency', 'Low'], default: 'Normal' },
    unread: { type: Boolean, default: true }
}, { timestamps: true });

export default mongoose.model('Notification', notificationSchema);
