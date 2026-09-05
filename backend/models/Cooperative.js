import mongoose from 'mongoose';

const cooperativeSchema = new mongoose.Schema({
    name: { type: String, default: 'Fixly Cooperative' },
    federationName: { type: String, default: null },
    state: { type: String, default: null },
    district: { type: String, default: null },
    commissionRate: { type: Number, default: 0.1 },
    welfareContributionRate: { type: Number, default: 0.02 },
    insuranceEnabled: { type: Boolean, default: true },
    fairWagePolicy: { type: String, default: null },
    active: { type: Boolean, default: true },
}, { timestamps: true });

export default mongoose.model('Cooperative', cooperativeSchema);
