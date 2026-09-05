import Razorpay from 'razorpay';
import crypto from 'crypto';
import Transaction from '../models/Transaction.js';
import Booking from '../models/Booking.js';
import User from '../models/User.js';
import Settings from '../models/Settings.js';

let razorpay = null;
if (process.env.RAZORPAY_KEY_ID && process.env.RAZORPAY_KEY_SECRET) {
    razorpay = new Razorpay({
        key_id: process.env.RAZORPAY_KEY_ID,
        key_secret: process.env.RAZORPAY_KEY_SECRET,
    });
}

const razorpayMode = () =>
    process.env.RAZORPAY_KEY_ID?.startsWith('rzp_live') ? 'live' : 'test';

const finalizeJobAfterPayment = async (booking, io) => {
    booking.status = 'COMPLETED';
    booking.jobCompletedAt = booking.jobCompletedAt || new Date();
    await booking.save();

    if (booking.worker) {
        const updatePayload = {};
        if (booking.serviceAddress?.location?.coordinates?.length === 2) {
            updatePayload.location = {
                type: 'Point',
                coordinates: booking.serviceAddress.location.coordinates,
            };
        }
        if (Object.keys(updatePayload).length) {
            await User.findByIdAndUpdate(booking.worker, { $set: updatePayload });
        }
    }

    if (io) {
        io.to(`booking_${booking._id}`).emit('booking_status_update', {
            bookingId: booking._id,
            status: 'COMPLETED',
            paymentStatus: 'PAID',
            transactionId: booking.invoice?.transactionId,
            invoice: booking.invoice,
        });
        if (booking.worker) {
            io.emit('worker:availability_changed', {
                workerId: String(booking.worker),
                isAvailable: true,
                status: 'AVAILABLE',
            });
        }
    }
};

const creditWorkerWallet = async ({
    workerId,
    booking,
    transaction,
    paymentId,
}) => {
    if (!workerId) return 0;
    const worker = await User.findById(workerId);
    if (!worker) return 0;
    if (!worker.workerProfile) worker.workerProfile = {};
    if (!worker.workerProfile.walletTransactions) {
        worker.workerProfile.walletTransactions = [];
    }

    const alreadyCredited = worker.workerProfile.walletTransactions.some(
        (tx) => tx.transactionId === paymentId
    );
    if (alreadyCredited) {
        return worker.workerProfile.walletBalance || 0;
    }

    const settings =
        (await Settings.findOne()) || {
            platformCommissionPercent: 5,
            cooperativeWelfarePercent: 5,
        };
    const commPercent = settings.platformCommissionPercent ?? 5;
    const welfarePercent = settings.cooperativeWelfarePercent ?? 5;
    const workerNetRatio = Math.max(0, 100 - (commPercent + welfarePercent)) / 100;
    const totalAmt =
        transaction.amount || booking.invoice?.totalAmount || 0;
    const workerPayout = Math.round(totalAmt * workerNetRatio);

    worker.workerProfile.walletBalance = Number(
        (worker.workerProfile.walletBalance || 0) + workerPayout
    );
    worker.workerProfile.totalEarnings = Number(
        (worker.workerProfile.totalEarnings || 0) + workerPayout
    );
    worker.workerProfile.totalJobs = Number(
        (worker.workerProfile.totalJobs || 0) + 1
    );
    worker.workerProfile.walletTransactions.push({
        transactionId: paymentId,
        bookingId: booking._id,
        amount: workerPayout,
        type: 'CREDIT',
        description: `Earnings credited for Booking ${booking.bookingId || booking._id} (Razorpay ID: ${paymentId})`,
        createdAt: new Date(),
    });
    await worker.save();
    return workerPayout;
};

export const getPaymentConfig = (_req, res) => {
    const keyId = process.env.RAZORPAY_KEY_ID;
    if (!keyId) {
        return res.status(503).json({
            success: false,
            message: 'Razorpay is not configured',
        });
    }
    return res.status(200).json({
        success: true,
        keyId,
        currency: 'INR',
        mode: razorpayMode(),
    });
};

export const createOrder = async (req, res) => {
    try {
        if (!razorpay || !process.env.RAZORPAY_KEY_ID) {
            return res.status(503).json({
                success: false,
                message: 'Razorpay is not configured',
            });
        }

        const { bookingId, amount } = req.body;
        const customerId = req.user.id;
        const booking = await Booking.findById(bookingId);
        if (!booking) {
            return res.status(404).json({ success: false, message: 'Booking not found' });
        }
        if (String(booking.customer) !== String(customerId) && req.user.role !== 'admin') {
            return res.status(403).json({ success: false, message: 'Not your booking' });
        }
        if (booking.invoice?.paymentStatus === 'PAID') {
            return res.status(400).json({ success: false, message: 'Booking already paid' });
        }
        if (!['IN_PROGRESS', 'COMPLETED'].includes(booking.status)) {
            return res.status(400).json({
                success: false,
                message: 'Payment is available after the job is in progress',
            });
        }

        const orderAmount = Math.round(Number(amount) * 100);
        if (!Number.isFinite(orderAmount) || orderAmount < 100) {
            return res.status(400).json({ success: false, message: 'Invalid payment amount' });
        }

        const existing = await Transaction.findOne({
            bookingId,
            status: 'pending',
        }).sort({ createdAt: -1 });

        let orderId = existing?.orderId;
        if (!orderId || String(orderId).startsWith('order_test_')) {
            const order = await razorpay.orders.create({
                amount: orderAmount,
                currency: 'INR',
                receipt: `receipt_booking_${bookingId}`.slice(0, 40),
            });
            orderId = order.id;
        }

        const description = `Fixly payment for ${booking.bookingId || bookingId}`;
        const transaction = existing
            ? await Transaction.findByIdAndUpdate(
                existing._id,
                {
                    orderId,
                    amount: Number(amount),
                    description,
                    workerId: booking.worker || existing.workerId,
                    paymentMethod: 'Razorpay',
                    status: 'pending',
                },
                { new: true }
            )
            : await Transaction.create({
                customerId,
                workerId: booking.worker || customerId,
                bookingId,
                orderId,
                amount: Number(amount),
                status: 'pending',
                paymentMethod: 'Razorpay',
                description,
            });

        return res.status(200).json({
            success: true,
            orderId,
            transactionId: transaction._id,
            amount: orderAmount,
            currency: 'INR',
            keyId: process.env.RAZORPAY_KEY_ID,
            mode: razorpayMode(),
        });
    } catch (error) {
        console.error('Create order error:', error);
        return res.status(500).json({ success: false, message: error.message });
    }
};

export const verifyPayment = async (req, res) => {
    try {
        const {
            razorpay_order_id,
            razorpay_payment_id,
            razorpay_signature,
            bookingId,
        } = req.body;

        if (!process.env.RAZORPAY_KEY_SECRET) {
            return res.status(503).json({
                success: false,
                message: 'Razorpay is not configured',
            });
        }

        const body = `${razorpay_order_id}|${razorpay_payment_id}`;
        const expectedSignature = crypto
            .createHmac('sha256', process.env.RAZORPAY_KEY_SECRET)
            .update(body)
            .digest('hex');
        const isAuthentic = expectedSignature === razorpay_signature;

        let transaction = await Transaction.findOne({ orderId: razorpay_order_id });
        if (!transaction && bookingId) {
            transaction = await Transaction.findOne({ bookingId }).sort({ createdAt: -1 });
        }
        if (!transaction) {
            return res.status(404).json({
                success: false,
                message: 'Transaction not found for this order/booking',
            });
        }

        if (!isAuthentic) {
            transaction.status = 'failed';
            await transaction.save();
            if (bookingId || transaction.bookingId) {
                await Booking.findByIdAndUpdate(bookingId || transaction.bookingId, {
                    'invoice.paymentStatus': 'FAILED',
                });
            }
            return res.status(400).json({
                success: false,
                message: 'Invalid Razorpay payment signature',
                status: 'failed',
            });
        }

        const finalPaymentId = razorpay_payment_id;
        if (transaction.status === 'success' && transaction.paymentId) {
            return res.status(200).json({
                success: true,
                message: 'Payment already verified',
                paymentId: transaction.paymentId,
                transactionId: transaction._id,
                status: 'success',
            });
        }

        transaction.paymentId = finalPaymentId;
        transaction.signature = razorpay_signature;
        transaction.status = 'success';
        transaction.description =
            transaction.description || `Razorpay ${finalPaymentId}`;
        await transaction.save();

        const booking = await Booking.findById(bookingId || transaction.bookingId);
        if (booking) {
            booking.invoice = booking.invoice || {};
            booking.invoice.paymentStatus = 'PAID';
            booking.invoice.paymentMethod = 'Razorpay';
            booking.invoice.transactionId = finalPaymentId;

            await creditWorkerWallet({
                workerId: booking.worker || transaction.workerId,
                booking,
                transaction,
                paymentId: finalPaymentId,
            });

            await finalizeJobAfterPayment(booking, req.app.get('io'));
        }

        return res.status(200).json({
            success: true,
            message: 'Payment verified, job completed, worker wallet credited',
            paymentId: finalPaymentId,
            transactionId: transaction._id,
            status: 'success',
        });
    } catch (error) {
        console.error('Verify Payment Error:', error);
        return res.status(500).json({ success: false, message: error.message });
    }
};

export const getCustomerWalletAndHistory = async (req, res) => {
    try {
        const customerId = req.user.id;
        const transactions = await Transaction.find({ customerId })
            .populate('workerId', 'name phone')
            .populate('bookingId', 'bookingId status invoice')
            .sort({ createdAt: -1 });

        const successfulTxs = transactions.filter((t) => t.status === 'success');
        const totalSpent = successfulTxs.reduce((acc, curr) => acc + curr.amount, 0);
        const history = transactions.map((t) => {
            const json = t.toObject();
            return {
                ...json,
                transactionId: json.paymentId || json.orderId || String(json._id),
                description:
                    json.description ||
                    `Razorpay payment${json.paymentId ? ` • ${json.paymentId}` : ''}`,
                type: 'DEBIT',
            };
        });

        return res.status(200).json({
            success: true,
            walletBalance: 0,
            totalSpent,
            history,
        });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

export const getWorkerWalletAndHistory = async (req, res) => {
    try {
        const workerId = req.user.id;
        const worker = await User.findById(workerId);
        if (!worker) {
            return res.status(404).json({ success: false, message: 'Worker not found' });
        }

        const transactions = await Transaction.find({ workerId, status: 'success' })
            .populate('customerId', 'name phone email')
            .populate('bookingId', 'bookingId status invoice')
            .sort({ createdAt: -1 });

        const profile = worker.workerProfile || {};
        const walletTransactions = (profile.walletTransactions || [])
            .slice()
            .reverse()
            .map((t) => ({
                _id: t._id,
                transactionId: t.transactionId,
                description: t.description,
                type: t.type || 'CREDIT',
                amount: t.amount,
                bookingId: t.bookingId,
                createdAt: t.createdAt,
            }));

        return res.status(200).json({
            success: true,
            walletBalance: profile.walletBalance || 0,
            totalEarnings: profile.totalEarnings || 0,
            totalJobs: profile.totalJobs || 0,
            walletTransactions,
            transactions: walletTransactions,
            history: walletTransactions,
            adminTransactions: transactions,
        });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};
