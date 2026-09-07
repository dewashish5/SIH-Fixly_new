import mongoose from 'mongoose';

const verificationAuditLogSchema = new mongoose.Schema({
    workerId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    action: { type: String, required: true }, // e.g., 'SUBMITTED', 'AI_EVALUATED', 'MANUAL_APPROVED', 'MANUAL_REJECTED'
    actorType: { type: String, enum: ['WORKER', 'AI', 'ADMIN'], required: true },
    actorId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null }, // Null if actorType is 'AI'
    oldStatus: { type: String, required: true },
    newStatus: { type: String, required: true },
    reason: { type: String, default: null },
    metadata: { type: mongoose.Schema.Types.Mixed, default: {} },
}, { timestamps: true });

const VerificationAuditLog = mongoose.model('VerificationAuditLog', verificationAuditLogSchema);
export default VerificationAuditLog;
