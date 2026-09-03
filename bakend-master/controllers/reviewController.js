import Review from '../models/Review.js';
import User from '../models/User.js';
import Booking from '../models/Booking.js';
import { uploadMulterFiles } from '../utils/cloudinary.js';

// Screen: Rating & Review Submission
export const submitReview = async (req, res) => {
    try {
        const { bookingId: bodyBookingId, workerId, rating, comment, traits } = req.body;
        const bookingId = req.params.bookingId || bodyBookingId;

        let badgesGiven = traits;
        if (typeof traits === 'string') {
            badgesGiven = traits.split(',').map((t) => t.trim()).filter(Boolean);
        }

        let photos = [];
        if (req.files?.length) {
            photos = await uploadMulterFiles(req.files, 'gigconnect/reviews');
        }

        const review = await Review.create({
            booking: bookingId,
            customer: req.user.id,
            worker: workerId,
            rating,
            feedback: comment,
            badgesGiven: badgesGiven || [],
            photos,
        });

        // MongoDB Aggregation to dynamically update worker's average rating
        const stats = await Review.aggregate([
            { $match: { worker: review.worker } },
            { $group: { _id: '$worker', avgRating: { $avg: '$rating' }, totalJobs: { $sum: 1 } } }
        ]);

        if (stats.length > 0) {
            await User.findByIdAndUpdate(workerId, {
                'workerProfile.rating': stats[0].avgRating.toFixed(1),
                'workerProfile.totalJobs': stats[0].totalJobs
            });
        }

        await Booking.findByIdAndUpdate(bookingId, { isReviewed: true });

        return res.status(201).json({ success: true, message: 'Review submitted successfully', review });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

export const getWorkerReviews = async (req, res) => {
    try {
        const page = Math.max(1, Number(req.query.page) || 1);
        const limit = Math.min(50, Math.max(1, Number(req.query.limit) || 10));
        const workerId = req.params.workerId;
        const [reviews, total, all] = await Promise.all([
            Review.find({ worker: workerId })
                .populate('customer', 'name avatar')
                .sort({ createdAt: -1 })
                .skip((page - 1) * limit)
                .limit(limit),
            Review.countDocuments({ worker: workerId }),
            Review.find({ worker: workerId }).select('rating'),
        ]);
        const avg = all.length ? all.reduce((s, r) => s + r.rating, 0) / all.length : 0;
        return res.status(200).json({
            success: true,
            data: reviews,
            reviews,
            summary: { count: total, average: Number(avg.toFixed(1)) },
            page,
            limit,
            total,
        });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

export const getBookingReview = async (req, res) => {
    try {
        const review = await Review.findOne({ booking: req.params.bookingId })
            .populate('customer', 'name avatar')
            .populate('worker', 'name');
        if (!review) return res.status(404).json({ success: false, code: 'NOT_FOUND', message: 'Review not found' });
        return res.status(200).json({ success: true, data: review, review });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};
