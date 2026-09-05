import express from 'express';
import {
    getExtraPartsCatalog,
    getCategories,
    getServiceDetails,
    searchServices,
    createService
} from '../controllers/serviceController.js';
import { protect } from '../middleware/authMiddleware.js';
import upload from '../middleware/uploadMiddleware.js';

const router = express.Router();

router.get('/search', searchServices); // Global search bar API
router.get('/categories', getCategories); // GET only for categories
router.get('/extra-parts', protect, getExtraPartsCatalog);
router.get('/:serviceId', getServiceDetails);
router.post('/', upload.single('image'), createService); // POST /api/services

export default router;