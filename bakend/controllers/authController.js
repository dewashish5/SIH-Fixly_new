import User from '../models/User.js';
import redis from '../config/redis.js';
import { generateOtpEmailHtml } from '../utils/emailTemplate.js';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import emailQueue from '../queues/queue.js';

const generateOTP = () => Math.floor(100000 + Math.random() * 900000).toString();

// ==========================================
// SINGLE-DEVICE SESSION HELPER
// ==========================================
const createSession = async (user, deviceId) => {
    const accessToken = jwt.sign(
        { id: user._id, role: user.role },
        process.env.JWT_SECRET,
        { expiresIn: '15m' }
    );
    const refreshToken = jwt.sign(
        { id: user._id },
        process.env.REFRESH_SECRET,
        { expiresIn: '7d' }
    );

    // 1. Check karein ki is user ka pehle se koi active device registered hai ya nahi
    const activeDeviceKey = `user:active-device:${user._id}`;
    const oldDeviceId = await redis.get(activeDeviceKey);

    // 2. Agar purana device tha aur wo naye device se alag hai, toh purana session delete kar do (Single-Device Enforcement)
    if (oldDeviceId && oldDeviceId !== deviceId) {
        await redis.del(`session:${user._id}:${oldDeviceId}`);
    }

    // 3. Pipeline ke through active device aur naya refresh token atomically set karein
    const pipeline = redis.pipeline();
    pipeline.set(activeDeviceKey, deviceId, 'EX', 7 * 24 * 60 * 60);
    pipeline.set(`session:${user._id}:${deviceId}`, refreshToken, 'EX', 7 * 24 * 60 * 60);
    await pipeline.exec();

    return { accessToken, refreshToken };
};

// Helper: Cache Invalidation
export const clearUserCache = async (email) => {
    await redis.del(`user:email:${email}`);
};

// Helper: Fetch cached user or fallback to MongoDB
const getUserCache = async (email) => {
    const cachedUser = await redis.get(`user:email:${email}`);
    if (cachedUser) {
        return JSON.parse(cachedUser);
    }

    const user = await User.findOne({ email }).lean();
    if (user) {
        const ttl = user.isVerified ? 3600 : 300;
        await redis.set(`user:email:${email}`, JSON.stringify(user), 'EX', ttl);
    }
    return user;
};


// ==========================================
// CONTROLLERS
// ==========================================

// 1. REGISTER (Local)
export const registerUser = async (req, res) => {
    try {
        const { name, email, password, role } = req.body;

        let user = await getUserCache(email);

        if (user && user.isVerified) {
            return res.status(400).json({ success: false, message: 'User already exists' });
        }

        if (!user) {
            const newUser = await User.create({ name, email, password, role, authProvider: 'local' });
            user = newUser.toObject();
        }

        const otp = generateOTP();

        // Pipeline: Clear stale user cache & set fresh OTP atomically
        const pipeline = redis.pipeline();
        pipeline.del(`user:email:${email}`);
        pipeline.set(`otp:${email}`, otp, 'EX', 300); // 5 mins OTP expiry
        await pipeline.exec();

        await emailQueue.add('sendOtpEmail', {
            to: email,
            subject: 'Your Verification Code',
            html: generateOtpEmailHtml(otp)
        });

        return res.status(201).json({ success: true, message: 'OTP sent to email. Please verify.' });
    } catch (error) {
        console.error('Register Error:', error);
        return res.status(500).json({ success: false, message: error.message });
    }
};

// 2. VERIFY OTP
export const verifyOTP = async (req, res) => {
    try {
        const { email, otp, deviceId } = req.body;

        const cachedOtp = await redis.get(`otp:${email}`);
        if (!cachedOtp || cachedOtp !== otp) {
            return res.status(400).json({ success: false, message: 'Invalid or expired OTP' });
        }

        const user = await User.findOne({ email });
        if (!user) return res.status(404).json({ success: false, message: 'User not found' });

        user.isVerified = true;
        await user.save();

        const updatedUser = user.toObject();

        // Pipeline: Delete OTP and update verified user cache atomically
        const pipeline = redis.pipeline();
        pipeline.del(`otp:${email}`);
        pipeline.set(`user:email:${email}`, JSON.stringify(updatedUser), 'EX', 3600);
        await pipeline.exec();

        const tokens = await createSession(updatedUser, deviceId);

        const { password: _, ...userWithoutPassword } = updatedUser;
        return res.status(200).json({ success: true, user: userWithoutPassword, ...tokens });
    } catch (error) {
        console.error('Verify OTP Error:', error);
        return res.status(500).json({ success: false, message: error.message });
    }
};

// 3. LOGIN (Local)
export const loginUser = async (req, res) => {
    try {
        const { email, password, deviceId } = req.body;

        const user = await getUserCache(email);
        if (!user) return res.status(404).json({ success: false, message: 'User not found' });

        if (user.authProvider === 'google') {
            return res.status(400).json({ success: false, message: 'Please login using Google' });
        }

        const isMatch = await bcrypt.compare(password, user.password);
        if (!isMatch) return res.status(401).json({ success: false, message: 'Invalid credentials' });

        if (!user.isVerified) {
            return res.status(401).json({ success: false, message: 'Please verify your email first' });
        }

        const tokens = await createSession(user, deviceId);
        const { password: _, ...userWithoutPassword } = user;

        return res.status(200).json({ success: true, user: userWithoutPassword, ...tokens });
    } catch (error) {
        console.error('Login Error:', error);
        return res.status(500).json({ success: false, message: error.message });
    }
};

// 4. REFRESH TOKEN
export const refreshToken = async (req, res) => {
    try {
        const { userId, deviceId, refreshToken } = req.body;

        if (!refreshToken) return res.status(401).json({ success: false, message: 'Refresh Token required' });

        const savedToken = await redis.get(`session:${userId}:${deviceId}`);
        if (!savedToken || savedToken !== refreshToken) {
            return res.status(403).json({ success: false, message: 'Invalid or expired refresh token. Please login again.' });
        }

        const decoded = jwt.verify(refreshToken, process.env.REFRESH_SECRET);

        const newAccessToken = jwt.sign(
            { id: decoded.id },
            process.env.JWT_SECRET,
            { expiresIn: '15m' }
        );

        return res.status(200).json({ success: true, accessToken: newAccessToken });
    } catch (error) {
        console.error('Refresh Token Error:', error);
        return res.status(403).json({ success: false, message: 'Invalid session' });
    }
};

// 5. GOOGLE AUTH
export const googleLogin = async (req, res) => {
    try {
        const { role, deviceId } = req.body;

        const email = "user@example.com";
        const name = "Google User";

        let user = await getUserCache(email);

        if (!user) {
            const newUser = await User.create({
                name,
                email,
                role: role || 'customer',
                authProvider: 'google',
                isVerified: true
            });
            user = newUser.toObject();
            await redis.set(`user:email:${email}`, JSON.stringify(user), 'EX', 3600);
        }

        const tokens = await createSession(user, deviceId);
        const { password: _, ...userWithoutPassword } = user;

        return res.status(200).json({ success: true, user: userWithoutPassword, ...tokens });
    } catch (error) {
        console.error('Google Auth Error:', error);
        return res.status(500).json({ success: false, message: 'Google Auth Failed' });
    }
};

// 6. FORGOT PASSWORD
export const forgotPassword = async (req, res) => {
    try {
        const { email } = req.body;
        const user = await getUserCache(email);

        if (!user) return res.status(404).json({ success: false, message: 'User not found' });
        if (user.authProvider === 'google') return res.status(400).json({ success: false, message: 'Google accounts cannot reset password here' });

        const otp = generateOTP();
        await redis.set(`otp:${email}`, otp, 'EX', 300);

        await emailQueue.add('sendOtpEmail', {
            to: email,
            subject: 'Password Reset Verification Code',
            html: generateOtpEmailHtml(otp)
        });

        return res.status(200).json({ success: true, message: 'Password reset OTP sent to email' });
    } catch (error) {
        console.error('Forgot Password Error:', error);
        return res.status(500).json({ success: false, message: error.message });
    }
};

// 7. RESET PASSWORD
export const resetPassword = async (req, res) => {
    try {
        const { email, otp, newPassword } = req.body;

        const cachedOtp = await redis.get(`otp:${email}`);
        if (!cachedOtp || cachedOtp !== otp) {
            return res.status(400).json({ success: false, message: 'Invalid or expired OTP' });
        }

        const user = await User.findOne({ email });
        if (!user) return res.status(404).json({ success: false, message: 'User not found' });

        user.password = newPassword;
        await user.save();

        const pipeline = redis.pipeline();
        pipeline.del(`otp:${email}`);
        pipeline.del(`user:email:${email}`);
        await pipeline.exec();

        return res.status(200).json({ success: true, message: 'Password reset successful. Please login.' });
    } catch (error) {
        console.error('Reset Password Error:', error);
        return res.status(500).json({ success: false, message: error.message });
    }
};

// 8. LOGOUT
export const logoutUser = async (req, res) => {
    try {
        const { userId, deviceId } = req.body;

        const pipeline = redis.pipeline();
        pipeline.del(`session:${userId}:${deviceId}`);
        pipeline.del(`user:active-device:${userId}`);
        await pipeline.exec();

        return res.status(200).json({ success: true, message: 'Logged out successfully' });
    } catch (error) {
        console.error('Logout Error:', error);
        return res.status(500).json({ success: false, message: error.message });
    }
};



// import User from '../models/User.js';
// import redis from '../config/redis.js';
// import { generateOtpEmailHtml } from '../utils/emailTemplate.js';
// import bcrypt from 'bcryptjs';
// import jwt from 'jsonwebtoken';
// import emailQueue from '../queues/queue.js';
// // import admin from '../config/firebaseAdmin.js'; 

// const generateOTP = () => Math.floor(100000 + Math.random() * 900000).toString();

// // ==========================================
// // CACHING & SESSION HELPERS
// // ==========================================

// const createSession = async (user, deviceId) => {
//     const accessToken = jwt.sign(
//         { id: user._id, role: user.role },
//         process.env.JWT_SECRET,
//         { expiresIn: '15m' }
//     );
//     const refreshToken = jwt.sign(
//         { id: user._id },
//         process.env.REFRESH_SECRET,
//         { expiresIn: '7d' }
//     );

//     // Store refresh token mapped to specific device (7 days expiry)
//     await redis.set(`session:${user._id}:${deviceId}`, refreshToken, 'EX', 7 * 24 * 60 * 60);

//     return { accessToken, refreshToken };
// };

// // Helper: Cache Invalidation (Jab bhi Profile/Status change ho)
// export const clearUserCache = async (email) => {
//     await redis.del(`user:email:${email}`);
// };

// // Helper: Fetch cached user or fallback to MongoDB
// const getUserCache = async (email) => {
//     const cachedUser = await redis.get(`user:email:${email}`);
//     if (cachedUser) {
//         return JSON.parse(cachedUser);
//     }

//     const user = await User.findOne({ email }).lean();
//     if (user) {
//         // Sirf VERIFIED users ko 1 hour (3600s) cache karo, unverified ko fast-expire karo
//         const ttl = user.isVerified ? 3600 : 300;
//         await redis.set(`user:email:${email}`, JSON.stringify(user), 'EX', ttl);
//     }
//     return user;
// };


// // ==========================================
// // CONTROLLERS
// // ==========================================

// // 1. REGISTER (Local)
// export const registerUser = async (req, res) => {
//     try {
//         const { name, email, password, role } = req.body;

//         let user = await getUserCache(email);

//         if (user && user.isVerified) {
//             return res.status(400).json({ success: false, message: 'User already exists' });
//         }

//         if (!user) {
//             const newUser = await User.create({ name, email, password, role, authProvider: 'local' });
//             user = newUser.toObject();
//         }

//         const otp = generateOTP();

//         // Pipeline: Clear stale user cache & set fresh OTP atomically
//         const pipeline = redis.pipeline();
//         pipeline.del(`user:email:${email}`); // Force cache reset for new OTP cycle
//         pipeline.set(`otp:${email}`, otp, 'EX', 300); // 5 mins OTP expiry
//         await pipeline.exec();

//         await emailQueue.add('sendOtpEmail', {
//             to: email,
//             subject: 'Your Verification Code',
//             html: generateOtpEmailHtml(otp)
//         });

//         return res.status(201).json({ success: true, message: 'OTP sent to email. Please verify.' });
//     } catch (error) {
//         console.log('Register Error:', error);
//         return res.status(500).json({ success: false, message: error.message });
//     }
// };

// // 2. VERIFY OTP
// export const verifyOTP = async (req, res) => {
//     try {
//         const { email, otp, deviceId } = req.body;

//         const cachedOtp = await redis.get(`otp:${email}`);
//         if (!cachedOtp || cachedOtp !== otp) {
//             return res.status(400).json({ success: false, message: 'Invalid or expired OTP' });
//         }

//         const user = await User.findOne({ email });
//         if (!user) return res.status(404).json({ success: false, message: 'User not found' });

//         user.isVerified = true;
//         await user.save();

//         // Clear OTP & reset fresh verified user cache
//         const updatedUser = user.toObject();

//         const pipeline = redis.pipeline();
//         pipeline.del(`otp:${email}`);
//         pipeline.set(`user:email:${email}`, JSON.stringify(updatedUser), 'EX', 3600); // 1 Hr cache
//         await pipeline.exec();

//         const tokens = await createSession(updatedUser, deviceId);

//         const { password: _, ...userWithoutPassword } = updatedUser;
//         res.status(200).json({ success: true, user: userWithoutPassword, ...tokens });
//     } catch (error) {
//         console.log('Verify Error:', error);
//         res.status(500).json({ success: false, message: error.message });
//     }
// };

// // 3. LOGIN (Local)
// export const loginUser = async (req, res) => {
//     try {
//         const { email, password, deviceId } = req.body;

//         const user = await getUserCache(email);
//         if (!user) return res.status(404).json({ success: false, message: 'User not found' });

//         if (user.authProvider === 'google') {
//             return res.status(400).json({ success: false, message: 'Please login using Google' });
//         }

//         const isMatch = await bcrypt.compare(password, user.password);
//         if (!isMatch) return res.status(401).json({ success: false, message: 'Invalid credentials' });

//         if (!user.isVerified) {
//             return res.status(401).json({ success: false, message: 'Please verify your email first' });
//         }

//         const tokens = await createSession(user, deviceId);
//         const { password: _, ...userWithoutPassword } = user;

//         res.status(200).json({ success: true, user: userWithoutPassword, ...tokens });
//     } catch (error) {
//         console.log('Login Error:', error);
//         res.status(500).json({ success: false, message: error.message });
//     }
// };

// // 4. REFRESH TOKEN (Naya Access Token lene ke liye)
// export const refreshToken = async (req, res) => {
//     try {
//         const { userId, deviceId, refreshToken } = req.body;

//         if (!refreshToken) return res.status(401).json({ success: false, message: 'Refresh Token required' });

//         // Redis se device session verify karo
//         const savedToken = await redis.get(`session:${userId}:${deviceId}`);
//         if (!savedToken || savedToken !== refreshToken) {
//             return res.status(403).json({ success: false, message: 'Invalid or expired refresh token. Please login again.' });
//         }

//         // Token verify karo
//         const decoded = jwt.verify(refreshToken, process.env.REFRESH_SECRET);

//         // Generate NEW Access Token
//         const newAccessToken = jwt.sign(
//             { id: decoded.id },
//             process.env.JWT_SECRET,
//             { expiresIn: '15m' }
//         );

//         res.status(200).json({ success: true, accessToken: newAccessToken });
//     } catch (error) {
//         console.log('Refresh Token Error:', error);
//         res.status(403).json({ success: false, message: 'Invalid session' });
//     }
// };

// // 5. GOOGLE AUTH
// export const googleLogin = async (req, res) => {
//     try {
//         const { idToken, role, deviceId } = req.body;

//         // const decodedToken = await admin.auth().verifyIdToken(idToken);
//         // const { email, name } = decodedToken; 

//         const email = "user@example.com";
//         const name = "Google User";

//         let user = await getUserCache(email);

//         if (!user) {
//             const newUser = await User.create({
//                 name,
//                 email,
//                 role: role || 'customer',
//                 authProvider: 'google',
//                 isVerified: true
//             });
//             user = newUser.toObject();
//             await redis.set(`user:email:${email}`, JSON.stringify(user), 'EX', 3600);
//         }

//         const tokens = await createSession(user, deviceId);
//         const { password: _, ...userWithoutPassword } = user;

//         res.status(200).json({ success: true, user: userWithoutPassword, ...tokens });
//     } catch (error) {
//         console.log('Google Auth Error:', error);
//         res.status(500).json({ success: false, message: 'Google Auth Failed' });
//     }
// };

// // 6. FORGOT PASSWORD (OTP Trigger)
// export const forgotPassword = async (req, res) => {
//     try {
//         const { email } = req.body;
//         const user = await getUserCache(email);

//         if (!user) return res.status(404).json({ success: false, message: 'User not found' });
//         if (user.authProvider === 'google') return res.status(400).json({ success: false, message: 'Google accounts cannot reset password here' });

//         const otp = generateOTP();
//         await redis.set(`otp:${email}`, otp, 'EX', 300);

//         await emailQueue.add('sendOtpEmail', {
//             to: email,
//             subject: 'Password Reset Verification Code',
//             html: generateOtpEmailHtml(otp)
//         });

//         res.status(200).json({ success: true, message: 'Password reset OTP sent to email' });
//     } catch (error) {
//         console.log('Forgot Password Error:', error);
//         res.status(500).json({ success: false, message: error.message });
//     }
// };

// // 7. RESET PASSWORD (Using OTP)
// export const resetPassword = async (req, res) => {
//     try {
//         const { email, otp, newPassword } = req.body;

//         const cachedOtp = await redis.get(`otp:${email}`);
//         if (!cachedOtp || cachedOtp !== otp) {
//             return res.status(400).json({ success: false, message: 'Invalid or expired OTP' });
//         }

//         const user = await User.findOne({ email });
//         if (!user) return res.status(404).json({ success: false, message: 'User not found' });

//         // Update password (Mongoose pre hook will auto-hash it)
//         user.password = newPassword;
//         await user.save();

//         // Pipeline: Delete OTP and clear cached user so old password hash in Redis is cleared
//         const pipeline = redis.pipeline();
//         pipeline.del(`otp:${email}`);
//         pipeline.del(`user:email:${email}`);
//         await pipeline.exec();

//         res.status(200).json({ success: true, message: 'Password reset successful. Please login.' });
//     } catch (error) {
//         console.log('Reset Password Error:', error);
//         res.status(500).json({ success: false, message: error.message });
//     }
// };

// // 8. LOGOUT (Specific Device)
// export const logoutUser = async (req, res) => {
//     try {
//         const { userId, deviceId } = req.body;

//         await redis.del(`session:${userId}:${deviceId}`);

//         res.status(200).json({ success: true, message: 'Logged out successfully' });
//     } catch (error) {
//         console.log('Logout Error:', error);
//         res.status(500).json({ success: false, message: error.message });
//     }
// };




// import User from '../models/User.js';
// import redis from '../config/redis.js';
// import emailQueue from '../queues/emailQueue.js';
// import { generateOtpEmailHtml } from '../utils/emailTemplate.js';
// import bcrypt from 'bcryptjs';
// import jwt from 'jsonwebtoken';
// // import admin from '../config/firebaseAdmin.js'; // Firebase Admin SDK

// const generateOTP = () => Math.floor(100000 + Math.random() * 900000).toString();

// // ==========================================
// // CACHING & SESSION HELPERS
// // ==========================================

// // Helper: JWT Session generation (Compatible with both Redis plain objects & Mongoose docs)
// const createSession = async (user, deviceId) => {
//     const accessToken = jwt.sign(
//         { id: user._id, role: user.role },
//         process.env.JWT_SECRET,
//         { expiresIn: '15m' }
//     );
//     const refreshToken = jwt.sign(
//         { id: user._id },
//         process.env.REFRESH_SECRET,
//         { expiresIn: '7d' }
//     );

//     // Store refresh token mapped to specific device (7 days expiry)
//     await redis.set(`session:${user._id}:${deviceId}`, refreshToken, 'EX', 7 * 24 * 60 * 60);

//     return { accessToken, refreshToken };
// };

// // Helper: Get user from Redis Cache or DB
// const getUserCache = async (email) => {
//     const cachedUser = await redis.get(`user:email:${email}`);
//     if (cachedUser) {
//         return JSON.parse(cachedUser); // Return fast from Redis
//     }

//     // .lean() returns plain JS object instead of heavy Mongoose doc, making it faster
//     const user = await User.findOne({ email }).lean();
//     if (user) {
//         // Cache user data for 1 hour (3600 seconds)
//         await redis.set(`user:email:${email}`, JSON.stringify(user), 'EX', 3600);
//     }
//     return user;
// };

// // Helper: Clear specific user cache (Used when data updates like verification)
// const clearUserCache = async (email) => {
//     await redis.del(`user:email:${email}`);
// };


// // ==========================================
// // CONTROLLERS
// // ==========================================

// // 1. REGISTER (Local) -> Only sends OTP
// export const registerUser = async (req, res) => {
//     try {
//         const { name, email, password, role } = req.body;

//         let user = await getUserCache(email);

//         if (user && user.isVerified) {
//             return res.status(400).json({ success: false, message: 'User already exists' });
//         }

//         if (!user) {
//             // Mongoose pre-save hook will hash the password
//             const newUser = await User.create({ name, email, password, role, authProvider: 'local' });
//             // Cache the newly created unverified user
//             await redis.set(`user:email:${email}`, JSON.stringify(newUser.toObject()), 'EX', 3600);
//         }

//         const otp = generateOTP();
//         await redis.set(`otp:${email}`, otp, 'EX', 300); // 5 mins expiry

//         await emailQueue.add('sendOtpEmail', {
//             to: email,
//             subject: 'Your Verification Code',
//             html: generateOtpEmailHtml(otp)
//         });

//         res.status(201).json({ success: true, message: 'OTP sent to email. Please verify.' });
//     } catch (error) {
//         res.status(500).json({ success: false, message: error.message });
//     }
// };

// // 2. VERIFY OTP
// export const verifyOTP = async (req, res) => {
//     try {
//         const { email, otp, deviceId } = req.body;

//         const cachedOtp = await redis.get(`otp:${email}`);
//         if (!cachedOtp || cachedOtp !== otp) {
//             return res.status(400).json({ success: false, message: 'Invalid or expired OTP' });
//         }

//         // Must fetch from DB to update and save
//         const user = await User.findOne({ email });
//         if (!user) return res.status(404).json({ success: false, message: 'User not found' });

//         user.isVerified = true;
//         await user.save();

//         // Clean up OTP and refresh the User Cache
//         await redis.del(`otp:${email}`);
//         await redis.set(`user:email:${email}`, JSON.stringify(user.toObject()), 'EX', 3600);

//         const tokens = await createSession(user, deviceId);
//         res.status(200).json({ success: true, user, ...tokens });
//     } catch (error) {
//         res.status(500).json({ success: false, message: error.message });
//     }
// };

// // 3. LOGIN (Local) - Highly Optimized
// export const loginUser = async (req, res) => {
//     try {
//         const { email, password, deviceId } = req.body;

//         // Try getting from Redis first
//         const user = await getUserCache(email);
//         if (!user) return res.status(404).json({ success: false, message: 'User not found' });

//         if (user.authProvider === 'google') {
//             return res.status(400).json({ success: false, message: 'Please login using Google' });
//         }

//         // Direct bcrypt compare works perfectly with Redis plain objects
//         const isMatch = await bcrypt.compare(password, user.password);
//         if (!isMatch) return res.status(401).json({ success: false, message: 'Invalid credentials' });

//         if (!user.isVerified) {
//             return res.status(401).json({ success: false, message: 'Please verify your email first' });
//         }

//         const tokens = await createSession(user, deviceId);

//         // Exclude password from the response object
//         const { password: _, ...userWithoutPassword } = user;
//         res.status(200).json({ success: true, user: userWithoutPassword, ...tokens });
//     } catch (error) {
//         res.status(500).json({ success: false, message: error.message });
//     }
// };

// // 4. GOOGLE AUTH (Firebase Verify)
// export const googleLogin = async (req, res) => {
//     try {
//         const { idToken, role, deviceId } = req.body;

//         // const decodedToken = await admin.auth().verifyIdToken(idToken);
//         // const { email, name } = decodedToken; 

//         const email = "user@example.com";
//         const name = "Google User";

//         let user = await getUserCache(email);

//         if (!user) {
//             const newUser = await User.create({
//                 name,
//                 email,
//                 role: role || 'customer',
//                 authProvider: 'google',
//                 isVerified: true
//             });
//             user = newUser.toObject();
//             await redis.set(`user:email:${email}`, JSON.stringify(user), 'EX', 3600);
//         }

//         const tokens = await createSession(user, deviceId);
//         res.status(200).json({ success: true, user, ...tokens });
//     } catch (error) {
//         res.status(500).json({ success: false, message: 'Google Auth Failed' });
//     }
// };

// // 5. FORGOT PASSWORD
// export const forgotPassword = async (req, res) => {
//     try {
//         const { email } = req.body;

//         // Fast DB bypass using Cache
//         const user = await getUserCache(email);

//         if (!user) return res.status(404).json({ success: false, message: 'User not found' });
//         if (user.authProvider === 'google') return res.status(400).json({ success: false, message: 'Google accounts cannot reset password here' });

//         const otp = generateOTP();
//         await redis.set(`otp:${email}`, otp, 'EX', 300);

//         await emailQueue.add('sendOtpEmail', {
//             to: email,
//             subject: 'Password Reset Verification Code',
//             html: generateOtpEmailHtml(otp)
//         });

//         res.status(200).json({ success: true, message: 'Password reset OTP sent to email' });
//     } catch (error) {
//         res.status(500).json({ success: false, message: error.message });
//     }
// };

// // 6. LOGOUT
// export const logoutUser = async (req, res) => {
//     try {
//         const { userId, deviceId } = req.body;

//         // Remove specific device session
//         await redis.del(`session:${userId}:${deviceId}`);

//         res.status(200).json({ success: true, message: 'Logged out successfully' });
//     } catch (error) {
//         res.status(500).json({ success: false, message: error.message });
//     }
// };