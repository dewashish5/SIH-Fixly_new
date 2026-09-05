import Cooperative from '../models/Cooperative.js';
import User from '../models/User.js';
import { fail, ok } from '../utils/http.js';

const getOrCreate = async () => {
    let doc = await Cooperative.findOne({ active: true });
    if (!doc) doc = await Cooperative.create({});
    return doc;
};

export const getCooperativeInfo = async (_req, res) => {
    try {
        const info = await getOrCreate();
        return ok(res, { data: info });
    } catch (error) {
        return fail(res, 500, 'INTERNAL_ERROR', error.message);
    }
};

export const getMyMembership = async (req, res) => {
    try {
        if (req.user.role !== 'worker') return fail(res, 403, 'FORBIDDEN', 'Worker role required');
        const info = await getOrCreate();
        const worker = await User.findById(req.user.id).select('name isVerified createdAt');
        return ok(res, {
            data: {
                member: Boolean(worker),
                verified: Boolean(worker?.isVerified),
                joinedAt: worker?.createdAt,
                cooperative: info,
            },
        });
    } catch (error) {
        return fail(res, 500, 'INTERNAL_ERROR', error.message);
    }
};

export const adminGetCooperative = async (_req, res) => {
    try {
        return ok(res, { data: await getOrCreate() });
    } catch (error) {
        return fail(res, 500, 'INTERNAL_ERROR', error.message);
    }
};

export const adminUpdateCooperative = async (req, res) => {
    try {
        const info = await getOrCreate();
        const fields = [
            'name', 'federationName', 'state', 'district', 'commissionRate',
            'welfareContributionRate', 'insuranceEnabled', 'fairWagePolicy', 'active',
        ];
        for (const key of fields) {
            if (req.body[key] !== undefined) info[key] = req.body[key];
        }
        await info.save();
        return ok(res, { data: info });
    } catch (error) {
        return fail(res, 500, 'INTERNAL_ERROR', error.message);
    }
};

export const adminCooperativeMembers = async (_req, res) => {
    try {
        const workers = await User.find({ role: 'worker' }).select('name email isVerified createdAt');
        return ok(res, { data: workers });
    } catch (error) {
        return fail(res, 500, 'INTERNAL_ERROR', error.message);
    }
};
