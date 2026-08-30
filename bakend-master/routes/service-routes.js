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
router.get('/categories', getCategories);
router.get('/extra-parts', protect, getExtraPartsCatalog);
router.get('/:serviceId', getServiceDetails);
router.post('/', upload.single('image'), createService);

export default router;


// import express from 'express';
// import {
//     getExtraPartsCatalog,
//     getCategories,
//     getServiceDetails
// } from '../controllers/serviceController.js';
// import { protect } from '../middleware/authMiddleware.js';

// const router = express.Router();

// router.get('/categories', getCategories);
// router.get('/extra-parts', protect, getExtraPartsCatalog);
// router.get('/:serviceId', getServiceDetails);

// export default router;