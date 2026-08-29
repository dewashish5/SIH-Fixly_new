import Razorpay from 'razorpay';
import crypto from 'crypto';
import Transaction from '../models/Transaction.js';
import Booking from '../models/Booking.js';

const razorpay = new Razorpay({
    key_id: process.env.RAZORPAY_KEY_ID,
    key_secret: process.env.RAZORPAY_KEY_SECRET,
});

// 1. Create Razorpay Order
export const createOrder = async (req, res) => {
    try {
        const { bookingId, amount } = req.body;
        const customerId = req.user._id;

        const booking = await Booking.findById(bookingId);
        if (!booking) {
            return res.status(404).json({ success: false, message: 'Booking not found' });
        }

        const options = {
            amount: Math.round(amount * 100), // Amount in paise
            currency: 'INR',
            receipt: `receipt_booking_${bookingId}`,
        };

        const order = await razorpay.orders.create(options);

        await Transaction.create({
            customerId,
            workerId: booking.workerId,
            bookingId,
            orderId: order.id,
            amount,
            status: 'pending'
        });

        res.status(200).json({
            success: true,
            orderId: order.id,
            amount: order.amount,
            currency: order.currency,
            keyId: process.env.RAZORPAY_KEY_ID
        });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// 2. Verify Payment (Success / Failure Transition & Worker Mapping)
export const verifyPayment = async (req, res) => {
    try {
        const { razorpay_order_id, razorpay_payment_id, razorpay_signature, bookingId } = req.body;

        const body = razorpay_order_id + '|' + razorpay_payment_id;
        const expectedSignature = crypto
            .createHmac('sha256', process.env.RAZORPAY_KEY_SECRET)
            .update(body.toString())
            .digest('hex');

        const isAuthentic = expectedSignature === razorpay_signature;

        const transaction = await Transaction.findOne({ orderId: razorpay_order_id });
        if (!transaction) {
            return res.status(404).json({ success: false, message: 'Transaction not found' });
        }

        if (isAuthentic) {
            transaction.paymentId = razorpay_payment_id;
            transaction.status = 'success';
            await transaction.save();

            await Booking.findByIdAndUpdate(bookingId, { paymentStatus: 'Paid', status: 'Completed' });

            return res.status(200).json({
                success: true,
                message: 'Payment verified successfully and mapped to assigned worker',
                paymentId: razorpay_payment_id,
                status: 'success'
            });
        } else {
            transaction.status = 'failed';
            await transaction.save();

            return res.status(400).json({ success: false, message: 'Invalid payment signature', status: 'failed' });
        }
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

// 3. Fake Wallet & Transaction History for Customer
export const getCustomerWalletAndHistory = async (req, res) => {
    try {
        const customerId = req.user._id;
        const transactions = await Transaction.find({ customerId })
            .populate('workerId', 'name phone')
            .sort({ createdAt: -1 });

        const successfulTxs = transactions.filter(t => t.status === 'success');
        const totalSpent = successfulTxs.reduce((acc, curr) => acc + curr.amount, 0);
        const fakeWalletBalance = 5000 - totalSpent; // Mock initial balance of 5000

        res.status(200).json({
            success: true,
            walletBalance: fakeWalletBalance >= 0 ? fakeWalletBalance : 0,
            history: transactions
        });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};