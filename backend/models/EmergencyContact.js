import mongoose from 'mongoose';

const EmergencyContactSchema = new mongoose.Schema({
  name: { type: String, required: true },
  nameI18n: { hi: String, en: String },
  phoneNumber: { type: String, required: true },
  category: { 
    type: String, 
    enum: ['police', 'fire', 'ambulance', 'women_helpline', 'child_helpline', 
           'disaster', 'federation_support', 'fixly_support', 'other'],
    required: true 
  },
  icon: { type: String },
  priority: { type: Number, default: 0 },
  isActive: { type: Boolean, default: true },
  federation: { type: mongoose.Schema.Types.ObjectId, ref: 'Cooperative' },
}, { timestamps: true });

const EmergencyContact = mongoose.model('EmergencyContact', EmergencyContactSchema);
export default EmergencyContact;
