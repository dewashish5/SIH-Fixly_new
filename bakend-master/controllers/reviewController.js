import Review from '../models/Review.js';
import User from '../models/User.js';
import Booking from '../models/Booking.js';

// Screen: Rating & Review Submission
export const submitReview = async (req, res) => {
    // #swagger.tags = ['Reviews']
    // #swagger.parameters['body'] = { in: 'body', description: 'Submit Review Input', required: true, schema: { $ref: '#/definitions/SubmitReviewInput' } }
    try {
        const { bookingId, workerId, rating, comment, traits } = req.body;

        const review = await Review.create({
            booking: bookingId,
            customer: req.user.id,
            worker: workerId,
            rating,
            feedback: comment,
            badgesGiven: traits // e.g., ['Professional', 'On Time']
        });

        // MongoDB Aggregation to dynamically update worker's average rating
        const stats = await Review.aggregate([
            { $match: { worker: workerId } },
            { $group: { _id: '$worker', avgRating: { $avg: '$rating' }, totalJobs: { $sum: 1 } } }
        ]);

        if (stats.length > 0) {
            await User.findByIdAndUpdate(workerId, {
                'workerProfile.rating': stats[0].avgRating.toFixed(1),
                'workerProfile.totalJobs': stats[0].totalJobs
            });
        }

        // Mark booking as reviewed
        await Booking.findByIdAndUpdate(bookingId, { isReviewed: true });

        return res.status(201).json({ success: true, message: 'Review submitted successfully', review });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};