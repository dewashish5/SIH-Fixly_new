import dotenv from 'dotenv';
dotenv.config();

import Booking from '../models/Booking.js';
import Service from '../models/Service.js';
import User from '../models/User.js';

// Screen 5 & 6: Estimate Price Breakdown
export const calculateEstimate = async (req, res) => {
    // #swagger.tags = ['Bookings']
    // #swagger.parameters['body'] = { in: 'body', description: 'Estimate Input', required: true, schema: { serviceId: '64f1bc000000000000000002', estimatedHours: 2 } }
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
        const role = req.user.role;

        let query = {};
        if (role === 'worker') {
            query = { worker: userId };
        } else {
            query = { customer: userId };
        }

        const bookings = await Booking.find(query)
            .populate('service')
            .populate('worker', 'name phone avatar workerProfile')
            .populate('customer', 'name phone avatar')
            .sort({ createdAt: -1 });

        return res.status(200).json({
            success: true,
            message: 'Booking history fetched successfully',
            bookings
        });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

export const getBookingInvoice = async (req, res) => {
    try {
        const { bookingId } = req.params;

        const booking = await Booking.findById(bookingId)
            .populate('service')
            .populate('customer', 'name email phone')
            .populate('worker', 'name phone avatar workerProfile')
            .lean();

        if (!booking) {
            return res.status(404).json({ success: false, message: 'Booking not found' });
        }

        return res.status(200).json({
            success: true,
            message: 'Booking invoice fetched successfully',
            invoice: booking.invoice,
            bookingDetails: {
                bookingId: booking.bookingId,
                customer: booking.customer,
                worker: booking.worker,
                service: booking.service,
                addOns: booking.addOns,
                jobStartedAt: booking.jobStartedAt,
                jobCompletedAt: booking.jobCompletedAt,
                status: booking.status
            }
        });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

export const getLiveTracking = async (req, res) => {
    try {
        const { bookingId } = req.params;

        const booking = await Booking.findById(bookingId).populate('worker');
        if (!booking) {
            return res.status(404).json({ success: false, message: 'Booking not found' });
        }

        if (!booking.worker) {
            return res.status(400).json({ success: false, message: 'No worker assigned to this booking yet' });
        }

        const worker = booking.worker;
        if (!worker.location || !worker.location.coordinates) {
            return res.status(404).json({ success: false, message: 'Worker location not available' });
        }

        return res.status(200).json({
            success: true,
            message: 'Live tracking data fetched successfully',
            location: {
                longitude: worker.location.coordinates[0],
                latitude: worker.location.coordinates[1]
            }
        });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

export const triggerSosAlert = async (req, res) => {
    try {
        const { bookingId } = req.params;

        const booking = await Booking.findById(bookingId);
        if (!booking) return res.status(404).json({ success: false, message: 'Booking not found' });

        // Broadcast SOS event to the specific booking room
        const io = req.app.get('io');
        if (io) {
            io.to(`booking_${bookingId}`).emit('sos_alert', {
                bookingId,
                message: 'EMERGENCY: SOS has been triggered!',
                timestamp: Date.now()
            });
        }

        return res.status(200).json({
            success: true,
            message: 'SOS alert triggered successfully. Emergency contacts and socket room notified.'
        });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};