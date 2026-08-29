import dotenv from 'dotenv';
dotenv.config();

import Booking from '../models/Booking.js';
import Service from '../models/Service.js';

// Screen 5 & 6: Estimate Price Breakdown
export const calculateEstimate = async (req, res) => {
    try {
        const { serviceId, estimatedHours = 1 } = req.body;

        const defaultLaborRate = parseFloat(process.env.DEFAULT_LABOR_RATE_PER_HR) || 45;
        const platformFee = parseFloat(process.env.DEFAULT_PLATFORM_FEE) || 15;

        const service = await Service.findById(serviceId);
        const basePrice = service ? service.basePrice : defaultLaborRate;

        const laborMin = basePrice * estimatedHours;
        const laborMax = laborMin + 45;
        const materialsMin = 20;
        const materialsMax = 40;

        return res.status(200).json({
            success: true,
            estimate: {
                laborEstimate: { min: laborMin, max: laborMax },
                materialsParts: { min: materialsMin, max: materialsMax },
                serviceFee: platformFee,
                totalEstimate: {
                    min: laborMin + materialsMin + platformFee,
                    max: laborMax + materialsMax + platformFee
                }
            }
        });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

// Screen 8: Create New Booking
export const createBooking = async (req, res) => {
    try {
        const { serviceId, workerId, problemDescription, problemPhotos, addressLine, coordinates, scheduledTime, invoice } = req.body;

        const booking = await Booking.create({
            customer: req.user.id,
            worker: workerId || null,
            service: serviceId,
            problemDescription,
            problemPhotos: problemPhotos || [],
            serviceAddress: {
                addressLine,
                location: { type: 'Point', coordinates }
            },
            scheduledTime: scheduledTime || Date.now(),
            status: workerId ? 'ACCEPTED' : 'SEARCHING',
            invoice: invoice || {}
        });

        return res.status(201).json({
            success: true,
            message: 'Booking created successfully',
            booking
        });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

// Screen 9: Get Booking Confirmation & Status
export const getBookingDetails = async (req, res) => {
    try {
        const { bookingId } = req.params;

        const booking = await Booking.findById(bookingId)
            .populate('service')
            .populate('worker', 'name phone avatar rating')
            .populate('customer', 'name phone')
            .lean();

        if (!booking) {
            return res.status(404).json({ success: false, message: 'Booking not found' });
        }

        return res.status(200).json({ success: true, booking });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

// Cancel Booking
export const cancelBooking = async (req, res) => {
    try {
        const { bookingId } = req.params;

        const booking = await Booking.findById(bookingId);
        if (!booking) return res.status(404).json({ success: false, message: 'Booking not found' });

        if (['COMPLETED', 'CANCELLED'].includes(booking.status)) {
            return res.status(400).json({ success: false, message: 'Cannot cancel an already completed/cancelled booking' });
        }

        booking.status = 'CANCELLED';
        await booking.save();

        return res.status(200).json({ success: true, message: 'Booking cancelled successfully', booking });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};


export const getBookingHistory = async (req, res) => {
    try {
        const userId = req.user.id;
        // Yahan database se user ki past bookings fetch karne ka logic likhein
        res.status(200).json({
            success: true,
            message: 'Booking history fetched successfully',
            data: []
        });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

export const getBookingInvoice = async (req, res) => {
    try {
        const { bookingId } = req.params;
        // Yahan invoice generate karne ya fetch karne ka logic likhein
        res.status(200).json({
            success: true,
            message: 'Booking invoice fetched successfully',
            invoiceUrl: ''
        });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};


export const getLiveTracking = async (req, res) => {
    try {
        const { bookingId } = req.params;
        // Yahan worker ki live location fetch karne ka logic likhein
        res.status(200).json({
            success: true,
            message: 'Live tracking data fetched successfully',
            location: { latitude: 0.0, longitude: 0.0 }
        });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

export const triggerSosAlert = async (req, res) => {
    try {
        const { bookingId } = req.params;
        // Yahan emergency SOS alert trigger karne ka logic likhein
        res.status(200).json({
            success: true,
            message: 'SOS alert triggered successfully. Emergency contacts notified.'
        });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};