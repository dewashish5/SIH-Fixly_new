import mongoose from 'mongoose';

const welfareAccountSchema = new mongoose.Schema({
    worker: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, unique: true },
    balance: { type: Number, default: 0 },
    totalContributed: { type: Number, default: 0 },
    trainingEligible: { type: Boolean, default: false },
    insuranceActive: { type: Boolean, default: false },
    lastContribution: { type: Date, default: null },
}, { timestamps: true });

export default mongoose.model('WelfareAccount', welfareAccountSchema);
