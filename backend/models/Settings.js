import mongoose from 'mongoose';

const settingsSchema = new mongoose.Schema({
    customerPlatformFee: { type: Number, default: 0 },
    workerCommissionPercent: { type: Number, default: 5 },
    platformCommissionPercent: { type: Number, default: 5 }, // legacy alias
    cooperativeWelfarePercent: { type: Number, default: 5 },
    workerSearchRadiusKm: { type: Number, default: 15 },
    defaultLaborRatePerHour: { type: Number, default: 350 },
    autoDispatchEnabled: { type: Boolean, default: true },
    emergencyHotline: { type: String, default: '+91 98765 43210' },
    workerDeclineTemplates: [{ type: String }],
    emailNotifications: { type: Boolean, default: true },
    smsAlerts: { type: Boolean, default: true },
    payoutSchedule: { type: String, default: 'Instant Automated UPI' },
    twoFactorAuth: { type: Boolean, default: false }
}, { timestamps: true });

export default mongoose.model('Settings', settingsSchema);
