import WorkerCertificate from '../models/WorkerCertificate.js';
import User from '../models/User.js';
import { fail, ok, isObjectId } from '../utils/http.js';

export const createCertificate = async (req, res) => {
    try {
        if (req.user.role !== 'worker') return fail(res, 403, 'FORBIDDEN', 'Worker role required');
        const { serviceCategory, certificateType, certificateNumber, fileUrl, issuer, issuedOn, expiresOn } = req.body || {};
        if (!certificateType || !fileUrl) {
            return fail(res, 400, 'VALIDATION_ERROR', 'certificateType and fileUrl required');
        }
        const cert = await WorkerCertificate.create({
            worker: req.user.id,
            serviceCategory: serviceCategory || null,
            certificateType,
            certificateNumber: certificateNumber || null,
            fileUrl,
            issuer: issuer || null,
            issuedOn: issuedOn || null,
            expiresOn: expiresOn || null,
            status: 'submitted',
        });
        return ok(res, { data: cert }, 201);
    } catch (error) {
        return fail(res, 500, 'INTERNAL_ERROR', error.message);
    }
};

export const listMyCertificates = async (req, res) => {
    try {
        const items = await WorkerCertificate.find({ worker: req.user.id }).sort({ createdAt: -1 });
        return ok(res, { data: items });
    } catch (error) {
        return fail(res, 500, 'INTERNAL_ERROR', error.message);
    }
};

export const getCertificate = async (req, res) => {
    try {
        const item = await WorkerCertificate.findOne({ _id: req.params.id, worker: req.user.id });
        if (!item) return fail(res, 404, 'NOT_FOUND', 'Certificate not found');
        return ok(res, { data: item });
    } catch (error) {
        return fail(res, 500, 'INTERNAL_ERROR', error.message);
    }
};

export const deleteCertificate = async (req, res) => {
    try {
        const item = await WorkerCertificate.findOneAndDelete({ _id: req.params.id, worker: req.user.id });
        if (!item) return fail(res, 404, 'NOT_FOUND', 'Certificate not found');
        return ok(res, { data: { deleted: true } });
    } catch (error) {
        return fail(res, 500, 'INTERNAL_ERROR', error.message);
    }
};

export const adminListCertificates = async (req, res) => {
    try {
        if (!isObjectId(req.params.workerId)) return fail(res, 400, 'VALIDATION_ERROR', 'Invalid worker id');
        const items = await WorkerCertificate.find({ worker: req.params.workerId }).sort({ createdAt: -1 });
        return ok(res, { data: items });
    } catch (error) {
        return fail(res, 500, 'INTERNAL_ERROR', error.message);
    }
};

export const adminReviewCertificate = async (req, res) => {
    try {
        const { status, reviewNote } = req.body || {};
        const allowed = ['pending', 'submitted', 'approved', 'rejected'];
        if (!allowed.includes(status)) return fail(res, 400, 'VALIDATION_ERROR', 'Invalid status');
        const item = await WorkerCertificate.findOne({
            _id: req.params.certificateId,
            worker: req.params.workerId,
        });
        if (!item) return fail(res, 404, 'NOT_FOUND', 'Certificate not found');
        item.status = status;
        item.reviewNote = reviewNote || null;
        await item.save();
        return ok(res, { data: item });
    } catch (error) {
        return fail(res, 500, 'INTERNAL_ERROR', error.message);
    }
};

export const adminGetWorkerVerification = async (req, res) => {
    try {
        const worker = await User.findById(req.params.id).select('name role isVerified kycDocuments');
        if (!worker || worker.role !== 'worker') return fail(res, 404, 'NOT_FOUND', 'Worker not found');
        return ok(res, { data: { worker, kycDocuments: worker.kycDocuments } });
    } catch (error) {
        return fail(res, 500, 'INTERNAL_ERROR', error.message);
    }
};

export const adminReviewWorkerVerification = async (req, res) => {
    try {
        const { status, declineReason } = req.body || {};
        const allowed = ['pending', 'submitted', 'approved', 'rejected'];
        if (!allowed.includes(status)) return fail(res, 400, 'VALIDATION_ERROR', 'Invalid status');
        const worker = await User.findById(req.params.id);
        if (!worker || worker.role !== 'worker') return fail(res, 404, 'NOT_FOUND', 'Worker not found');
        worker.kycDocuments = worker.kycDocuments || {};
        worker.kycDocuments.status = status === 'pending' ? 'none' : status;
        worker.kycDocuments.declineReason = status === 'rejected' ? (declineReason || 'Rejected') : null;
        worker.isVerified = status === 'approved';
        await worker.save();
        return ok(res, { data: { status: worker.kycDocuments.status, isVerified: worker.isVerified } });
    } catch (error) {
        return fail(res, 500, 'INTERNAL_ERROR', error.message);
    }
};
