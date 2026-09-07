import mongoose from 'mongoose';

const cooperativeSchema = new mongoose.Schema({
    name: { type: String, default: 'Fixly Cooperative Federation' },
    federationName: { type: String, default: 'National Labour Cooperative Federation' },
    registrationNumber: { type: String, default: 'FED-COOP-2026-001' },
    state: { type: String, default: null },
    district: { type: String, default: null },
    commissionRate: { type: Number, default: 0.05 }, // 5% Cooperative Platform operational fee
    welfareContributionRate: { type: Number, default: 0.05 }, // 5% dedicated to worker welfare fund
    insuranceEnabled: { type: Boolean, default: true },
    emergencySurchargePercent: { type: Number, default: 20 }, // +20% for emergency SOS jobs
    fairWagePolicy: { type: String, default: 'Cooperative Minimum Fair Wage Guarantee Policy v1.0' },
    minimumWageFloor: {
        plumbing: { type: Number, default: 350 },
        electrical: { type: Number, default: 400 },
        carpentry: { type: Number, default: 400 },
        cleaning: { type: Number, default: 250 },
        painting: { type: Number, default: 350 },
        appliance: { type: Number, default: 350 },
        gardening: { type: Number, default: 250 },
        default: { type: Number, default: 300 }
    },
    welfareReserveBalance: { type: Number, default: 0 },
    active: { type: Boolean, default: true },
}, { timestamps: true });

export default mongoose.model('Cooperative', cooperativeSchema);
