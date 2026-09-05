import mongoose from 'mongoose';

const settingsSchema = new mongoose.Schema({
    platformCommissionPercent: { type: Number, default: 5 },
    cooperativeWelfarePercent: { type: Number, default: 5 },
    autoDispatchEnabled: { type: Boolean, default: true },
    emergencyHotline: { type: String, default: '+91 98765 43210' },
    emailNotifications: { type: Boolean, default: true },
    smsAlerts: { type: Boolean, default: true },
    payoutSchedule: { type: String, default: 'Instant Automated UPI' },
    twoFactorAuth: { type: Boolean, default: false }
}, { timestamps: true });

export default mongoose.model('Settings', settingsSchema);
