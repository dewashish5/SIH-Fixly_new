import mongoose from 'mongoose';
const WelfareResourceSchema = new mongoose.Schema({
  title: { type: String, required: true },
  titleI18n: { hi: String, en: String },
  description: String,
  descriptionI18n: { hi: String, en: String },
  type: { type: String, enum: ['link', 'pdf', 'guide'], required: true },
  url: String,
  pdfUrl: String,
  category: { type: String, enum: ['insurance', 'eshram', 'uan', 'government_scheme', 'training', 'health_camp'], required: true },
  targetAudience: { type: String, enum: ['all', 'worker', 'customer'], default: 'worker' },
  priority: { type: Number, default: 0 },
  isActive: { type: Boolean, default: true },
  federation: { type: mongoose.Schema.Types.ObjectId, ref: 'Cooperative' },
}, { timestamps: true });
export default mongoose.model('WelfareResource', WelfareResourceSchema);
