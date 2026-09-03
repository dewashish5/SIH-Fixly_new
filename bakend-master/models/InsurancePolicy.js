import mongoose from 'mongoose';

const claimSchema = new mongoose.Schema({
    subject: { type: String, required: true },
    description: { type: String, required: true },
    status: { type: String, enum: ['OPEN', 'IN_REVIEW', 'APPROVED', 'REJECTED'], default: 'OPEN' },
    amount: { type: Number, default: 0 },
}, { timestamps: true });

const insurancePolicySchema = new mongoose.Schema({
    worker: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, unique: true },
    provider: { type: String, default: 'Fixly Welfare Cover' },
    active: { type: Boolean, default: false },
    coverageAmount: { type: Number, default: 0 },
    startsOn: { type: Date, default: null },
    endsOn: { type: Date, default: null },
    claims: { type: [claimSchema], default: [] },
}, { timestamps: true });

export default mongoose.model('InsurancePolicy', insurancePolicySchema);
