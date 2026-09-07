import mongoose from 'mongoose';

const cooperativeSocietySchema = new mongoose.Schema({
    name: { type: String, required: true, trim: true },
    registrationNumber: { type: String, required: true, unique: true, uppercase: true, trim: true },
    state: { type: String, required: true, trim: true },
    district: { type: String, required: true, trim: true },
    wardOrArea: { type: String, trim: true, default: '' },
    officeAddress: { type: String, trim: true, default: '' },
    contactPhone: { type: String, trim: true, default: '' },
    presidentName: { type: String, trim: true, default: '' },
    secretaryName: { type: String, trim: true, default: '' },
    fairWageComplianceScore: { type: Number, default: 100 },
    activeMembersCount: { type: Number, default: 0 },
    federation: { type: mongoose.Schema.Types.ObjectId, ref: 'Cooperative' },
    active: { type: Boolean, default: true, index: true }
}, { timestamps: true });

export default mongoose.model('CooperativeSociety', cooperativeSocietySchema);
