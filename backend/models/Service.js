import mongoose from 'mongoose';

const serviceSchema = new mongoose.Schema({
    title: { type: String, required: true, trim: true },
    category: { type: String, required: true, index: true },
    image: { type: String, required: true },
    basePrice: { type: Number, required: true },
    estimatedTime: { type: String, default: '1 Hour' },
    whatsIncluded: [{ type: String }],
    isActive: { type: Boolean, default: true }
}, { timestamps: true });

const Service = mongoose.model('Service', serviceSchema);

export default Service;