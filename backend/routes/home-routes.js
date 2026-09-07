import express from 'express';
import {
    getHomeData,
    getCategories,
    getServiceDetails,
    getExtraPartsCatalog,
    createCategory
} from '../controllers/homeController.js';
import { getBanners } from '../controllers/bannerController.js';
import { protect } from '../middleware/authMiddleware.js';
import upload from '../middleware/uploadMiddleware.js';

const router = express.Router();

router.get('/home', protect, getHomeData);
router.get('/banners', getBanners);
router.get('/categories', getCategories);
router.post('/categories', upload.single('image'), createCategory);
router.get('/services/:serviceId', getServiceDetails);
router.get('/extra-parts', protect, getExtraPartsCatalog); // Screen 5: Add extra services/parts

export default router;