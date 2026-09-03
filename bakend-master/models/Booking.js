import mongoose from 'mongoose';

const addOnItemSchema = new mongoose.Schema({
    title: { type: String, required: true },
    price: { type: Number, required: true }
}, { _id: true });

const bookingSchema = new mongoose.Schema({
    // Auto-generates format: #BK-84920
    bookingId: {
        type: String,
        required: true,
        unique: true,
        default: () => `#BK-${Math.floor(10000 + Math.random() * 90000)}`
    },
    customer: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    worker: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },
    service: { type: mongoose.Schema.Types.ObjectId, ref: 'Service', required: true },

    status: {
        type: String,
        enum: ['SEARCHING', 'ACCEPTED', 'ARRIVED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED'],
        default: 'SEARCHING'
    },

    problemDescription: { type: String, default: null },
    problemPhotos: [{ type: String }],

    serviceAddress: {
        addressLine: { type: String, required: true },
        location: {
            type: { type: String, enum: ['Point'], default: 'Point' },
            coordinates: { type: [Number], required: true } // [longitude, latitude]
        }
    },
    scheduledTime: { type: Date, default: Date.now },

    // Auto-generates 4-Digit Security OTP
    arrivalOtp: {
        type: String,
        required: true,
        default: () => Math.floor(1000 + Math.random() * 9000).toString()
    },

    addOns: { type: [addOnItemSchema], default: [] },

    jobStartedAt: { type: Date, default: null },
    jobCompletedAt: { type: Date, default: null },

    isReviewed: { type: Boolean, default: false },
    declineReason: { type: String, default: null },
    declinedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },

    invoice: {
        baseServiceFee: { type: Number, default: 0 },
        extraPartsTotal: { type: Number, default: 0 },
        platformFee: { type: Number, default: 15 },
        totalAmount: { type: Number, default: 0 },
        paymentStatus: { type: String, enum: ['PENDING', 'PAID', 'FAILED'], default: 'PENDING' },
        paymentMethod: { type: String, default: 'UPI' }
    }
}, { timestamps: true });

bookingSchema.index({ "serviceAddress.location": '2dsphere' });

const Booking = mongoose.model('Booking', bookingSchema);

export default Booking;
