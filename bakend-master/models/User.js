import mongoose from 'mongoose';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';

// 1. Saved Address Schema
const addressSchema = new mongoose.Schema({
    label: { type: String, default: 'Home' }, // Home, Work, Other
    addressLine: { type: String, required: true },
    city: { type: String },
    pincode: { type: String },
    location: {
        type: { type: String, enum: ['Point'], default: 'Point' },
        coordinates: { type: [Number], required: true } // [longitude, latitude]
    }
});

// 2. Worker Profile Schema (Sub-document)
const workerProfileSchema = new mongoose.Schema({
    category: { type: String, default: null }, // e.g., 'Plumbing'
    hourlyRate: { type: Number, default: 0 },
    experienceYears: { type: Number, default: 0 },
    bio: { type: String, default: null },
    rating: { type: Number, default: 5.0 },
    totalJobs: { type: Number, default: 0 },
    recentWorkPhotos: [{ type: String }],
    badges: [{ type: String }] // e.g., 'Background Checked', 'Top Rated'
}, { _id: false });

const userSchema = new mongoose.Schema({
    name: {
        type: String,
        required: true,
        trim: true
    },
    email: {
        type: String,
        required: true,
        unique: true,
        lowercase: true,
        trim: true
    },
    phone: {
        type: String,
        sparse: true,
        trim: true,
        default: null // Frontend check: if (!user.phone) -> Redirect to Add Phone Screen
    },
    password: {
        type: String,
        default: null
    },
    role: {
        type: String,
        enum: ['customer', 'worker', 'admin'],
        default: 'customer'
    },
    authProvider: {
        type: String,
        enum: ['local', 'google'],
        default: 'local'
    },
    avatar: {
        type: String,
        default: null
    },
    isVerified: {
        type: Boolean,
        default: false
    },

    // GeoJSON Live Location (Location default undefined rakhi hai taaki dummy [0,0] coords na jayein)
    location: {
        type: {
            type: String,
            enum: ['Point'],
            default: 'Point'
        },
        coordinates: {
            type: [Number],
            default: undefined // Frontend check: if (!user.location?.coordinates) -> Redirect to Location Permission
        }
    },

    // Saved Addresses (Khali array agar abhi tak address save nahi kiya)
    savedAddresses: {
        type: [addressSchema],
        default: []
    },

    // Worker Profile: Customer ke liye null rahega, Worker ke setup karne par populate hoga
    workerProfile: {
        type: workerProfileSchema,
        default: null // Frontend check: if (user.role === 'worker' && !user.workerProfile) -> Redirect to Worker Setup Screen
    },

    // Single-device login security tracking
    activeDeviceId: {
        type: String,
        default: null
    }
}, {
    timestamps: true
});

// Spatial index for 5km radius queries
userSchema.index({ location: '2dsphere' });

// PRE HOOK: Hash Password before saving
userSchema.pre('save', async function () {
    if (!this.isModified('password') || !this.password) {
        return;
    }

    const salt = await bcrypt.genSalt(10);
    this.password = await bcrypt.hash(this.password, salt);
});

// METHOD: Compare Password
userSchema.methods.comparePassword = async function (enteredPassword) {
    return await bcrypt.compare(enteredPassword, this.password);
};

// METHOD: Generate Access Token (15 mins)
userSchema.methods.generateAccessToken = function () {
    return jwt.sign(
        { id: this._id, role: this.role },
        process.env.JWT_SECRET,
        { expiresIn: '15m' }
    );
};

// METHOD: Generate Refresh Token (7 days)
userSchema.methods.generateRefreshToken = function () {
    return jwt.sign(
        { id: this._id },
        process.env.REFRESH_SECRET,
        { expiresIn: '7d' }
    );
};

const User = mongoose.model('User', userSchema);

export default User;