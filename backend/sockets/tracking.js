import User from '../models/User.js';
import Booking from '../models/Booking.js';
import redis from '../config/redis.js';

/**
 * Registers all real-time Socket.io event listeners and business logic (e.g. tracking and updates)
 * @param {object} io - The initialized socket.io server instance
 */
export const registerSocketHandlers = (io) => {
    io.on('connection', (socket) => {
        console.log(`User Connected: ${socket.id}`);

        // 1. Join Specific Booking Room (Customer and Worker)
        socket.on('join_booking_room', (bookingId) => {
            socket.join(`booking_${bookingId}`);
        });

        // 2. Real-time Worker Location Update (Broadcast via Socket.io & Cache in Redis with 60s TTL)
        socket.on('worker_location_update', async (data) => {
            const { bookingId, lat, lng, heading } = data;

            // Broadcast real-time location to the booking room (Does NOT touch MongoDB)
            io.to(`booking_${bookingId}`).emit('live_tracking', {
                lat: parseFloat(lat), 
                lng: parseFloat(lng), 
                heading: heading || 0, 
                timestamp: Date.now()
            });

            // Cache temporary live GPS in Redis with 60s TTL (Zero DB hits, auto-expires, zero memory leak)
            try {
                await redis.set(
                    `tracking:booking:${bookingId}`,
                    JSON.stringify({
                        lat: parseFloat(lat),
                        lng: parseFloat(lng),
                        heading: heading || 0,
                        timestamp: Date.now()
                    }),
                    'EX',
                    60
                );
            } catch (err) {
                console.warn('Redis live tracking cache warning:', err.message);
            }

            // Sync worker live location in User model if workerId provided
            if (data.workerId && !isNaN(lat) && !isNaN(lng)) {
                User.findByIdAndUpdate(data.workerId, {
                    location: { type: 'Point', coordinates: [parseFloat(lng), parseFloat(lat)] }
                }).catch(() => {});
            }
        });

        // 3. User Disconnection
        socket.on('disconnect', () => {
            console.log(`User Disconnected: ${socket.id}`);
        });
    });
};
