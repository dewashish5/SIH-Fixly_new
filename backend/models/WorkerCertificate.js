import mongoose from 'mongoose';

const workerCertificateSchema = new mongoose.Schema({
    worker: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    serviceCategory: { type: String, default: null },
    certificateType: { type: String, required: true },
    certificateNumber: { type: String, default: null },
    fileUrl: { type: String, required: true },
    issuer: { type: String, default: null },
    issuedOn: { type: Date, default: null },
    expiresOn: { type: Date, default: null },
    status: {
        type: String,
        enum: ['pending', 'submitted', 'approved', 'rejected'],
        default: 'submitted',
    },
    reviewNote: { type: String, default: null },
}, { timestamps: true });

export default mongoose.model('WorkerCertificate', workerCertificateSchema);
