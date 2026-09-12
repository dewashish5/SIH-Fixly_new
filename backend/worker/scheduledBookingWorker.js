import { Worker } from 'bullmq';
import { redisConnection } from '../config/redis.js';
import Booking from '../models/Booking.js';
import { notifyUser } from '../services/notificationService.js';

export const scheduledBookingWorker = new Worker('scheduled-booking-queue', async (job) => {
    const { bookingId, type } = job.data;

    const booking = await Booking.findById(bookingId).populate('customer').populate('worker');
    if (!booking) return;

    if (!['PENDING', 'APPROVED', 'ACCEPTED', 'SEARCHING'].includes(booking.status)) {
        return; // Job is not active in a way that requires reminders
    }

    let timeText = '';
    if (type === '24h') timeText = '24 hours';
    else if (type === '1h') timeText = '1 hour';
    else if (type === '30m') timeText = '30 minutes';

    if (booking.customer) {
        await notifyUser({
            recipient: booking.customer._id,
            eventType: 'BOOKING_REMINDER',
            entityId: booking._id,
            bookingId: booking._id,
            dedupeKey: `REMINDER:${booking._id}:CUST:${type}`,
        });
    }

    if (booking.worker) {
        await notifyUser({
            recipient: booking.worker._id,
            eventType: 'BOOKING_REMINDER',
            entityId: booking._id,
            bookingId: booking._id,
            dedupeKey: `REMINDER:${booking._id}:WORKER:${type}`,
        });
    }
}, {
    connection: redisConnection
});

scheduledBookingWorker.on('completed', (job) => {
    // console.log(`Reminder job ${job.id} completed for booking ${job.data.bookingId}`);
});

scheduledBookingWorker.on('failed', (job, err) => {
    console.error(`Reminder job ${job?.id} failed:`, err);
});
