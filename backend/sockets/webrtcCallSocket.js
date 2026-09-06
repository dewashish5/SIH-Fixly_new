import Booking from '../models/Booking.js';
import WebRTCCallLog from '../models/WebRTCCallLog.js';
import redis from '../config/redis.js';
import { sendIncomingCallPush, sendCancelCallPush } from '../services/webrtcCallPushService.js';
import { buildBookingQuery } from '../controllers/webrtcCallController.js';

export const getCanonicalBookingKey = (bookingId) => {
    if (!bookingId) return '';
    return String(bookingId).trim().replace(/^#/, '');
};

/**
 * Normalizes booking ID into all valid room name aliases (with and without '#').
 * Ensures socket emissions reach the peer regardless of which variant is sent.
 */
export const getTargetCallRooms = (bookingId) => {
    if (!bookingId) return [];
    const clean = String(bookingId).trim();
    const rooms = new Set();
    rooms.add(`webrtc_call_${clean}`);
    if (clean.startsWith('#')) {
        rooms.add(`webrtc_call_${clean.slice(1)}`);
    } else {
        rooms.add(`webrtc_call_#${clean}`);
    }
    return Array.from(rooms);
};

/**
 * Registers WebRTC Audio Calling Socket.io event listeners.
 * Employs Redis Pub/Sub for seamless scaling across multi-container AWS ECS tasks.
 * Ensures strict participant authorization and Wi-Fi firewall diagnostics.
 * @param {object} io - The initialized socket.io server instance
 */
export const registerWebRTCSocketHandlers = (io) => {
    io.on('connection', (socket) => {
        // Track rooms joined by this socket for clean disconnection handling
        socket.callRooms = new Set();

        // =========================================================================
        // 1. Join Secure Booking Call Room (Strict Authorization: Customer & Worker only)
        // =========================================================================
        socket.on('webrtc:join-room', async (data) => {
            try {
                const { bookingId, userId } = data || {};

                if (!bookingId || !userId) {
                    return socket.emit('webrtc:error', {
                        errorCode: 'INVALID_PARAMETERS',
                        message: 'bookingId and userId are required to join the call room'
                    });
                }

                const bookingQuery = buildBookingQuery(bookingId);
                if (!bookingQuery) {
                    return socket.emit('webrtc:error', {
                        errorCode: 'INVALID_PARAMETERS',
                        message: 'Invalid bookingId provided'
                    });
                }

                // Verify booking and participants safely (supports #BK-... and MongoDB _id)
                const booking = await Booking.findOne(bookingQuery)
                    .select('_id bookingId customer worker status');

                if (!booking) {
                    return socket.emit('webrtc:error', {
                        errorCode: 'BOOKING_NOT_FOUND',
                        message: 'Booking not found for audio call'
                    });
                }

                const customerId = String(booking.customer);
                const workerId = String(booking.worker);
                const requesterId = String(userId);

                // Strictly disallow any third person from joining the channel
                if (requesterId !== customerId && requesterId !== workerId) {
                    return socket.emit('webrtc:error', {
                        errorCode: 'UNAUTHORIZED_CALL_PARTICIPANT',
                        message: 'Sirf is booking ke customer aur assigned worker hi call room me shamil ho sakte hain.'
                    });
                }

                const canonicalId = String(booking.bookingId);
                const mongoId = String(booking._id);
                const roomsToJoin = new Set([
                    `webrtc_call_${canonicalId}`,
                    `webrtc_call_${mongoId}`
                ]);
                if (canonicalId.startsWith('#')) {
                    roomsToJoin.add(`webrtc_call_${canonicalId.slice(1)}`);
                } else {
                    roomsToJoin.add(`webrtc_call_#${canonicalId}`);
                }

                roomsToJoin.forEach((r) => {
                    socket.join(r);
                    socket.callRooms.add(r);
                });

                socket.currentUserId = requesterId;
                socket.currentBookingId = canonicalId;

                console.log(`[WebRTC] User ${requesterId} joined channel aliases: ${Array.from(roomsToJoin).join(', ')}`);

                socket.emit('webrtc:room-joined', {
                    bookingId: canonicalId,
                    room: `webrtc_call_${canonicalId}`,
                    userId: requesterId,
                    role: requesterId === customerId ? 'customer' : 'worker'
                });

                // Inform counterpart across all room aliases that peer is ready
                socket.to(Array.from(roomsToJoin)).emit('webrtc:peer-ready', {
                    userId: requesterId,
                    role: requesterId === customerId ? 'customer' : 'worker'
                });

            } catch (err) {
                console.error('[WebRTC] join-room error:', err.message);
                socket.emit('webrtc:error', {
                    errorCode: 'ROOM_JOIN_FAILED',
                    message: 'Call room join karne me dikkat aayi'
                });
            }
        });

        // =========================================================================
        // 2. Call Initiation (Rings Counterpart)
        // =========================================================================
        socket.on('webrtc:call-initiate', async (data) => {
            try {
                const { bookingId, callerId, callerName, callerAvatar, callerRole } = data || {};
                const targetRooms = getTargetCallRooms(bookingId);

                console.log(`[WebRTC] Initiating call in rooms [${targetRooms.join(', ')}] by ${callerRole} (${callerId})`);

                // Broadcast incoming call to counterpart in room aliases (Omits real phone numbers)
                socket.to(targetRooms).emit('webrtc:incoming-call', {
                    bookingId,
                    caller: {
                        id: callerId,
                        name: callerName || (callerRole === 'customer' ? 'Customer' : 'Worker'),
                        avatar: callerAvatar || null,
                        role: callerRole
                    },
                    timestamp: Date.now()
                });

                // Update Redis active call state with 180s TTL
                try {
                    const redisCallKey = `webrtc:call:${getCanonicalBookingKey(bookingId)}`;
                    await redis.set(
                        redisCallKey,
                        JSON.stringify({
                            bookingId,
                            callerId,
                            callerRole,
                            status: 'RINGING',
                            timestamp: Date.now()
                        }),
                        'EX',
                        180
                    );
                } catch (redisErr) {
                    console.warn('[WebRTC] Redis call state cache warning:', redisErr.message);
                }

                // Dispatch FCM High-Priority Push to wake up phone if recipient app is closed/minimized
                try {
                    const bookingQuery = buildBookingQuery(bookingId);
                    const booking = bookingQuery ? await Booking.findOne(bookingQuery)
                        .select('bookingId customer worker service')
                        .populate('service', 'title') : null;

                    if (booking) {
                        const isCallerCustomer = String(callerId) === String(booking.customer);
                        const recipientUserId = isCallerCustomer ? booking.worker : booking.customer;
                        if (recipientUserId) {
                            sendIncomingCallPush({
                                recipientUserId,
                                bookingId: booking.bookingId,
                                callSessionId: `call_${booking.bookingId}_${Date.now()}`,
                                callerId,
                                callerName,
                                callerAvatar,
                                callerRole,
                                serviceTitle: booking.service?.title || 'Gig Service'
                            }).catch((err) => console.warn('[WebRTC Socket] FCM push error:', err.message));
                        }
                    }
                } catch (lookupErr) {
                    console.warn('[WebRTC Socket] booking lookup for push error:', lookupErr.message);
                }

            } catch (err) {
                console.error('[WebRTC] call-initiate error:', err.message);
            }
        });

        // =========================================================================
        // 3. Call Acceptance
        // =========================================================================
        socket.on('webrtc:call-accept', async (data) => {
            try {
                const { bookingId, receiverId } = data || {};
                const targetRooms = getTargetCallRooms(bookingId);

                console.log(`[WebRTC] Call accepted in rooms [${targetRooms.join(', ')}] by receiver ${receiverId}`);

                // Notify caller that call was accepted
                socket.to(targetRooms).emit('webrtc:call-accepted', {
                    bookingId,
                    receiverId,
                    timestamp: Date.now()
                });

                // Update Redis status to CONNECTED
                try {
                    const redisCallKey = `webrtc:call:${getCanonicalBookingKey(bookingId)}`;
                    const existingCallRaw = await redis.get(redisCallKey);
                    let callObj = existingCallRaw ? JSON.parse(existingCallRaw) : {};
                    callObj.status = 'CONNECTED';
                    callObj.connectedAt = Date.now();
                    await redis.set(redisCallKey, JSON.stringify(callObj), 'EX', 3600); // 1 hour call max
                } catch (redisErr) {
                    console.warn('[WebRTC] Redis call state update warning:', redisErr.message);
                }

            } catch (err) {
                console.error('[WebRTC] call-accept error:', err.message);
            }
        });

        // =========================================================================
        // 4. Call Rejection / Busy
        // =========================================================================
        socket.on('webrtc:call-reject', async (data) => {
            try {
                const { bookingId, reason } = data || {};
                const targetRooms = getTargetCallRooms(bookingId);

                console.log(`[WebRTC] Call rejected in rooms [${targetRooms.join(', ')}]. Reason: ${reason}`);

                socket.to(targetRooms).emit('webrtc:call-rejected', {
                    bookingId,
                    reason: reason || 'DECLINED',
                    timestamp: Date.now()
                });

                // Clean up Redis call state
                try {
                    await redis.del(`webrtc:call:${getCanonicalBookingKey(bookingId)}`);
                } catch (redisErr) {
                    console.warn('[WebRTC] Redis del error:', redisErr.message);
                }

            } catch (err) {
                console.error('[WebRTC] call-reject error:', err.message);
            }
        });

        // =========================================================================
        // 5. WebRTC SDP Offer Relay
        // =========================================================================
        socket.on('webrtc:offer', (data) => {
            const { bookingId, sdp } = data || {};
            if (bookingId && sdp) {
                socket.to(getTargetCallRooms(bookingId)).emit('webrtc:offer', { sdp, bookingId });
            }
        });

        // =========================================================================
        // 6. WebRTC SDP Answer Relay
        // =========================================================================
        socket.on('webrtc:answer', (data) => {
            const { bookingId, sdp } = data || {};
            if (bookingId && sdp) {
                socket.to(getTargetCallRooms(bookingId)).emit('webrtc:answer', { sdp, bookingId });
            }
        });

        // =========================================================================
        // 7. ICE Candidate Exchange
        // =========================================================================
        socket.on('webrtc:ice-candidate', (data) => {
            const { bookingId, candidate } = data || {};
            if (bookingId && candidate) {
                socket.to(getTargetCallRooms(bookingId)).emit('webrtc:ice-candidate', { candidate, bookingId });
            }
        });

        // =========================================================================
        // 8. Firewall Restriction & Strict NAT ICE Failure Detection
        // =========================================================================
        socket.on('webrtc:ice-failed', async (data) => {
            try {
                const { bookingId, networkType, iceState, details } = data || {};
                const targetRooms = getTargetCallRooms(bookingId);
                const isWifi = networkType === 'wifi';

                console.warn(`[WebRTC] ICE Failure detected in rooms [${targetRooms.join(', ')}] (Network: ${networkType}, ICE: ${iceState})`);

                if (isWifi) {
                    // Send explicit instructions for Wi-Fi Firewall block
                    const firewallError = {
                        errorCode: 'FIREWALL_BLOCKED_WIFI_RESTRICTION',
                        message: 'Aapke Wi-Fi network ya router firewall ne audio call ports block kar diye hain. Kripya apna Wi-Fi band karke mobile data (personal internet) chalu karein aur call dobara lagayein.',
                        suggestion: 'SWITCH_TO_MOBILE_DATA',
                        networkType: 'wifi',
                        bookingId
                    };

                    // Send to reporting socket
                    socket.emit('webrtc:error', firewallError);

                    // Notify counterpart so they know why the call couldn't connect
                    socket.to(targetRooms).emit('webrtc:peer-network-issue', {
                        bookingId,
                        message: 'Doosre user ka Wi-Fi firewall connection ko block kar raha hai. Switch ki pratiksha kar rahe hain.',
                        suggestion: 'WAIT_FOR_PEER_NETWORK_SWITCH'
                    });

                    // Log audit event
                    try {
                        const bookingQuery = buildBookingQuery(bookingId);
                        const booking = bookingQuery ? await Booking.findOne(bookingQuery)
                            .select('_id bookingId customer worker') : null;

                        if (booking) {
                            await WebRTCCallLog.create({
                                booking: booking._id,
                                bookingId: booking.bookingId,
                                caller: booking.customer,
                                receiver: booking.worker || booking.customer,
                                callerRole: socket.currentUserId === String(booking.customer) ? 'customer' : 'worker',
                                status: 'FAILED',
                                endReason: 'FIREWALL_BLOCKED',
                                networkDiagnostics: {
                                    callerNetwork: isWifi ? 'wifi' : 'unknown',
                                    firewallBlocked: true,
                                    iceConnectionState: iceState || 'failed',
                                    details: details || 'Wi-Fi UDP/STUN firewall block detected'
                                }
                            });
                        }
                    } catch (logErr) {
                        console.warn('[WebRTC] Error logging firewall failure:', logErr.message);
                    }
                } else {
                    // Generic connection issue
                    socket.emit('webrtc:error', {
                        errorCode: 'WEBRTC_ICE_FAILED',
                        message: 'Audio call connection establish nahi ho paya. Kripya internet signal check karein.',
                        suggestion: 'CHECK_INTERNET_CONNECTION',
                        networkType: networkType || 'unknown'
                    });
                }

            } catch (err) {
                console.error('[WebRTC] ice-failed handler error:', err.message);
            }
        });

        // =========================================================================
        // 9. Call Hangup / Normal Termination
        // =========================================================================
        socket.on('webrtc:call-hangup', async (data) => {
            try {
                const { bookingId, durationSeconds, endReason } = data || {};
                const targetRooms = getTargetCallRooms(bookingId);

                console.log(`[WebRTC] Call hung up in rooms [${targetRooms.join(', ')}]. Duration: ${durationSeconds || 0}s`);

                // Notify counterpart
                socket.to(targetRooms).emit('webrtc:call-ended', {
                    bookingId,
                    durationSeconds: durationSeconds || 0,
                    endReason: endReason || 'NORMAL_HANGUP',
                    timestamp: Date.now()
                });

                // Persist completed call log and clean Redis cache
                try {
                    const redisCallKey = `webrtc:call:${getCanonicalBookingKey(bookingId)}`;
                    const rawCall = await redis.get(redisCallKey);
                    await redis.del(redisCallKey);

                    let callData = rawCall ? JSON.parse(rawCall) : {};

                    const bookingQuery = buildBookingQuery(bookingId);
                    const booking = bookingQuery ? await Booking.findOne(bookingQuery)
                        .select('_id bookingId customer worker') : null;

                    if (booking) {
                        const recipientToDismiss = (callData.callerId && String(callData.callerId) === String(booking.customer))
                            ? (booking.worker || booking.customer)
                            : booking.customer;

                        sendCancelCallPush({
                            recipientUserId: recipientToDismiss,
                            bookingId: booking.bookingId,
                            callSessionId: callData.callSessionId
                        }).catch(() => {});

                        await WebRTCCallLog.create({
                            booking: booking._id,
                            bookingId: booking.bookingId,
                            caller: callData.callerId || booking.customer,
                            receiver: (callData.callerId && String(callData.callerId) === String(booking.customer))
                                ? (booking.worker || booking.customer)
                                : booking.customer,
                            callerRole: callData.callerRole || 'customer',
                            status: durationSeconds > 0 ? 'COMPLETED' : 'MISSED',
                            durationSeconds: durationSeconds || 0,
                            startedAt: callData.initiatedAt ? new Date(callData.initiatedAt) : new Date(),
                            connectedAt: callData.connectedAt ? new Date(callData.connectedAt) : null,
                            endedAt: new Date(),
                            endReason: endReason || 'NORMAL_HANGUP'
                        });
                    }
                } catch (dbErr) {
                    console.warn('[WebRTC] Call log save error:', dbErr.message);
                }

            } catch (err) {
                console.error('[WebRTC] call-hangup error:', err.message);
            }
        });

        // =========================================================================
        // 10. Disconnect Cleanup
        // =========================================================================
        socket.on('disconnect', () => {
            if (socket.callRooms && socket.callRooms.size > 0) {
                for (const room of socket.callRooms) {
                    socket.to(room).emit('webrtc:peer-disconnected', {
                        userId: socket.currentUserId,
                        room,
                        timestamp: Date.now()
                    });
                }
            }
        });
    });
};
