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
        coordinates: { type: [Number], required: true, default: null } // [longitude, latitude]
    }
});

// 2. Worker Profile Schema (Sub-document)
const categoryRateSchema = new mongoose.Schema({
    category: { type: String },
    rate: { type: Number }
}, { _id: false });

const identityDocSchema = new mongoose.Schema({
    docType: { type: String },
    docNumber: { type: String },
    frontPhotoUrl: { type: String },
    backPhotoUrl: { type: String },
    status: { type: String, default: 'PENDING' }
}, { _id: false });

const workerProfileSchema = new mongoose.Schema({
    dateOfBirth: { type: String, default: null },
    gender: { type: String, default: null },
    selfieImageUrl: { type: String, default: null },
    category: { type: String, default: null },
    categories: [{ type: String }],
    rate: { type: Number, default: 0 },
    hourlyRate: { type: Number, default: 0 },
    categoryRates: { type: [categoryRateSchema], default: [] },
    experienceYears: { type: Number, default: 0 },
    bio: { type: String, default: null },
    rating: { type: Number, default: 5.0 },
    totalJobs: { type: Number, default: 0 },
    recentWorkPhotos: [{ type: String }],
    badges: [{ type: String }],
    skills: [{ type: String }],
    certifications: [{ type: String }],
    workAddress: { type: String, default: null },
    identityDocuments: { type: [identityDocSchema], default: [] },
    payoutMethod: { type: String, default: null },
    bank: {
        accountHolderName: { type: String },
        accountNumber: { type: String },
        ifscCode: { type: String }
    },
    upi: {
        upiId: { type: String }
    }
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
        trim: true,
        match: [/^\S+@\S+\.\S+$/, 'Please enter a valid email address']
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
    isEmailVerified: {
        type: Boolean,
        default: false
    },

    // GeoJSON Live Location (Optional, without defaults to prevent index errors when location is off)
    location: {
        type: {
            type: String,
            enum: ['Point']
        },
        coordinates: {
            type: [Number]
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

    // KYC docs — Cloudinary URLs after Flutter /api/upload
    kycDocuments: {
        aadhaarNumber: { type: String, default: null },
        aadhaarFrontPhoto: { type: String, default: null },
        aadhaarBackPhoto: { type: String, default: null },
        panNumber: { type: String, default: null },
        panFrontPhoto: { type: String, default: null },
        panBackPhoto: { type: String, default: null },
        selfieImageUrl: { type: String, default: null },
        certificateUrl: { type: String, default: null },
        govermentIdType: { type: String, default: null },
        govermentIdNumber: { type: String, default: null },
        status: {
            type: String,
            enum: ['none', 'submitted', 'approved', 'rejected'],
            default: 'none'
        }
    },

    payoutDetails: { type: mongoose.Schema.Types.Mixed, default: null },

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

// METHOD: Generate Access Token (Dynamic Expiry)
userSchema.methods.generateAccessToken = function () {
    return jwt.sign(
        { id: this._id, role: this.role },
        process.env.JWT_SECRET,
        { expiresIn: process.env.JWT_ACCESS_EXPIRY || '15m' }
    );
};

// METHOD: Generate Refresh Token (Dynamic Expiry)
userSchema.methods.generateRefreshToken = function () {
    return jwt.sign(
        { id: this._id },
        process.env.REFRESH_SECRET,
        { expiresIn: process.env.JWT_REFRESH_EXPIRY || '7d' }
    );
};

const User = mongoose.model('User', userSchema);

export default User;