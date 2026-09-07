import Transaction from '../models/Transaction.js';
import Booking from '../models/Booking.js';
import User from '../models/User.js';
import PayoutRequest from '../models/PayoutRequest.js';
import { fail, ok } from '../utils/http.js';
import { notifyUser, safeNotify } from '../services/notificationService.js';

const MIN_WITHDRAW = 100;

const startOfDay = (d) => {
    const x = new Date(d);
    x.setHours(0, 0, 0, 0);
    return x;
};

const summarize = async (workerId, from, to) => {
    const txQuery = { workerId, status: 'success' };
    if (from || to) {
        txQuery.createdAt = {};
        if (from) txQuery.createdAt.$gte = new Date(from);
        if (to) txQuery.createdAt.$lte = new Date(to);
    }
    const txs = await Transaction.find(txQuery);
    const totalEarned = txs.reduce((s, t) => s + (t.amount || 0), 0);
    const now = new Date();
    const weekAgo = new Date(now);
    weekAgo.setDate(weekAgo.getDate() - 7);
    const monthStart = new Date(now.getFullYear(), now.getMonth(), 1);
    const thisWeek = txs.filter((t) => t.createdAt >= weekAgo).reduce((s, t) => s + t.amount, 0);
    const thisMonth = txs.filter((t) => t.createdAt >= monthStart).reduce((s, t) => s + t.amount, 0);
    const today = txs.filter((t) => t.createdAt >= startOfDay(now)).reduce((s, t) => s + t.amount, 0);

    const pendingPayouts = await PayoutRequest.find({ worker: workerId, status: { $in: ['requested', 'processing'] } });
    const pendingBalance = pendingPayouts.reduce((s, p) => s + p.amount, 0);
    const lastPayout = await PayoutRequest.findOne({ worker: workerId, status: 'paid' }).sort({ paidAt: -1 });

    const worker = await User.findById(workerId).select('workerProfile');
    const profile = worker?.workerProfile || {};
    const stored = profile.walletBalance || 0;
    const availableBalance = Math.max(0, stored - pendingBalance);
    const walletTxs = (profile.walletTransactions || [])
        .slice()
        .sort((a, b) => new Date(b.createdAt || 0) - new Date(a.createdAt || 0))
        .map((t) => ({
            _id: t._id,
            transactionId: t.transactionId,
            description: t.description,
            type: t.type || 'CREDIT',
            amount: t.amount,
            grossAmount: t.grossAmount || t.amount,
            platformFeeDeducted: t.platformFeeDeducted || 0,
            welfareDeducted: t.welfareDeducted || 0,
            bookingId: t.bookingId,
            createdAt: t.createdAt,
        }));
    const history = walletTxs.length
        ? walletTxs
        : txs.map((t) => ({
            _id: t._id,
            transactionId: t.paymentId || t.orderId,
            description: t.description || `Razorpay ${t.paymentId || t.orderId || ''}`.trim(),
            type: 'CREDIT',
            amount: t.amount,
            bookingId: t.bookingId,
            createdAt: t.createdAt,
        }));
    const profileEarnings = profile.totalEarnings || 0;

    return {
        availableBalance,
        pendingBalance,
        totalEarned: profileEarnings || totalEarned,
        totalEarnings: profileEarnings || totalEarned,
        today,
        thisWeek,
        thisMonth,
        platformFee: 0,
        welfareContribution: 0,
        insuranceContribution: 0,
        lastPayout: lastPayout || null,
        transactions: history,
        walletTransactions: history,
    };
};

export const getWallet = async (req, res) => {
    try {
        if (req.user.role !== 'worker') return fail(res, 403, 'FORBIDDEN', 'Worker role required');
        const summary = await summarize(req.user.id);
        return ok(res, { data: summary, walletBalance: summary.availableBalance });
    } catch (error) {
        return fail(res, 500, 'INTERNAL_ERROR', error.message);
    }
};

export const getEarnings = async (req, res) => {
    try {
        if (req.user.role !== 'worker') return fail(res, 403, 'FORBIDDEN', 'Worker role required');
        const summary = await summarize(req.user.id, req.query.from, req.query.to);
        return ok(res, { data: summary });
    } catch (error) {
        return fail(res, 500, 'INTERNAL_ERROR', error.message);
    }
};

export const getEarningsSummary = async (req, res) => {
    try {
        if (req.user.role !== 'worker') return fail(res, 403, 'FORBIDDEN', 'Worker role required');
        const summary = await summarize(req.user.id);
        const completedJobs = await Booking.countDocuments({ worker: req.user.id, status: 'COMPLETED' });
        return ok(res, {
            data: {
                today: summary.today,
                thisWeek: summary.thisWeek,
                thisMonth: summary.thisMonth,
                totalEarned: summary.totalEarned,
                completedJobs,
            },
        });
    } catch (error) {
        return fail(res, 500, 'INTERNAL_ERROR', error.message);
    }
};

export const getTransactions = async (req, res) => {
    try {
        if (req.user.role !== 'worker') return fail(res, 403, 'FORBIDDEN', 'Worker role required');
        const txs = await Transaction.find({ workerId: req.user.id })
            .populate('bookingId', 'bookingId status invoice')
            .populate('customerId', 'name')
            .sort({ createdAt: -1 });
        return ok(res, { data: txs });
    } catch (error) {
        return fail(res, 500, 'INTERNAL_ERROR', error.message);
    }
};

export const listPayouts = async (req, res) => {
    try {
        if (req.user.role !== 'worker') return fail(res, 403, 'FORBIDDEN', 'Worker role required');
        const items = await PayoutRequest.find({ worker: req.user.id }).sort({ createdAt: -1 });
        return ok(res, { data: items });
    } catch (error) {
        return fail(res, 500, 'INTERNAL_ERROR', error.message);
    }
};

export const requestWithdraw = async (req, res) => {
    try {
        if (req.user.role !== 'worker') return fail(res, 403, 'FORBIDDEN', 'Worker role required');
        const amount = Number(req.body.amount);
        if (!Number.isFinite(amount) || amount < MIN_WITHDRAW) {
            return fail(res, 400, 'VALIDATION_ERROR', `Minimum withdrawal is ${MIN_WITHDRAW}`);
        }
        const worker = await User.findById(req.user.id);
        const hasPayout = worker?.workerProfile?.upi?.upiId || worker?.workerProfile?.bank?.accountNumber;
        if (!hasPayout) {
            return fail(res, 400, 'VALIDATION_ERROR', 'Add a payout account before withdrawing');
        }
        const summary = await summarize(req.user.id);
        if (amount > summary.availableBalance) {
            return fail(res, 400, 'VALIDATION_ERROR', 'Insufficient available balance');
        }
        const payout = await PayoutRequest.create({
            worker: req.user.id,
            amount,
            status: 'requested',
        });
        safeNotify(() => notifyUser({
            recipient: req.user.id,
            eventType: 'PAYOUT_REQUESTED',
            entityId: payout._id,
            dedupeKey: `PAYOUT_REQUESTED:${payout._id}`,
        }));
        return ok(res, { data: payout }, 201);
    } catch (error) {
        return fail(res, 500, 'INTERNAL_ERROR', error.message);
    }
};

export const adminListPayouts = async (_req, res) => {
    try {
        const items = await PayoutRequest.find().populate('worker', 'name email').sort({ createdAt: -1 });
        return ok(res, { data: items });
    } catch (error) {
        return fail(res, 500, 'INTERNAL_ERROR', error.message);
    }
};

const PAYOUT_TRANSITIONS = {
    requested: ['processing', 'paid', 'rejected'],
    processing: ['paid', 'rejected'],
};

const PAYOUT_EVENTS = {
    processing: 'PAYOUT_PROCESSING',
    paid: 'PAYOUT_PAID',
    rejected: 'PAYOUT_REJECTED',
};

export const adminUpdatePayoutStatus = async (req, res) => {
    try {
        const { status, note } = req.body || {};
        const payout = await PayoutRequest.findById(req.params.id);
        if (!payout) return fail(res, 404, 'NOT_FOUND', 'Payout not found');
        const allowed = PAYOUT_TRANSITIONS[payout.status] || [];
        if (!allowed.includes(status)) {
            return fail(res, 400, 'VALIDATION_ERROR', `Cannot change payout from ${payout.status} to ${status}`);
        }
        payout.status = status;
        if (note) payout.note = note;

        if (status === 'paid') {
            payout.paidAt = new Date();
            const worker = await User.findById(payout.worker);
            if (worker && worker.workerProfile) {
                worker.workerProfile.walletBalance = Math.max(0, (worker.workerProfile.walletBalance || 0) - payout.amount);
                worker.workerProfile.walletTransactions = worker.workerProfile.walletTransactions || [];
                worker.workerProfile.walletTransactions.push({
                    transactionId: `PAYOUT-${payout._id}`,
                    amount: payout.amount,
                    type: 'DEBIT',
                    description: `Payout withdrawal settled to bank/UPI (${payout.note || 'Admin settlement approved'})`,
                    createdAt: new Date(),
                });
                await worker.save();
            }
        }

        await payout.save();
        safeNotify(() => notifyUser({
            recipient: payout.worker,
            eventType: PAYOUT_EVENTS[status],
            entityId: payout._id,
            dedupeKey: `${PAYOUT_EVENTS[status]}:${payout._id}`,
        }));
        return ok(res, { data: payout, message: `Payout status updated to ${status} and worker wallet updated.` });
    } catch (error) {
        return fail(res, 500, 'INTERNAL_ERROR', error.message);
    }
};
