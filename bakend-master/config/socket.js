import { Server } from 'socket.io';
import { createAdapter } from '@socket.io/redis-adapter';
import redis from './redis.js';

export const initSocket = (httpServer) => {
    const io = new Server(httpServer, {
        cors: { origin: '*' }
    });

    // Redis Pub/Sub instances for horizontal scaling
    const pubClient = redis.duplicate();
    const subClient = redis.duplicate();

    io.adapter(createAdapter(pubClient, subClient));

    io.on('connection', (socket) => {
        console.log(`User Connected: ${socket.id}`);

        // Customer & Worker join the specific booking room
        socket.on('join_booking_room', (bookingId) => {
            socket.join(`booking_${bookingId}`);
        });

        // Worker emits location -> Server broadcasts to Customer in that room
        socket.on('worker_location_update', (data) => {
            const { bookingId, lat, lng, heading } = data;

            // Broadcast location to specific booking room
            io.to(`booking_${bookingId}`).emit('live_tracking', {
                lat, lng, heading, timestamp: Date.now()
            });
        });

        socket.on('disconnect', () => {
            console.log(`User Disconnected: ${socket.id}`);
        });
    });

    return io;
};