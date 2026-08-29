import express from 'express';
import {
    getHomeData,
    getCategories,
    getServiceDetails,
    getExtraPartsCatalog
} from '../controllers/homeController.js';
import { protect } from '../middleware/authMiddleware.js';

const router = express.Router();

router.get('/home', protect, getHomeData);
router.get('/categories', getCategories);
router.get('/services/:serviceId', getServiceDetails);
router.get('/extra-parts', protect, getExtraPartsCatalog); // Screen 5: Add extra services/parts

export default router;