import { Queue } from 'bullmq';
import { redisConnection } from '../config/redis.js';

export const scheduledBookingQueue = new Queue('scheduled-booking-queue', {
    connection: redisConnection
});

export const scheduleReminders = async (bookingId, scheduledTime) => {
    const timeMs = scheduledTime.getTime();
    
    // 24 hours before
    const time24h = timeMs - 24 * 60 * 60 * 1000;
    if (time24h > Date.now()) {
        await scheduledBookingQueue.add('reminder-24h', { bookingId, type: '24h' }, { delay: time24h - Date.now() });
    }
    
    // 1 hour before
    const time1h = timeMs - 60 * 60 * 1000;
    if (time1h > Date.now()) {
        await scheduledBookingQueue.add('reminder-1h', { bookingId, type: '1h' }, { delay: time1h - Date.now() });
    }
    
    // 30 mins before
    const time30m = timeMs - 30 * 60 * 1000;
    if (time30m > Date.now()) {
        await scheduledBookingQueue.add('reminder-30m', { bookingId, type: '30m' }, { delay: time30m - Date.now() });
    }
};
