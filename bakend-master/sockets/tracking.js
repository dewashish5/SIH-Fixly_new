import User from '../models/User.js';
import Booking from '../models/Booking.js';

// In-memory cache for fast sync when customer/worker joins room
const latestBookingLocations = new Map();

/**
 * Registers all real-time Socket.io event listeners and business logic (e.g. tracking and updates)
 * @param {object} io - The initialized socket.io server instance
 */
export const registerSocketHandlers = (io) => {
    io.on('connection', (socket) => {
        console.log(`[Socket] User Connected: ${socket.id}`);

        const handleJoinRoom = (payload) => {
            const rawId = typeof payload === 'object' && payload !== null 
                ? (payload.bookingId || payload.id || payload.roomId) 
                : payload;
            
            if (!rawId) {
                console.warn(`[Socket] join_booking_room missing bookingId from ${socket.id}`);
                return;
            }

            const cleanId = String(rawId).trim();
            const roomName = `booking_${cleanId}`;
            socket.join(roomName);
            console.log(`[Socket] Client ${socket.id} joined room ${roomName}`);

            // Send immediate last known location if cached
            if (latestBookingLocations.has(cleanId)) {
                const cached = latestBookingLocations.get(cleanId);
                socket.emit('live_tracking', cached);
                console.log(`[Socket] Sent cached location to ${socket.id} for booking ${cleanId}`);
            }
        };

        // 1. Join Specific Booking Room (Customer and Worker)
        socket.on('join_booking_room', handleJoinRoom);
        socket.on('joinBooking', handleJoinRoom);
        socket.on('subscribeBooking', handleJoinRoom);

        // 2. Real-time Worker Location Update (Broadcast and DB sync)
        socket.on('worker_location_update', async (data) => {
            if (!data) return;

            const bookingId = typeof data.bookingId === 'string' 
                ? data.bookingId.trim() 
                : (data.bookingId ? String(data.bookingId) : null);

            const lat = parseFloat(data.lat ?? data.latitude);
            const lng = parseFloat(data.lng ?? data.longitude);
            const heading = parseFloat(data.heading ?? data.bearing ?? 0);

            if (Number.isNaN(lat) || Number.isNaN(lng)) {
                console.warn(`[Socket] Invalid coordinates received from ${socket.id}:`, data);
                return;
            }

            const updatePayload = {
                bookingId,
                lat,
                lng,
                heading: Number.isNaN(heading) ? 0 : heading,
                timestamp: Date.now()
            };

            if (bookingId) {
                latestBookingLocations.set(bookingId, updatePayload);

                // Broadcast real-time location to the booking room
                io.to(`booking_${bookingId}`).emit('live_tracking', updatePayload);
                // Also emit alias for backwards compatibility
                io.to(`booking_${bookingId}`).emit('worker:location', updatePayload);
            } else {
                // Broadcast to sender's joined rooms
                socket.broadcast.emit('live_tracking', updatePayload);
            }

            // Asynchronously sync worker's current location to MongoDB
            if (bookingId && bookingId.length === 24) {
                try {
                    const booking = await Booking.findById(bookingId);
                    if (booking && booking.worker) {
                        await User.findByIdAndUpdate(booking.worker, {
                            $set: {
                                location: {
                                    type: 'Point',
                                    coordinates: [lng, lat]
                                }
                            }
                        });
                    }
                } catch (error) {
                    console.error('[Socket] Failed to update worker location in DB:', error.message);
                }
            }
        });

        // 3. User Disconnection
        socket.on('disconnect', () => {
            console.log(`[Socket] User Disconnected: ${socket.id}`);
        });
    });
};

