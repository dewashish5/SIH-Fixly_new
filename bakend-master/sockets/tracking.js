import User from '../models/User.js';
import Booking from '../models/Booking.js';

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

        // 2. Real-time Worker Location Update (Broadcast and DB sync)
        socket.on('worker_location_update', async (data) => {
            const { bookingId, lat, lng, heading } = data;

            // Broadcast real-time location to the booking room
            io.to(`booking_${bookingId}`).emit('live_tracking', {
                lat, 
                lng, 
                heading, 
                timestamp: Date.now()
            });

            // Asynchronously sync worker's current location to MongoDB
            try {
                const booking = await Booking.findById(bookingId);
                if (booking && booking.worker) {
                    await User.findByIdAndUpdate(booking.worker, {
                        $set: {
                            location: {
                                type: 'Point',
                                coordinates: [parseFloat(lng), parseFloat(lat)]
                            }
                        }
                    });
                }
            } catch (error) {
                console.error('Failed to update worker location in DB via socket:', error.message);
            }
        });

        // 3. User Disconnection
        socket.on('disconnect', () => {
            console.log(`User Disconnected: ${socket.id}`);
        });
    });
};
