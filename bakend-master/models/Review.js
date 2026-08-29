import mongoose from 'mongoose';

const reviewSchema = new mongoose.Schema({
    booking: { type: mongoose.Schema.Types.ObjectId, ref: 'Booking', required: true, unique: true },
    customer: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    worker: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    rating: { type: Number, required: true, min: 1, max: 5 },
    feedback: { type: String, trim: true, default: null },
    badgesGiven: [{ type: String }], // e.g., 'On Time', 'Clean Workspace'
    photos: [{ type: String }]
}, { timestamps: true });

const Review = mongoose.model('Review', reviewSchema);

export default Review;
