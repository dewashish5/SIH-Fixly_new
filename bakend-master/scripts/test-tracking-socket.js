import { io } from 'socket.io-client';

const PORT = process.env.PORT || 8000;
const SERVER_URL = `http://localhost:${PORT}`;
const TEST_BOOKING_ID = 'test-booking-' + Date.now();

console.log(`\n--- Fixly Real-Time Tracking Socket Test ---`);
console.log(`Target: ${SERVER_URL}`);
console.log(`Booking ID: ${TEST_BOOKING_ID}\n`);

// 1. Customer Socket Client
const customerSocket = io(SERVER_URL, {
    transports: ['websocket'],
    reconnection: false
});

// 2. Worker Socket Client
const workerSocket = io(SERVER_URL, {
    transports: ['websocket'],
    reconnection: false
});

let eventsReceived = 0;
const expectedUpdates = 4;

const testCoordinates = [
    { lat: 28.6139, lng: 77.2090, heading: 45 },
    { lat: 28.6149, lng: 77.2100, heading: 60 },
    { lat: 28.6160, lng: 77.2115, heading: 75 },
    { lat: 28.6175, lng: 77.2130, heading: 90 },
];

customerSocket.on('connect', () => {
    console.log(`✅ [Customer] Connected with ID: ${customerSocket.id}`);
    customerSocket.emit('join_booking_room', TEST_BOOKING_ID);
    console.log(`📢 [Customer] Emitted join_booking_room for: ${TEST_BOOKING_ID}`);
});

customerSocket.on('live_tracking', (data) => {
    eventsReceived++;
    console.log(`🎯 [Customer RECEIVED live_tracking #${eventsReceived}]:`, data);

    if (eventsReceived === expectedUpdates) {
        console.log(`\n🎉 SUCCESS! All ${expectedUpdates} real-time location updates received!`);
        cleanupAndExit(0);
    }
});

workerSocket.on('connect', () => {
    console.log(`✅ [Worker] Connected with ID: ${workerSocket.id}`);
    workerSocket.emit('join_booking_room', TEST_BOOKING_ID);

    // Give customer time to join room before emitting updates
    setTimeout(() => {
        console.log(`\n🚀 [Worker] Starting live coordinate broadcast...`);
        testCoordinates.forEach((coord, idx) => {
            setTimeout(() => {
                const payload = {
                    bookingId: TEST_BOOKING_ID,
                    lat: coord.lat,
                    lng: coord.lng,
                    heading: coord.heading
                };
                console.log(`📡 [Worker EMITTING #${idx + 1}]:`, payload);
                workerSocket.emit('worker_location_update', payload);
            }, idx * 400);
        });
    }, 500);
});

function cleanupAndExit(code) {
    customerSocket.disconnect();
    workerSocket.disconnect();
    setTimeout(() => process.exit(code), 200);
}

// Timeout after 6 seconds
setTimeout(() => {
    if (eventsReceived < expectedUpdates) {
        console.error(`❌ Test timed out! Received only ${eventsReceived}/${expectedUpdates} updates.`);
        cleanupAndExit(1);
    }
}, 6000);
