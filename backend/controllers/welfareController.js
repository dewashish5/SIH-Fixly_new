import WelfareAccount from '../models/WelfareAccount.js';
import WelfareTransaction from '../models/WelfareTransaction.js';
import InsurancePolicy from '../models/InsurancePolicy.js';
import { fail, ok } from '../utils/http.js';

const accountFor = async (workerId) => {
    let acc = await WelfareAccount.findOne({ worker: workerId });
    if (!acc) acc = await WelfareAccount.create({ worker: workerId });
    return acc;
};

const policyFor = async (workerId) => {
    let pol = await InsurancePolicy.findOne({ worker: workerId });
    if (!pol) pol = await InsurancePolicy.create({ worker: workerId });
    return pol;
};

export const getWelfare = async (req, res) => {
    try {
        if (req.user.role !== 'worker') return fail(res, 403, 'FORBIDDEN', 'Worker role required');
        const acc = await accountFor(req.user.id);
        const pol = await policyFor(req.user.id);
        return ok(res, {
            data: {
                balance: acc.balance,
                totalContributed: acc.totalContributed,
                trainingEligible: acc.trainingEligible,
                insuranceActive: pol.active,
                lastContribution: acc.lastContribution,
            },
        });
    } catch (error) {
        return fail(res, 500, 'INTERNAL_ERROR', error.message);
    }
};

export const getWelfareTransactions = async (req, res) => {
    try {
        if (req.user.role !== 'worker') return fail(res, 403, 'FORBIDDEN', 'Worker role required');
        const items = await WelfareTransaction.find({ worker: req.user.id }).sort({ createdAt: -1 });
        return ok(res, { data: items });
    } catch (error) {
        return fail(res, 500, 'INTERNAL_ERROR', error.message);
    }
};

export const getInsurance = async (req, res) => {
    try {
        if (req.user.role !== 'worker') return fail(res, 403, 'FORBIDDEN', 'Worker role required');
        const pol = await policyFor(req.user.id);
        return ok(res, { data: pol });
    } catch (error) {
        return fail(res, 500, 'INTERNAL_ERROR', error.message);
    }
};

export const getInsuranceClaims = async (req, res) => {
    try {
        if (req.user.role !== 'worker') return fail(res, 403, 'FORBIDDEN', 'Worker role required');
        const pol = await policyFor(req.user.id);
        return ok(res, { data: pol.claims || [] });
    } catch (error) {
        return fail(res, 500, 'INTERNAL_ERROR', error.message);
    }
};

export const createInsuranceClaim = async (req, res) => {
    try {
        if (req.user.role !== 'worker') return fail(res, 403, 'FORBIDDEN', 'Worker role required');
        const { subject, description, amount } = req.body || {};
        if (!subject || !description) return fail(res, 400, 'VALIDATION_ERROR', 'subject and description required');
        const pol = await policyFor(req.user.id);
        pol.claims.push({ subject, description, amount: Number(amount) || 0 });
        await pol.save();
        return ok(res, { data: pol.claims[pol.claims.length - 1] }, 201);
    } catch (error) {
        return fail(res, 500, 'INTERNAL_ERROR', error.message);
    }
};

export const adminWelfareSummary = async (_req, res) => {
    try {
        const accounts = await WelfareAccount.find();
        const totalBalance = accounts.reduce((s, a) => s + (a.balance || 0), 0);
        const totalContributed = accounts.reduce((s, a) => s + (a.totalContributed || 0), 0);
        return ok(res, { data: { members: accounts.length, totalBalance, totalContributed } });
    } catch (error) {
        return fail(res, 500, 'INTERNAL_ERROR', error.message);
    }
};

import WelfareResource from '../models/WelfareResource.js';
import User from '../models/User.js';

export const getWelfareResources = async (req, res) => {
    try {
        let federationId = null;
        let eshramUan = null;

        if (req.user?.id) {
            const worker = await User.findById(req.user.id);
            if (worker) {
                federationId = worker.federation || null;
                eshramUan = worker.workerProfile?.eshramUan;
            }
        }
        
        const filter = {
            isActive: true,
            targetAudience: { $in: ['all', 'worker'] }
        };

        if (federationId) {
            filter.$or = [
                { federation: null },
                { federation: federationId }
            ];
        } else {
            filter.federation = null;
        }

        const resources = await WelfareResource.find(filter).sort({ priority: -1, createdAt: -1 }).lean();
        
        // E-Shram / Insurance logic
        if (eshramUan) {
            resources.unshift({
                _id: 'auto-insurance-link',
                title: 'View Your Insurance Policy',
                type: 'link',
                url: '/worker/insurance',
                category: 'insurance',
                priority: 100
            });
        } else {
            resources.unshift({
                _id: 'auto-eshram-link',
                title: 'Register for e-Shram',
                description: 'Get your UAN to unlock government benefits.',
                type: 'link',
                url: 'https://eshram.gov.in',
                category: 'eshram',
                priority: 100
            });
        }
        
        return ok(res, { data: resources });
    } catch (error) {
        return fail(res, 500, 'INTERNAL_ERROR', error.message);
    }
};
