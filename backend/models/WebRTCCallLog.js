import mongoose from 'mongoose';

const webrtcCallLogSchema = new mongoose.Schema({
    booking: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Booking',
        required: true,
        index: true
    },
    bookingId: {
        type: String,
        required: true,
        index: true
    },
    caller: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true,
        index: true
    },
    receiver: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true,
        index: true
    },
    callerRole: {
        type: String,
        enum: ['customer', 'worker'],
        required: true
    },
    status: {
        type: String,
        enum: ['INITIATED', 'RINGING', 'ACCEPTED', 'REJECTED', 'BUSY', 'MISSED', 'FAILED', 'COMPLETED'],
        default: 'INITIATED',
        index: true
    },
    startedAt: {
        type: Date,
        default: Date.now
    },
    connectedAt: {
        type: Date,
        default: null
    },
    endedAt: {
        type: Date,
        default: null
    },
    durationSeconds: {
        type: Number,
        default: 0
    },
    endReason: {
        type: String,
        enum: [
            'NORMAL_HANGUP',
            'REJECTED',
            'BUSY',
            'MISSED',
            'FIREWALL_BLOCKED',
            'NETWORK_DISCONNECT',
            'CALLER_CANCELLED',
            'UNKNOWN'
        ],
        default: 'UNKNOWN'
    },
    networkDiagnostics: {
        callerNetwork: { type: String, enum: ['wifi', 'cellular', 'ethernet', 'unknown'], default: 'unknown' },
        receiverNetwork: { type: String, enum: ['wifi', 'cellular', 'ethernet', 'unknown'], default: 'unknown' },
        firewallBlocked: { type: Boolean, default: false },
        iceConnectionState: { type: String, default: null },
        details: { type: String, default: null }
    }
}, { timestamps: true });

webrtcCallLogSchema.index({ booking: 1, createdAt: -1 });
webrtcCallLogSchema.index({ caller: 1, createdAt: -1 });
webrtcCallLogSchema.index({ receiver: 1, createdAt: -1 });

const WebRTCCallLog = mongoose.model('WebRTCCallLog', webrtcCallLogSchema);

export default WebRTCCallLog;
