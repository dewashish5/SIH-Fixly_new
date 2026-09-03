import express from 'express';
import { protect } from '../middleware/authMiddleware.js';
import upload from '../middleware/uploadMiddleware.js';
import { uploadSingle, uploadMany } from '../controllers/uploadController.js';

const router = express.Router();

router.post('/', protect, upload.single('file'), uploadSingle);
router.post('/many', protect, upload.array('files', 10), uploadMany);

export default router;
