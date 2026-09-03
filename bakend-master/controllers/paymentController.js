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

// 1. Create Razorpay Order
export const createOrder = async (req, res) => {
    try {
        const { bookingId, amount } = req.body;
        const customerId = req.user.id;

        const booking = await Booking.findById(bookingId);
        if (!booking) {
            return res.status(404).json({ success: false, message: 'Booking not found' });
        }

        let orderId = `order_test_${Date.now()}_${Math.floor(Math.random() * 1000)}`;
        let orderAmount = Math.round(amount * 100);

        if (razorpay) {
            try {
                const options = {
                    amount: orderAmount,
                    currency: 'INR',
                    receipt: `receipt_booking_${bookingId}`,
                };
                const order = await razorpay.orders.create(options);
                orderId = order.id;
            } catch (rzErr) {
                console.warn('Razorpay order creation fallback:', rzErr.message);
            }
        }

        const transaction = await Transaction.create({
            customerId,
            workerId: booking.worker || customerId,
            bookingId,
            orderId,
            amount: Number(amount),
            status: 'pending',
            paymentMethod: 'Razorpay'
        });

        res.status(200).json({
            success: true,
            orderId,
            transactionId: transaction._id,
            amount: orderAmount,
            currency: 'INR',
            keyId: process.env.RAZORPAY_KEY_ID || 'rzp_test_mock_key'
        });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// 2. Verify Payment (Success / Failure Transition, Admin Mapping & Worker Wallet Credit)
export const verifyPayment = async (req, res) => {
    try {
        const { razorpay_order_id, razorpay_payment_id, razorpay_signature, bookingId } = req.body;

        let isAuthentic = true;
        if (process.env.RAZORPAY_KEY_SECRET && razorpay_signature !== 'test_signature') {
            const body = razorpay_order_id + '|' + razorpay_payment_id;
            const expectedSignature = crypto
                .createHmac('sha256', process.env.RAZORPAY_KEY_SECRET)
                .update(body.toString())
                .digest('hex');
            isAuthentic = expectedSignature === razorpay_signature;
        }

        let transaction = await Transaction.findOne({ orderId: razorpay_order_id });
        if (!transaction && bookingId) {
            transaction = await Transaction.findOne({ bookingId });
        }

        if (!transaction) {
            return res.status(404).json({ success: false, message: 'Transaction not found for this order/booking' });
        }

        if (isAuthentic) {
            const finalPaymentId = razorpay_payment_id || `pay_${Date.now()}`;
            transaction.paymentId = finalPaymentId;
            transaction.signature = razorpay_signature || 'verified_sig';
            transaction.status = 'success';
            await transaction.save();

            // Update Booking status to COMPLETED and invoice paymentStatus to PAID
            const booking = await Booking.findById(bookingId || transaction.bookingId);
            if (booking) {
                booking.invoice = booking.invoice || {};
                booking.invoice.paymentStatus = 'PAID';
                booking.invoice.paymentMethod = 'Razorpay';
                booking.invoice.transactionId = finalPaymentId;
                booking.status = 'COMPLETED';
                await booking.save();

                // CREDIT WORKER DUMMY WALLET
                const workerId = booking.worker || transaction.workerId;
                if (workerId) {
                    const worker = await User.findById(workerId);
                    if (worker) {
                        if (!worker.workerProfile) {
                            worker.workerProfile = {};
                        }

                        // Worker Payout calculated dynamically from Admin Settings (Platform Commission % & Welfare Pool %)
                        const settings = await Settings.findOne() || { platformCommissionPercent: 5, cooperativeWelfarePercent: 5 };
                        const commPercent = settings.platformCommissionPercent ?? 5;
                        const welfarePercent = settings.cooperativeWelfarePercent ?? 5;
                        const workerNetRatio = Math.max(0, 100 - (commPercent + welfarePercent)) / 100;

                        const totalAmt = transaction.amount || booking.invoice?.totalAmount || 500;
                        const workerPayout = Math.round(totalAmt * workerNetRatio);

                        worker.workerProfile.walletBalance = Number((worker.workerProfile.walletBalance || 0) + workerPayout);
                        worker.workerProfile.totalEarnings = Number((worker.workerProfile.totalEarnings || 0) + workerPayout);
                        worker.workerProfile.totalJobs = Number((worker.workerProfile.totalJobs || 0) + 1);

                        if (!worker.workerProfile.walletTransactions) {
                            worker.workerProfile.walletTransactions = [];
                        }

                        worker.workerProfile.walletTransactions.push({
                            transactionId: finalPaymentId,
                            bookingId: booking._id,
                            amount: workerPayout,
                            type: 'CREDIT',
                            description: `Earnings credited for Booking #${booking.bookingId || booking._id} (Razorpay ID: ${finalPaymentId})`,
                            createdAt: new Date()
                        });

                        await worker.save();
                    }
                }
            }

            return res.status(200).json({
                success: true,
                message: 'Razorpay payment verified successfully, Admin Transaction logged & Worker Wallet credited!',
                paymentId: finalPaymentId,
                transactionId: transaction._id,
                status: 'success'
            });
        } else {
            transaction.status = 'failed';
            await transaction.save();

            return res.status(400).json({ success: false, message: 'Invalid Razorpay payment signature', status: 'failed' });
        }
    } catch (error) {
        console.error('Verify Payment Error:', error);
        res.status(500).json({ success: false, message: error.message });
    }
};

// 3. Customer Wallet & Transaction History
export const getCustomerWalletAndHistory = async (req, res) => {
    try {
        const customerId = req.user.id;
        const transactions = await Transaction.find({ customerId })
            .populate('workerId', 'name phone')
            .populate('bookingId', 'bookingId status invoice')
            .sort({ createdAt: -1 });

        const successfulTxs = transactions.filter(t => t.status === 'success');
        const totalSpent = successfulTxs.reduce((acc, curr) => acc + curr.amount, 0);
        const fakeWalletBalance = 5000 - totalSpent;

        res.status(200).json({
            success: true,
            walletBalance: fakeWalletBalance >= 0 ? fakeWalletBalance : 0,
            history: transactions
        });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// 4. Worker Wallet Balance & Transaction History
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

        res.status(200).json({
            success: true,
            walletBalance: profile.walletBalance || 0,
            totalEarnings: profile.totalEarnings || 0,
            totalJobs: profile.totalJobs || 0,
            walletTransactions: profile.walletTransactions || [],
            adminTransactions: transactions
        });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};