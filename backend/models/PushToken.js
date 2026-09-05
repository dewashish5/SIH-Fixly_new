import mongoose from 'mongoose';

const pushTokenSchema = new mongoose.Schema({
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    token: { type: String, required: true, unique: true, trim: true },
    deviceId: { type: String, required: true, trim: true },
    platform: { type: String, enum: ['android', 'ios', 'web', 'unknown'], default: 'unknown' },
    appVersion: { type: String, default: null },
    locale: { type: String, default: 'en' },
    isActive: { type: Boolean, default: true },
    lastSeenAt: { type: Date, default: Date.now },
}, { timestamps: true });

pushTokenSchema.index({ user: 1, isActive: 1 });
pushTokenSchema.index({ user: 1, deviceId: 1 });

export default mongoose.model('PushToken', pushTokenSchema);