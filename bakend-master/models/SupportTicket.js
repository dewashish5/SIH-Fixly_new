import mongoose from 'mongoose';

const messageSchema = new mongoose.Schema({
    sender: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    role: { type: String, enum: ['customer', 'worker', 'admin'], required: true },
    body: { type: String, required: true },
    attachments: [{ type: String }],
}, { timestamps: true });

const supportTicketSchema = new mongoose.Schema({
    ticketNumber: { type: String, unique: true, required: true },
    createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    booking: { type: mongoose.Schema.Types.ObjectId, ref: 'Booking', default: null },
    category: {
        type: String,
        enum: ['SERVICE_DISPUTE', 'WORKER_CUSTOMER_ISSUE', 'PAYMENT', 'SAFETY', 'BOOKING', 'ACCOUNT', 'OTHER'],
        default: 'OTHER',
    },
    priority: { type: String, enum: ['LOW', 'NORMAL', 'HIGH', 'URGENT'], default: 'NORMAL' },
    status: {
        type: String,
        enum: ['OPEN', 'IN_REVIEW', 'WAITING_FOR_USER', 'RESOLVED', 'CLOSED'],
        default: 'OPEN',
        index: true,
    },
    subject: { type: String, required: true },
    description: { type: String, required: true },
    attachments: [{ type: String }],
    assignedTo: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },
    messages: { type: [messageSchema], default: [] },
    lastMessageAt: { type: Date, default: Date.now },
    resolvedAt: { type: Date, default: null },
}, { timestamps: true });

supportTicketSchema.pre('validate', function () {
    if (!this.ticketNumber) {
        this.ticketNumber = `TKT-${Date.now().toString(36).toUpperCase()}`;
    }
});

export default mongoose.model('SupportTicket', supportTicketSchema);
