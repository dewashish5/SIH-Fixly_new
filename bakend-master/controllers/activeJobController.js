import Booking from '../models/Booking.js';

// Screen: Verify Worker Arrival (OTP)
export const verifyArrivalOtp = async (req, res) => {
    try {
        const { bookingId } = req.params;
        const { otp } = req.body;

        const booking = await Booking.findById(bookingId);
        if (!booking) return res.status(404).json({ success: false, message: 'Booking not found' });

        // Dummy check for testing (In production, compare with booking.arrivalOtp)
        if (otp !== '8492' && otp !== booking.arrivalOtp) {
            return res.status(400).json({ success: false, message: 'Invalid Secure PIN' });
        }

        booking.status = 'ARRIVED';
        await booking.save();

        return res.status(200).json({ success: true, message: 'Worker arrival verified', booking });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

// Screen: Add Extra Parts/Services
export const addExtraParts = async (req, res) => {
    try {
        const { bookingId } = req.params;
        const { extraItems } = req.body; // Array: [{ name: 'U-bend Pipe', price: 25 }]

        const booking = await Booking.findById(bookingId);
        if (!booking) return res.status(404).json({ success: false, message: 'Booking not found' });

        const totalAdditions = extraItems.reduce((sum, item) => sum + item.price, 0);

        booking.invoice.extraParts = [...(booking.invoice.extraParts || []), ...extraItems];
        booking.invoice.totalAmount += totalAdditions;

        await booking.save();

        return res.status(200).json({ success: true, invoice: booking.invoice });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

// Screen: Job Completed & Payment Generation
export const completeJob = async (req, res) => {
    try {
        const { bookingId } = req.params;

        const booking = await Booking.findById(bookingId);
        booking.status = 'COMPLETED';
        booking.completedAt = Date.now();

        // Final calculation logic
        booking.invoice.finalAmount = booking.invoice.baseService + booking.invoice.totalAmount + booking.invoice.platformFee;

        await booking.save();

        return res.status(200).json({ success: true, message: 'Job completed', invoice: booking.invoice });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};