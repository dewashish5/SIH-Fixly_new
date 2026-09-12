import mongoose from 'mongoose';
const WelfareResourceSchema = new mongoose.Schema({
  title: { type: String, required: true },
  titleI18n: { hi: String, en: String },
  description: String,
  descriptionI18n: { hi: String, en: String },
  type: { type: String, enum: ['link', 'pdf', 'guide'], required: true },
  url: String,
  pdfUrl: String,
  fileName: String,
  fileSize: String,
  category: { 
    type: String, 
    enum: ['eshram', 'insurance', 'uan', 'government_scheme', 'training', 'health_camp', 'health', 'pension', 'general', 'Health', 'Education', 'Finance', 'Legal'], 
    default: 'eshram' 
  },
  targetAudience: { type: String, enum: ['all', 'worker', 'customer'], default: 'worker' },
  priority: { type: Number, default: 0 },
  isActive: { type: Boolean, default: true },
  federation: { type: mongoose.Schema.Types.ObjectId, ref: 'Cooperative' },
}, { timestamps: true });

WelfareResourceSchema.pre('save', function () {
  if (this.type === 'pdf' && this.pdfUrl && !this.url) {
    this.url = this.pdfUrl;
  } else if (this.type === 'pdf' && this.url && !this.pdfUrl) {
    this.pdfUrl = this.url;
  }
});

export default mongoose.model('WelfareResource', WelfareResourceSchema);
