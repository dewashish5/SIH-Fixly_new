import mongoose from 'mongoose';

const bannerSchema = new mongoose.Schema({
    title: { type: String, required: true, trim: true },
    code: { type: String, required: true, uppercase: true, trim: true },
    discount: { type: String, required: true, trim: true },
    discountPercent: { type: Number, default: 0 },
    discountAmount: { type: Number, default: 0 },
    description: { type: String, trim: true, default: '' },
    imageUrl: { type: String, default: '' },
    gradient: [{ type: String }],
    category: { type: String, default: 'all', index: true },
    targetUserRole: { type: String, enum: ['all', 'customer', 'new_user', 'vip'], default: 'all' },
    minOrderValue: { type: Number, default: 0 },
    maxDiscount: { type: Number, default: 500 },
    validUntil: { type: Date },
    isActive: { type: Boolean, default: true, index: true },
    priority: { type: Number, default: 0 }
}, { timestamps: true });

const Banner = mongoose.model('Banner', bannerSchema);

export default Banner;
