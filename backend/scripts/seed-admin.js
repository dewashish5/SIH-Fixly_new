import dotenv from 'dotenv';
dotenv.config();

import mongoose from 'mongoose';
import User from '../models/User.js';

const ADMIN_EMAIL = process.env.ADMIN_EMAIL || 'admin@fixly.com';
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD || 'Admin@123';
const ADMIN_NAME = process.env.ADMIN_NAME || 'Fixly Admin';

async function main() {
    await mongoose.connect(process.env.MONGO_URI);
    let user = await User.findOne({ email: ADMIN_EMAIL.toLowerCase() });
    if (!user) {
        user = new User({
            name: ADMIN_NAME,
            email: ADMIN_EMAIL.toLowerCase(),
            password: ADMIN_PASSWORD,
            role: 'admin',
            isVerified: true,
            isEmailVerified: true,
        });
    } else {
        user.name = ADMIN_NAME;
        user.role = 'admin';
        user.password = ADMIN_PASSWORD;
        user.isVerified = true;
        user.isEmailVerified = true;
    }
    await user.save();
    console.log(JSON.stringify({
        ok: true,
        email: user.email,
        password: ADMIN_PASSWORD,
        role: user.role,
        id: String(user._id),
    }));
    await mongoose.disconnect();
}

main().catch((err) => {
    console.error(err);
    process.exit(1);
});
