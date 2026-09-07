import mongoose from 'mongoose';

const cooperativeSchema = new mongoose.Schema({
    name: { type: String, default: 'Fixly Cooperative Federation' },
    federationName: { type: String, default: 'National Labour Cooperative Federation of India' },
    registrationNumber: { type: String, default: 'FED-COOP-2026-001' },
    state: { type: String, default: null },
    district: { type: String, default: null },
    commissionRate: { type: Number, default: 0.05 },
    welfareContributionRate: { type: Number, default: 0.05 },
    insuranceEnabled: { type: Boolean, default: true },
    fairWagePolicy: { type: String, default: 'Cooperative Minimum Fair Wage Guarantee Policy v1.0' },
    minimumWageFloor: {
        type: Map,
        of: Number,
        default: () => ({
            electrical: 450,
            plumbing: 400,
            carpentry: 400,
            cleaning: 300,
            painting: 400,
            appliance: 450,
            gardening: 300,
            default: 350
        })
    },
    emergencySurchargePercent: { type: Number, default: 20 },
    emergencySurchargeFixed: { type: Number, default: 50 },
    welfareBalance: { type: Number, default: 0 },
    active: { type: Boolean, default: true },
}, { timestamps: true });

export default mongoose.model('Cooperative', cooperativeSchema);
