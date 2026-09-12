import express from 'express';
import { submitReview } from '../controllers/reviewController.js';
import { protect } from '../middleware/authMiddleware.js';
import upload from '../middleware/uploadMiddleware.js'; // Added Multer

const router = express.Router();

// Upload up to 3 photos for review
router.post('/:bookingId', protect, upload.array('workPhotos', 3), submitReview);

export default router;


// import express from 'express';
// import { submitReview } from '../controllers/reviewController.js';
// import { protect } from '../middleware/authMiddleware.js';

// const router = express.Router();

// router.post('/:bookingId', protect, submitReview);

// export default router;