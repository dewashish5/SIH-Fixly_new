import mongoose from 'mongoose';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';

const userSchema = new mongoose.Schema({
    name: {
        type: String,
        required: true
    },
    email: {
        type: String,
        required: true,
        unique: true
    },
    password: {
        type: String
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
    isVerified: {
        type: Boolean,
        default: false
    }
}, {
    timestamps: true
});

// PRE HOOK: Hash password before saving
// PRE HOOK: Hash password before saving (Bina 'next' ke, async/await automatically handle hota hai)
userSchema.pre('save', async function () {
    // Agar password modify nahi hua hai (ya password field nahi hai), toh skip karo
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

// METHOD: Generate Access Token (Short lived - e.g., 15 mins)
userSchema.methods.generateAccessToken = function () {
    return jwt.sign(
        { id: this._id, role: this.role },
        process.env.JWT_SECRET,
        { expiresIn: '15m' }
    );
};

// METHOD: Generate Refresh Token (Long lived - e.g., 7 days)
userSchema.methods.generateRefreshToken = function () {
    return jwt.sign(
        { id: this._id },
        process.env.REFRESH_SECRET,
        { expiresIn: '7d' }
    );
};

const User = mongoose.model('User', userSchema);

export default User;