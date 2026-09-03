import mongoose from 'mongoose';

const payoutRequestSchema = new mongoose.Schema({
    worker: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    amount: { type: Number, required: true, min: 1 },
    status: {
        type: String,
        enum: ['requested', 'processing', 'paid', 'rejected'],
        default: 'requested',
        index: true,
    },
    note: { type: String, default: null },
    paidAt: { type: Date, default: null },
}, { timestamps: true });

export default mongoose.model('PayoutRequest', payoutRequestSchema);
