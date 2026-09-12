import mongoose from 'mongoose';

const cooperativeSocietySchema = new mongoose.Schema({
    name: {
        type: String,
        required: [true, 'Society name is required'],
        trim: true,
    },
    registrationNumber: {
        type: String,
        required: [true, 'Society registration number is required'],
        unique: true,
        trim: true,
    },
    federation: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Cooperative',
        default: null,
    },
    state: {
        type: String,
        required: true,
        trim: true,
    },
    district: {
        type: String,
        required: true,
        trim: true,
    },
    wardOrArea: {
        type: String,
        default: null,
        trim: true,
    },
    officeAddress: {
        type: String,
        default: null,
    },
    contactPhone: {
        type: String,
        default: null,
    },
    presidentName: {
        type: String,
        default: null,
    },
    secretaryName: {
        type: String,
        default: null,
    },
    activeMembersCount: {
        type: Number,
        default: 0,
    },
    fairWageComplianceScore: {
        type: Number,
        default: 100, // 0-100%
    },
    active: {
        type: Boolean,
        default: true,
    },
}, { timestamps: true });

cooperativeSocietySchema.index({ district: 1, state: 1 });

export default mongoose.model('CooperativeSociety', cooperativeSocietySchema);
