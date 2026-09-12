import express from 'express';
import {
    initiateWebRTCCall,
    getIceServers,
    reportNetworkDiagnostics,
    getCallStatus,
    getCallHistory
} from '../controllers/webrtcCallController.js';
import { protect } from '../middleware/authMiddleware.js';

const router = express.Router();

/**
 * WebRTC Masked Audio Calling Endpoints
 * Base Path: /api/webrtc
 */

// 1. Initiate Audio Call for a Booking (returns masked profiles & channel)
router.post('/call/initiate', protect, initiateWebRTCCall);

// 2. Fetch ICE Servers (STUN/TURN) Configuration
router.get('/config/ice-servers', protect, getIceServers);

// 3. Network Diagnostics & Wi-Fi Firewall Issue Reporting
router.post('/call/network-diagnostics', protect, reportNetworkDiagnostics);

// 4. Check Real-Time Call Status in Redis
router.get('/call/status/:bookingId', protect, getCallStatus);

// 5. User Call History (Strictly masked, no phone numbers)
router.get('/call/history', protect, getCallHistory);

export default router;
