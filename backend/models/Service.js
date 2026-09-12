import mongoose from 'mongoose';

const serviceSchema = new mongoose.Schema({
    title: { type: String, required: true, trim: true },
    titleI18n: {
        hi: { type: String, default: null },
        en: { type: String, default: null }
    },
    category: { type: String, required: true, index: true },
    categoryI18n: {
        hi: { type: String, default: null },
        en: { type: String, default: null }
    },
    description: { type: String, default: null },
    descriptionI18n: {
        hi: { type: String, default: null },
        en: { type: String, default: null }
    },
    image: { type: String, required: true },
    basePrice: { type: Number, required: true },
    estimatedTime: { type: String, default: '1 Hour' },
    whatsIncluded: [{ type: String }],
    whatsIncludedI18n: {
        hi: [{ type: String }],
        en: [{ type: String }]
    },
    isActive: { type: Boolean, default: true }
}, { timestamps: true });

const Service = mongoose.model('Service', serviceSchema);

export default Service;