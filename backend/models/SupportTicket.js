import mongoose from 'mongoose';

const messageSchema = new mongoose.Schema({
    sender: { type: mongoose.Schema.Types.Mixed, default: null },
    senderName: { type: String, default: null },
    role: { type: String, enum: ['customer', 'worker', 'admin', 'ai', 'system'], required: true },
    body: { type: String, required: true },
    attachments: [{ type: String }],
    mediaType: { type: String, enum: ['image', 'video', 'audio', null], default: null },
    quickReplies: [{ type: String }],
}, { timestamps: true });

const supportTicketSchema = new mongoose.Schema({
    ticketNumber: { type: String, unique: true, required: true },
    createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    userRole: { type: String, enum: ['customer', 'worker'], default: 'customer' },
    booking: { type: mongoose.Schema.Types.ObjectId, ref: 'Booking', default: null },
    category: {
        type: String,
        enum: ['SERVICE_DISPUTE', 'WORKER_CUSTOMER_ISSUE', 'PAYMENT', 'SAFETY', 'BOOKING', 'ACCOUNT', 'OTHER'],
        default: 'OTHER',
    },
    priority: { type: String, enum: ['LOW', 'NORMAL', 'HIGH', 'URGENT'], default: 'NORMAL' },
    handledBy: { type: String, enum: ['BOT', 'HUMAN'], default: 'BOT', index: true },
    status: {
        type: String,
        enum: ['BOT_ACTIVE', 'ESCALATED', 'AGENT_ACTIVE', 'WAITING_FOR_USER', 'OPEN', 'IN_REVIEW', 'RESOLVED', 'CLOSED'],
        default: 'BOT_ACTIVE',
        index: true,
    },
    subject: { type: String, default: 'Fixly Help & Support' },
    description: { type: String, default: 'Support chat initiated' },
    attachments: [{ type: String }],
    assignedTo: { type: mongoose.Schema.Types.Mixed, default: null },
    messages: { type: [messageSchema], default: [] },
    quickReplies: [{ type: String }],
    lastMessageAt: { type: Date, default: Date.now },
    resolvedAt: { type: Date, default: null },
}, { timestamps: true });

supportTicketSchema.pre('validate', function () {
    if (!this.ticketNumber) {
        this.ticketNumber = `TKT-${Date.now().toString(36).toUpperCase()}`;
    }
});

export default mongoose.model('SupportTicket', supportTicketSchema);
