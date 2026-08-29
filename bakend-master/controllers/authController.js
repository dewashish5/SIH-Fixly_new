import User from '../models/User.js';
import redis from '../config/redis.js';
import { generateOtpEmailHtml } from '../utils/emailTemplate.js';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import emailQueue from '../queues/queue.js';

const generateOTP = () => Math.floor(100000 + Math.random() * 900000).toString();
const REDIS_VERIFIED_TTL = 86400; // 24 Hours Cache TTL

// ==========================================
// SINGLE-DEVICE SESSION HELPER
// ==========================================
const createSession = async (user, deviceId) => {
    const userIdStr = user._id ? user._id.toString() : user.id;

    const accessToken = jwt.sign(
        { id: userIdStr, role: user.role },
        process.env.JWT_SECRET,
        { expiresIn: '15m' }
    );
    const refreshToken = jwt.sign(
        { id: userIdStr },
        process.env.REFRESH_SECRET,
        { expiresIn: '7d' }
    );

    if (deviceId) {
        const activeDeviceKey = `user:active-device:${userIdStr}`;
        const oldDeviceId = await redis.get(activeDeviceKey);

        if (oldDeviceId && oldDeviceId !== deviceId) {
            await redis.del(`session:${userIdStr}:${oldDeviceId}`);
        }

        const pipeline = redis.pipeline();
        pipeline.set(activeDeviceKey, deviceId, 'EX', 7 * 24 * 60 * 60);
        pipeline.set(`session:${userIdStr}:${deviceId}`, refreshToken, 'EX', 7 * 24 * 60 * 60);
        await pipeline.exec();
    }

    return { accessToken, refreshToken };
};

// User object se password strip karke Redis me cache karna
export const syncUserCache = async (email, userData) => {
    const { password, ...safeUser } = userData;
    const ttl = safeUser.isVerified ? REDIS_VERIFIED_TTL : 300;
    await redis.set(`user:email:${email}`, JSON.stringify(safeUser), 'EX', ttl);
};

// Cache Reader Helper
const getUserCache = async (email) => {
    const cachedUser = await redis.get(`user:email:${email}`);
    if (cachedUser) return JSON.parse(cachedUser);

    const user = await User.findOne({ email }).select('-password').lean();
    if (user) {
        await syncUserCache(email, user);
    }
    return user;
};

// ==========================================
// CONTROLLERS
// ==========================================

// Get Current Logged-in User Profile
export const getMe = async (req, res) => {
    try {
        // req.user.id auth middleware se aayega jo token decode karta hai
        const user = await User.findById(req.user.id).select('-password');

        if (!user) {
            return res.status(404).json({ success: false, message: 'User not found' });
        }

        res.status(200).json({
            success: true,
            user
        });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};


// 1. REGISTER (FIXED: Explicit Bcrypt Password Hashing)
export const registerUser = async (req, res) => {
    try {
        const { name, email, password, role, phone, location, workerProfile } = req.body;

        const existingUser = await getUserCache(email);
        if (existingUser && existingUser.isVerified) {
            return res.status(400).json({ success: false, message: 'User already exists' });
        }

        // Fix: Explicitly Hash Password before saving
        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash(password, salt);

        const userPayload = {
            name,
            email,
            password: hashedPassword,
            role: role || 'customer',
            authProvider: 'local',
            phone: phone || null,
            location: location || undefined,
            workerProfile: role === 'worker' ? workerProfile || {} : null
        };

        let userDoc;
        if (!existingUser) {
            userDoc = await User.create(userPayload);
        } else {
            userDoc = await User.findOne({ email });
            Object.assign(userDoc, userPayload);
            await userDoc.save();
        }

        const otp = generateOTP();
        const pipeline = redis.pipeline();
        pipeline.del(`user:email:${email}`);
        pipeline.set(`otp:${email}`, otp, 'EX', 300);
        await pipeline.exec();

        await emailQueue.add('sendOtpEmail', {
            to: email,
            subject: 'Your Verification Code',
            html: generateOtpEmailHtml(otp)
        });

        return res.status(201).json({
            success: true,
            message: 'OTP sent to email. Please verify.',
            userId: userDoc._id
        });
    } catch (error) {
        console.error('Register Error:', error);
        return res.status(500).json({ success: false, message: error.message });
    }
};

// 2. VERIFY REGISTRATION OTP
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

        const userObj = user.toObject();
        delete userObj.password;

        const pipeline = redis.pipeline();
        pipeline.del(`otp:${email}`);
        await pipeline.exec();

        await syncUserCache(email, userObj);
        const tokens = await createSession(userObj, deviceId);

        return res.status(200).json({
            success: true,
            message: 'Email verified successfully',
            user: userObj,
            ...tokens
        });
    } catch (error) {
        console.error('Verify OTP Error:', error);
        return res.status(500).json({ success: false, message: error.message });
    }
};

// 3. LOGIN
export const loginUser = async (req, res) => {
    try {
        const { email, password, deviceId, location, phone } = req.body;

        const user = await User.findOne({ email }).select('+password');
        if (!user) return res.status(404).json({ success: false, message: 'User not found' });

        if (user.authProvider === 'google') {
            return res.status(400).json({ success: false, message: 'Please login using Google' });
        }

        const isMatch = await bcrypt.compare(password, user.password);
        if (!isMatch) {
            return res.status(401).json({ success: false, message: 'Invalid credentials' });
        }

        if (!user.isVerified) {
            return res.status(401).json({ success: false, message: 'Please verify your email first' });
        }

        let isModified = false;
        if (location) {
            user.location = location;
            isModified = true;
        }
        if (phone && !user.phone) {
            user.phone = phone;
            isModified = true;
        }

        if (isModified) {
            await user.save();
        }

        const userObj = user.toObject();
        delete userObj.password;

        await syncUserCache(email, userObj);
        const tokens = await createSession(userObj, deviceId);

        return res.status(200).json({
            success: true,
            user: userObj,
            ...tokens
        });
    } catch (error) {
        console.error('Login Error:', error);
        return res.status(500).json({ success: false, message: error.message });
    }
};

// 4. DYNAMIC PROFILE UPDATE
export const updateUserProfile = async (req, res) => {
    try {
        const userId = req.user.id;
        const updates = req.body;

        delete updates.password;
        delete updates.email;

        const updatedUser = await User.findByIdAndUpdate(
            userId,
            { $set: updates },
            { new: true, runValidators: true }
        ).select('-password').lean();

        if (!updatedUser) return res.status(404).json({ success: false, message: 'User not found' });

        await syncUserCache(updatedUser.email, updatedUser);

        return res.status(200).json({
            success: true,
            message: 'Profile updated successfully',
            user: updatedUser
        });
    } catch (error) {
        console.error('Update Profile Error:', error);
        return res.status(500).json({ success: false, message: error.message });
    }
};

// 5. GOOGLE AUTH
export const googleLogin = async (req, res) => {
    try {
        const { email, name, avatar, role, deviceId, location } = req.body;

        let userDoc = await User.findOne({ email }).select('-password');

        if (!userDoc) {
            userDoc = await User.create({
                name,
                email,
                avatar: avatar || null,
                role: role || 'customer',
                authProvider: 'google',
                isVerified: true,
                location: location || undefined
            });
        }

        const user = userDoc.toObject ? userDoc.toObject() : userDoc;
        delete user.password;

        await syncUserCache(email, user);
        const tokens = await createSession(user, deviceId);

        return res.status(200).json({ success: true, user, ...tokens });
    } catch (error) {
        console.error('Google Auth Error:', error);
        return res.status(500).json({ success: false, message: 'Google Auth Failed' });
    }
};

// 6. REFRESH TOKEN (FIXED: Includes user role in new access token)
export const refreshToken = async (req, res) => {
    try {
        const { userId, deviceId, refreshToken } = req.body;

        if (!refreshToken) return res.status(401).json({ success: false, message: 'Refresh Token required' });

        const savedToken = await redis.get(`session:${userId}:${deviceId}`);
        if (!savedToken || savedToken !== refreshToken) {
            return res.status(403).json({ success: false, message: 'Invalid or expired session. Please login again.' });
        }

        const decoded = jwt.verify(refreshToken, process.env.REFRESH_SECRET);

        // Fetch user from DB/Cache to ensure active role is present
        const user = await User.findById(decoded.id).select('role').lean();
        if (!user) return res.status(404).json({ success: false, message: 'User no longer exists' });

        const newAccessToken = jwt.sign(
            { id: decoded.id, role: user.role },
            process.env.JWT_SECRET,
            { expiresIn: '15m' }
        );

        return res.status(200).json({ success: true, accessToken: newAccessToken });
    } catch (error) {
        console.error('Refresh Token Error:', error);
        return res.status(403).json({ success: false, message: 'Invalid session' });
    }
};

// 7. FORGOT PASSWORD
export const forgotPassword = async (req, res) => {
    try {
        const { email } = req.body;
        const user = await User.findOne({ email });

        if (!user) return res.status(404).json({ success: false, message: 'Is email se koi account nahi milaa' });
        if (user.authProvider === 'google') return res.status(400).json({ success: false, message: 'Google accounts cannot reset password here' });

        const otp = generateOTP();
        await redis.set(`reset_otp:${email}`, otp, 'EX', 300);

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

// 8. RESET PASSWORD
export const resetPassword = async (req, res) => {
    try {
        const { email, otp, newPassword } = req.body;

        if (!email || !otp || !newPassword) {
            return res.status(400).json({ success: false, message: 'Email, OTP aur Naya Password required hain' });
        }

        const cachedOtp = await redis.get(`reset_otp:${email}`);
        if (!cachedOtp || cachedOtp !== otp) {
            return res.status(400).json({ success: false, message: 'Invalid ya expired OTP' });
        }

        const user = await User.findOne({ email });
        if (!user) return res.status(404).json({ success: false, message: 'User not found' });

        const salt = await bcrypt.genSalt(10);
        user.password = await bcrypt.hash(newPassword, salt);
        await user.save();

        const pipeline = redis.pipeline();
        pipeline.del(`reset_otp:${email}`);
        pipeline.del(`user:email:${email}`);
        await pipeline.exec();

        return res.status(200).json({ success: true, message: 'Password reset successful. Please login.' });
    } catch (error) {
        console.error('Reset Password Error:', error);
        return res.status(500).json({ success: false, message: error.message });
    }
};

// 9. LOGOUT
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

// const generateOTP = () => Math.floor(100000 + Math.random() * 900000).toString();
// const REDIS_VERIFIED_TTL = 86400; // 24 Hours Cache TTL

// // ==========================================
// // SINGLE-DEVICE SESSION HELPER
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

//     if (deviceId) {
//         const activeDeviceKey = `user:active-device:${user._id}`;
//         const oldDeviceId = await redis.get(activeDeviceKey);

//         if (oldDeviceId && oldDeviceId !== deviceId) {
//             await redis.del(`session:${user._id}:${oldDeviceId}`);
//         }

//         const pipeline = redis.pipeline();
//         pipeline.set(activeDeviceKey, deviceId, 'EX', 7 * 24 * 60 * 60);
//         pipeline.set(`session:${user._id}:${deviceId}`, refreshToken, 'EX', 7 * 24 * 60 * 60);
//         await pipeline.exec();
//     }

//     return { accessToken, refreshToken };
// };

// // User object se password strip karke Redis me cache karna
// export const syncUserCache = async (email, userData) => {
//     const { password, ...safeUser } = userData;
//     const ttl = safeUser.isVerified ? REDIS_VERIFIED_TTL : 300;
//     await redis.set(`user:email:${email}`, JSON.stringify(safeUser), 'EX', ttl);
// };

// // Cache Reader Helper
// const getUserCache = async (email) => {
//     const cachedUser = await redis.get(`user:email:${email}`);
//     if (cachedUser) return JSON.parse(cachedUser);

//     const user = await User.findOne({ email }).select('-password').lean();
//     if (user) {
//         await syncUserCache(email, user);
//     }
//     return user;
// };

// // ==========================================
// // CONTROLLERS
// // ==========================================

// // 1. REGISTER
// export const registerUser = async (req, res) => {
//     try {
//         const { name, email, password, role, phone, location, workerProfile } = req.body;

//         const existingUser = await getUserCache(email);
//         if (existingUser && existingUser.isVerified) {
//             return res.status(400).json({ success: false, message: 'User already exists' });
//         }

//         const userPayload = {
//             name,
//             email,
//             password,
//             role: role || 'customer',
//             authProvider: 'local',
//             phone: phone || null,
//             location: location || undefined,
//             workerProfile: role === 'worker' ? workerProfile || {} : null
//         };

//         let userDoc;
//         if (!existingUser) {
//             userDoc = await User.create(userPayload);
//         } else {
//             userDoc = await User.findOne({ email });
//             Object.assign(userDoc, userPayload);
//             await userDoc.save();
//         }

//         const otp = generateOTP();
//         const pipeline = redis.pipeline();
//         pipeline.del(`user:email:${email}`);
//         pipeline.set(`otp:${email}`, otp, 'EX', 300); // 5 Mins Registration OTP
//         await pipeline.exec();

//         await emailQueue.add('sendOtpEmail', {
//             to: email,
//             subject: 'Your Verification Code',
//             html: generateOtpEmailHtml(otp)
//         });

//         return res.status(201).json({
//             success: true,
//             message: 'OTP sent to email. Please verify.',
//             userId: userDoc._id
//         });
//     } catch (error) {
//         console.error('Register Error:', error);
//         return res.status(500).json({ success: false, message: error.message });
//     }
// };

// // 2. VERIFY REGISTRATION OTP
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

//         const userObj = user.toObject();
//         delete userObj.password;

//         const pipeline = redis.pipeline();
//         pipeline.del(`otp:${email}`);
//         await pipeline.exec();

//         await syncUserCache(email, userObj);
//         const tokens = await createSession(userObj, deviceId);

//         return res.status(200).json({
//             success: true,
//             message: 'Email verified successfully',
//             user: userObj,
//             ...tokens
//         });
//     } catch (error) {
//         console.error('Verify OTP Error:', error);
//         return res.status(500).json({ success: false, message: error.message });
//     }
// };

// // 3. LOGIN (bcrypt.compare Check)
// export const loginUser = async (req, res) => {
//     try {
//         const { email, password, deviceId, location, phone } = req.body;

//         const user = await User.findOne({ email }).select('+password');
//         if (!user) return res.status(404).json({ success: false, message: 'User not found' });

//         if (user.authProvider === 'google') {
//             return res.status(400).json({ success: false, message: 'Please login using Google' });
//         }

//         const isMatch = await bcrypt.compare(password, user.password);
//         if (!isMatch) {
//             return res.status(401).json({ success: false, message: 'Invalid credentials' });
//         }

//         if (!user.isVerified) {
//             return res.status(401).json({ success: false, message: 'Please verify your email first' });
//         }

//         let isModified = false;
//         if (location) {
//             user.location = location;
//             isModified = true;
//         }
//         if (phone && !user.phone) {
//             user.phone = phone;
//             isModified = true;
//         }

//         if (isModified) {
//             await user.save();
//         }

//         const userObj = user.toObject();
//         delete userObj.password;

//         await syncUserCache(email, userObj);
//         const tokens = await createSession(userObj, deviceId);

//         return res.status(200).json({
//             success: true,
//             user: userObj,
//             ...tokens
//         });
//     } catch (error) {
//         console.error('Login Error:', error);
//         return res.status(500).json({ success: false, message: error.message });
//     }
// };

// // 4. DYNAMIC PROFILE UPDATE
// export const updateUserProfile = async (req, res) => {
//     try {
//         const userId = req.user.id;
//         const updates = req.body;

//         delete updates.password;
//         delete updates.email;

//         const updatedUser = await User.findByIdAndUpdate(
//             userId,
//             { $set: updates },
//             { new: true, runValidators: true }
//         ).select('-password').lean();

//         if (!updatedUser) return res.status(404).json({ success: false, message: 'User not found' });

//         await syncUserCache(updatedUser.email, updatedUser);

//         return res.status(200).json({
//             success: true,
//             message: 'Profile updated successfully',
//             user: updatedUser
//         });
//     } catch (error) {
//         console.error('Update Profile Error:', error);
//         return res.status(500).json({ success: false, message: error.message });
//     }
// };

// // 5. GOOGLE AUTH
// export const googleLogin = async (req, res) => {
//     try {
//         const { email, name, avatar, role, deviceId, location } = req.body;

//         let user = await User.findOne({ email }).select('-password');

//         if (!user) {
//             user = await User.create({
//                 name,
//                 email,
//                 avatar: avatar || null,
//                 role: role || 'customer',
//                 authProvider: 'google',
//                 isVerified: true,
//                 location: location || undefined
//             });
//             user = user.toObject();
//             delete user.password;
//         } else {
//             user = user.toObject();
//         }

//         await syncUserCache(email, user);
//         const tokens = await createSession(user, deviceId);

//         return res.status(200).json({ success: true, user, ...tokens });
//     } catch (error) {
//         console.error('Google Auth Error:', error);
//         return res.status(500).json({ success: false, message: 'Google Auth Failed' });
//     }
// };

// // 6. REFRESH TOKEN
// export const refreshToken = async (req, res) => {
//     try {
//         const { userId, deviceId, refreshToken } = req.body;

//         if (!refreshToken) return res.status(401).json({ success: false, message: 'Refresh Token required' });

//         const savedToken = await redis.get(`session:${userId}:${deviceId}`);
//         if (!savedToken || savedToken !== refreshToken) {
//             return res.status(403).json({ success: false, message: 'Invalid or expired session. Please login again.' });
//         }

//         const decoded = jwt.verify(refreshToken, process.env.REFRESH_SECRET);

//         const newAccessToken = jwt.sign(
//             { id: decoded.id },
//             process.env.JWT_SECRET,
//             { expiresIn: '15m' }
//         );

//         return res.status(200).json({ success: true, accessToken: newAccessToken });
//     } catch (error) {
//         console.error('Refresh Token Error:', error);
//         return res.status(403).json({ success: false, message: 'Invalid session' });
//     }
// };

// // 7. STEP 1: FORGOT PASSWORD (OTP Generate & Email Send)
// export const forgotPassword = async (req, res) => {
//     try {
//         const { email } = req.body;
//         const user = await User.findOne({ email });

//         if (!user) return res.status(404).json({ success: false, message: 'Is email se koi account nahi milaa' });
//         if (user.authProvider === 'google') return res.status(400).json({ success: false, message: 'Google accounts cannot reset password here' });

//         const otp = generateOTP();
//         await redis.set(`reset_otp:${email}`, otp, 'EX', 300); // 5 mins OTP validity

//         await emailQueue.add('sendOtpEmail', {
//             to: email,
//             subject: 'Password Reset Verification Code',
//             html: generateOtpEmailHtml(otp)
//         });

//         return res.status(200).json({ success: true, message: 'Password reset OTP sent to email' });
//     } catch (error) {
//         console.error('Forgot Password Error:', error);
//         return res.status(500).json({ success: false, message: error.message });
//     }
// };

// // 8. STEP 2: RESET PASSWORD (Verify OTP & Update Password)
// export const resetPassword = async (req, res) => {
//     try {
//         const { email, otp, newPassword } = req.body;

//         if (!email || !otp || !newPassword) {
//             return res.status(400).json({ success: false, message: 'Email, OTP aur Naya Password required hain' });
//         }

//         // Redis se OTP compare karein
//         const cachedOtp = await redis.get(`reset_otp:${email}`);
//         if (!cachedOtp || cachedOtp !== otp) {
//             return res.status(400).json({ success: false, message: 'Invalid ya expired OTP' });
//         }

//         const user = await User.findOne({ email });
//         if (!user) return res.status(404).json({ success: false, message: 'User not found' });

//         // Password Hash aur Update
//         const salt = await bcrypt.genSalt(10);
//         user.password = await bcrypt.hash(newPassword, salt);
//         await user.save();

//         // Expired OTP aur stale cache clear
//         const pipeline = redis.pipeline();
//         pipeline.del(`reset_otp:${email}`);
//         pipeline.del(`user:email:${email}`);
//         await pipeline.exec();

//         return res.status(200).json({ success: true, message: 'Password reset successful. Please login.' });
//     } catch (error) {
//         console.error('Reset Password Error:', error);
//         return res.status(500).json({ success: false, message: error.message });
//     }
// };

// // 9. LOGOUT
// export const logoutUser = async (req, res) => {
//     try {
//         const { userId, deviceId } = req.body;

//         const pipeline = redis.pipeline();
//         pipeline.del(`session:${userId}:${deviceId}`);
//         pipeline.del(`user:active-device:${userId}`);
//         await pipeline.exec();

//         return res.status(200).json({ success: true, message: 'Logged out successfully' });
//     } catch (error) {
//         console.error('Logout Error:', error);
//         return res.status(500).json({ success: false, message: error.message });
//     }
// };



// import User from '../models/User.js';
// import redis from '../config/redis.js';
// import { generateOtpEmailHtml } from '../utils/emailTemplate.js';
// import bcrypt from 'bcryptjs';
// import jwt from 'jsonwebtoken';
// import emailQueue from '../queues/queue.js';

// const generateOTP = () => Math.floor(100000 + Math.random() * 900000).toString();

// // ==========================================
// // SINGLE-DEVICE SESSION HELPER
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

//     // 1. Check karein ki is user ka pehle se koi active device registered hai ya nahi
//     const activeDeviceKey = `user:active-device:${user._id}`;
//     const oldDeviceId = await redis.get(activeDeviceKey);

//     // 2. Agar purana device tha aur wo naye device se alag hai, toh purana session delete kar do (Single-Device Enforcement)
//     if (oldDeviceId && oldDeviceId !== deviceId) {
//         await redis.del(`session:${user._id}:${oldDeviceId}`);
//     }

//     // 3. Pipeline ke through active device aur naya refresh token atomically set karein
//     const pipeline = redis.pipeline();
//     pipeline.set(activeDeviceKey, deviceId, 'EX', 7 * 24 * 60 * 60);
//     pipeline.set(`session:${user._id}:${deviceId}`, refreshToken, 'EX', 7 * 24 * 60 * 60);
//     await pipeline.exec();

//     return { accessToken, refreshToken };
// };

// // Helper: Cache Invalidation
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
//         pipeline.del(`user:email:${email}`);
//         pipeline.set(`otp:${email}`, otp, 'EX', 300); // 5 mins OTP expiry
//         await pipeline.exec();

//         await emailQueue.add('sendOtpEmail', {
//             to: email,
//             subject: 'Your Verification Code',
//             html: generateOtpEmailHtml(otp)
//         });

//         return res.status(201).json({ success: true, message: 'OTP sent to email. Please verify.' });
//     } catch (error) {
//         console.error('Register Error:', error);
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

//         const updatedUser = user.toObject();

//         // Pipeline: Delete OTP and update verified user cache atomically
//         const pipeline = redis.pipeline();
//         pipeline.del(`otp:${email}`);
//         pipeline.set(`user:email:${email}`, JSON.stringify(updatedUser), 'EX', 3600);
//         await pipeline.exec();

//         const tokens = await createSession(updatedUser, deviceId);

//         const { password: _, ...userWithoutPassword } = updatedUser;
//         return res.status(200).json({ success: true, user: userWithoutPassword, ...tokens });
//     } catch (error) {
//         console.error('Verify OTP Error:', error);
//         return res.status(500).json({ success: false, message: error.message });
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

//         return res.status(200).json({ success: true, user: userWithoutPassword, ...tokens });
//     } catch (error) {
//         console.error('Login Error:', error);
//         return res.status(500).json({ success: false, message: error.message });
//     }
// };

// // 4. REFRESH TOKEN
// export const refreshToken = async (req, res) => {
//     try {
//         const { userId, deviceId, refreshToken } = req.body;

//         if (!refreshToken) return res.status(401).json({ success: false, message: 'Refresh Token required' });

//         const savedToken = await redis.get(`session:${userId}:${deviceId}`);
//         if (!savedToken || savedToken !== refreshToken) {
//             return res.status(403).json({ success: false, message: 'Invalid or expired refresh token. Please login again.' });
//         }

//         const decoded = jwt.verify(refreshToken, process.env.REFRESH_SECRET);

//         const newAccessToken = jwt.sign(
//             { id: decoded.id },
//             process.env.JWT_SECRET,
//             { expiresIn: '15m' }
//         );

//         return res.status(200).json({ success: true, accessToken: newAccessToken });
//     } catch (error) {
//         console.error('Refresh Token Error:', error);
//         return res.status(403).json({ success: false, message: 'Invalid session' });
//     }
// };

// // 5. GOOGLE AUTH
// export const googleLogin = async (req, res) => {
//     try {
//         const { role, deviceId } = req.body;

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

//         return res.status(200).json({ success: true, user: userWithoutPassword, ...tokens });
//     } catch (error) {
//         console.error('Google Auth Error:', error);
//         return res.status(500).json({ success: false, message: 'Google Auth Failed' });
//     }
// };

// // 6. FORGOT PASSWORD
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

//         return res.status(200).json({ success: true, message: 'Password reset OTP sent to email' });
//     } catch (error) {
//         console.error('Forgot Password Error:', error);
//         return res.status(500).json({ success: false, message: error.message });
//     }
// };

// // 7. RESET PASSWORD
// export const resetPassword = async (req, res) => {
//     try {
//         const { email, otp, newPassword } = req.body;

//         const cachedOtp = await redis.get(`otp:${email}`);
//         if (!cachedOtp || cachedOtp !== otp) {
//             return res.status(400).json({ success: false, message: 'Invalid or expired OTP' });
//         }

//         const user = await User.findOne({ email });
//         if (!user) return res.status(404).json({ success: false, message: 'User not found' });

//         user.password = newPassword;
//         await user.save();

//         const pipeline = redis.pipeline();
//         pipeline.del(`otp:${email}`);
//         pipeline.del(`user:email:${email}`);
//         await pipeline.exec();

//         return res.status(200).json({ success: true, message: 'Password reset successful. Please login.' });
//     } catch (error) {
//         console.error('Reset Password Error:', error);
//         return res.status(500).json({ success: false, message: error.message });
//     }
// };

// // 8. LOGOUT
// export const logoutUser = async (req, res) => {
//     try {
//         const { userId, deviceId } = req.body;

//         const pipeline = redis.pipeline();
//         pipeline.del(`session:${userId}:${deviceId}`);
//         pipeline.del(`user:active-device:${userId}`);
//         await pipeline.exec();

//         return res.status(200).json({ success: true, message: 'Logged out successfully' });
//     } catch (error) {
//         console.error('Logout Error:', error);
//         return res.status(500).json({ success: false, message: error.message });
//     }
// };