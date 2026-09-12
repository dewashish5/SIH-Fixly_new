import express from 'express';
import { analyzeIssue, serviceDiscovery, matchWorkers } from '../controllers/aiController.js';
import { getDemandForecast } from '../controllers/demandForecastController.js';
import { protect } from '../middleware/authMiddleware.js';
import upload from '../middleware/uploadMiddleware.js'; // Added Multer

const router = express.Router();

// AI analyze text + image (max 1 photo)
router.post('/analyze-issue', protect, upload.single('issueImage'), analyzeIssue);
router.post('/service-discovery', protect, serviceDiscovery);
router.post('/match-workers', protect, matchWorkers);
router.get('/demand-forecast', protect, getDemandForecast);

export default router;

// import express from 'express';
// import { analyzeIssue } from '../controllers/aiController.js';
// import { protect } from '../middleware/authMiddleware.js';

// const router = express.Router();

// router.post('/analyze-issue', protect, analyzeIssue);

// export default router;