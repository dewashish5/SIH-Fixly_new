import mongoose from 'mongoose';

const welfareTransactionSchema = new mongoose.Schema({
    worker: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    amount: { type: Number, required: true },
    type: { type: String, enum: ['contribution', 'benefit', 'payout'], required: true },
    note: { type: String, default: null },
    booking: { type: mongoose.Schema.Types.ObjectId, ref: 'Booking', default: null },
}, { timestamps: true });

export default mongoose.model('WelfareTransaction', welfareTransactionSchema);
