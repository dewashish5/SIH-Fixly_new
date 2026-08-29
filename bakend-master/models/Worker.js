import mongoose from 'mongoose';

const workerSchema = new mongoose.Schema({
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    title: { type: String, required: true }, // e.g. "Master Electrician"
    hourlyRate: { type: Number, required: true },
    rating: { type: Number, default: 5.0 },
    reviewsCount: { type: Number, default: 0 },
    jobsCompleted: { type: Number, default: 0 },
    verified: { type: Boolean, default: false },
    about: { type: String },
    skills: [{ type: String }],
    recentWorkImages: [{ type: String }],
    location: {
        type: { type: String, enum: ['Point'], default: 'Point' },
        coordinates: { type: [Number], required: true } // [longitude, latitude]
    }
}, { timestamps: true });

workerSchema.index({ location: '2dsphere' }); // GeoJSON Nearby query performance ke liye

const Worker = mongoose.model('Worker', workerSchema);

export default Worker