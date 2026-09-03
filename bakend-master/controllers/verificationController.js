import User from '../models/User.js';
import { authorize } from '../middleware/authMiddleware.js';
import { fail, ok, maskId } from '../utils/http.js';

export const requireRole = authorize;

const workerOnly = (req, res) => {
    if (req.user?.role !== 'worker') {
        fail(res, 403, 'FORBIDDEN', 'Worker role required');
        return false;
    }
    return true;
};

const mapStatus = (kyc = {}) => {
    const raw = (kyc.status || 'none').toLowerCase();
    if (raw === 'none') return 'pending';
    return raw;
};

export const submitVerification = async (req, res) => {
    try {
        if (!workerOnly(req, res)) return;
        const {
            governmentIdType,
            governmentIdNumber,
            governmentIdFrontUrl,
            governmentIdBackUrl,
            selfieImageUrl,
            additionalDocuments = [],
        } = req.body || {};

        if (!governmentIdType || !governmentIdNumber || !governmentIdFrontUrl || !selfieImageUrl) {
            return fail(res, 400, 'VALIDATION_ERROR', 'Required verification fields missing');
        }

        const user = await User.findById(req.user.id);
        if (!user) return fail(res, 404, 'NOT_FOUND', 'User not found');

        user.kycDocuments = {
            ...(user.kycDocuments?.toObject?.() || user.kycDocuments || {}),
            govermentIdType: governmentIdType,
            govermentIdNumber: governmentIdNumber,
            aadhaarFrontPhoto: governmentIdFrontUrl,
            aadhaarBackPhoto: governmentIdBackUrl || null,
            selfieImageUrl,
            status: 'submitted',
            declineReason: null,
        };

        const pan = Array.isArray(additionalDocuments)
            ? additionalDocuments.find((d) => String(d.type || '').toLowerCase().includes('pan'))
            : null;
        if (pan) {
            user.kycDocuments.panNumber = pan.number || user.kycDocuments.panNumber;
            user.kycDocuments.panFrontPhoto = pan.frontUrl || user.kycDocuments.panFrontPhoto;
            user.kycDocuments.panBackPhoto = pan.backUrl || user.kycDocuments.panBackPhoto;
        }

        await user.save();
        return ok(res, {
            verification: {
                status: 'submitted',
                submittedAt: new Date().toISOString(),
            },
        });
    } catch (error) {
        return fail(res, 500, 'INTERNAL_ERROR', error.message);
    }
};

export const getMyVerification = async (req, res) => {
    try {
        if (!workerOnly(req, res)) return;
        const user = await User.findById(req.user.id).select('kycDocuments isVerified workerProfile');
        if (!user) return fail(res, 404, 'NOT_FOUND', 'User not found');
        const kyc = user.kycDocuments || {};
        const status = user.isVerified ? 'approved' : mapStatus(kyc);
        const hasSelfie = Boolean(kyc.selfieImageUrl);
        const hasId = Boolean(kyc.aadhaarFrontPhoto || kyc.govermentIdNumber);
        return ok(res, {
            verification: {
                status,
                identity: hasId ? (status === 'approved' ? 'approved' : 'submitted') : 'pending',
                selfie: hasSelfie ? (status === 'approved' ? 'approved' : 'submitted') : 'pending',
                certificates: 'pending',
                declineReason: kyc.declineReason || null,
                lastUpdatedAt: user.updatedAt,
                governmentIdType: kyc.govermentIdType || null,
                governmentIdNumber: maskId(kyc.govermentIdNumber || kyc.aadhaarNumber),
            },
        });
    } catch (error) {
        return fail(res, 500, 'INTERNAL_ERROR', error.message);
    }
};

export const resubmitVerification = async (req, res) => {
    try {
        if (!workerOnly(req, res)) return;
        const user = await User.findById(req.user.id);
        if (!user) return fail(res, 404, 'NOT_FOUND', 'User not found');
        const status = mapStatus(user.kycDocuments);
        if (status !== 'rejected') {
            return fail(res, 400, 'VALIDATION_ERROR', 'Resubmit allowed only after rejection');
        }
        req.body = req.body || {};
        return submitVerification(req, res);
    } catch (error) {
        return fail(res, 500, 'INTERNAL_ERROR', error.message);
    }
};
