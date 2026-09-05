import express from 'express';
import { protect, authorize } from '../middleware/authMiddleware.js';
import {
    createCertificate,
    listMyCertificates,
    getCertificate,
    deleteCertificate,
} from '../controllers/workerCertificateController.js';

const router = express.Router();
router.use(protect, authorize('worker'));
router.post('/', createCertificate);
router.get('/', listMyCertificates);
router.get('/:id', getCertificate);
router.delete('/:id', deleteCertificate);
export default router;
