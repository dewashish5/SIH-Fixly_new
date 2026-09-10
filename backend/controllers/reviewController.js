import Review from '../models/Review.js';
import User from '../models/User.js';
import Booking from '../models/Booking.js';
import { uploadMulterFiles } from '../utils/cloudinary.js';

// Screen: Rating & Review Submission (supports customer→worker and worker→customer)
export const submitReview = async (req, res) => {
    try {
        const { bookingId: bodyBookingId, workerId: rawWorkerId, rating, comment, description, traits, reviewerRole: bodyRole } = req.body;
        const bookingId = req.params.bookingId || bodyBookingId;

        // Fetch booking to reliably determine worker & customer ObjectIds
        const booking = await Booking.findById(bookingId);
        if (!booking) {
            return res.status(404).json({ success: false, message: 'Booking not found' });
        }

        const isWorker = req.user.role === 'worker' || bodyRole === 'worker' || (booking.worker && String(booking.worker) === String(req.user.id));
        const reviewerRole = isWorker ? 'worker' : 'customer';

        let customerId;
        let workerId;

        if (isWorker) {
            workerId = booking.worker || req.user.id;
            customerId = booking.customer || req.body.customerId;
        } else {
            customerId = booking.customer || req.user.id;
            workerId = (rawWorkerId && String(rawWorkerId).trim() !== '') ? rawWorkerId : (booking.worker || req.body.workerId);
        }

        if (!customerId) {
            return res.status(400).json({ success: false, message: 'Customer ID could not be identified for this booking' });
        }
        if (!workerId) {
            return res.status(400).json({ success: false, message: 'Worker ID could not be identified for this booking' });
        }

        let badgesGiven = traits;
        if (typeof traits === 'string') {
            badgesGiven = traits.split(',').map((t) => t.trim()).filter(Boolean);
        }

        let photos = [];
        if (Array.isArray(req.body.photos)) {
            photos = req.body.photos;
        } else if (Array.isArray(req.body.images)) {
            photos = req.body.images;
        } else if (typeof req.body.photo === 'string' && req.body.photo) {
            photos = [req.body.photo];
        }

        if (req.files?.length) {
            const uploaded = await uploadMulterFiles(req.files, 'gigconnect/reviews');
            photos = [...photos, ...uploaded];
        }

        const feedback = comment || description || req.body.feedback || '';

        const review = await Review.create({
            booking: booking._id,
            customer: customerId,
            worker: workerId,
            reviewerRole,
            rating: Number(rating) || 5,
            feedback,
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

        await Booking.findByIdAndUpdate(booking._id, { isReviewed: true });

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
        const defaultLimit = parseInt(process.env.REVIEWS_PAGE_LIMIT, 10) || 5;
        const page = Math.max(1, Number(req.query.page) || 1);
        const limit = Math.min(50, Math.max(1, Number(req.query.limit) || defaultLimit));
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
