import Review from '../models/Review.js';
import User from '../models/User.js';
import Booking from '../models/Booking.js';
import { uploadMulterFiles } from '../utils/cloudinary.js';

// Screen: Rating & Review Submission (supports customer→worker and worker→customer)
export const submitReview = async (req, res) => {
    try {
        const { bookingId: bodyBookingId, workerId, rating, comment, traits, reviewerRole: bodyRole } = req.body;
        const bookingId = req.params.bookingId || bodyBookingId;

        // Determine reviewer role from body or from user's role
        const reviewerRole = bodyRole === 'worker' ? 'worker' : 'customer';

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
            reviewerRole,
            rating,
            feedback: comment,
            badgesGiven: badgesGiven || [],
            photos,
        });

        // Update worker's aggregate rating only when customer submits review
        if (reviewerRole === 'customer') {
            const stats = await Review.aggregate([
                { $match: { worker: review.worker, reviewerRole: 'customer' } },
                { $group: { _id: '$worker', avgRating: { $avg: '$rating' }, totalJobs: { $sum: 1 } } }
            ]);

            if (stats.length > 0) {
                await User.findByIdAndUpdate(workerId, {
                    'workerProfile.rating': stats[0].avgRating.toFixed(1),
                    'workerProfile.totalJobs': stats[0].totalJobs
                });
            }
        }

        await Booking.findByIdAndUpdate(bookingId, { isReviewed: true });

        return res.status(201).json({ success: true, message: 'Review submitted successfully', review });
    } catch (error) {
        // Handle duplicate review gracefully
        if (error.code === 11000) {
            return res.status(409).json({ success: false, message: 'Review already submitted for this booking' });
        }
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
