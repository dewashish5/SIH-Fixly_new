import express from 'express';
import { analyzeIssue } from '../controllers/aiController.js';
import { protect } from '../middleware/authMiddleware.js';
import upload from '../middleware/uploadMiddleware.js'; // Added Multer

const router = express.Router();

// AI analyze text + image (max 1 photo)
router.post('/analyze-issue', protect, upload.single('issueImage'), analyzeIssue);

export default router;

// import express from 'express';
// import { analyzeIssue } from '../controllers/aiController.js';
// import { protect } from '../middleware/authMiddleware.js';

// const router = express.Router();

// router.post('/analyze-issue', protect, analyzeIssue);

// export default router;