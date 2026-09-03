import dotenv from 'dotenv';
dotenv.config();

import User from '../models/User.js';
import redis from '../config/redis.js';
import { uploadDataUriOrUrl } from '../utils/cloudinary.js';

// Screen 7: Get GeoJSON Nearby Workers with Embedded workerProfile
export const getNearbyWorkers = async (req, res) => {
    try {
        const defaultRadius = process.env.WORKER_SEARCH_RADIUS_KM || 10;
        const { lng, lat, category, sortBy = 'nearest', radiusInKm = defaultRadius } = req.query;

        if (!lng || !lat) {
            return res.status(400).json({ success: false, message: 'Coordinates (lng, lat) mandatory hain' });
        }

        const longitude = parseFloat(lng);
        const latitude = parseFloat(lat);
        const searchRadius = parseInt(radiusInKm, 10);

        // Base Filter: Only active workers with setup profiles
        const queryFilter = {
            role: 'worker',
            isVerified: true,
            workerProfile: { $ne: null },
            location: {
                $near: {
                    $geometry: { type: 'Point', coordinates: [longitude, latitude] },
                    $maxDistance: searchRadius * 1000
                }
            }
        };

        // Optional Category Filter
        if (category) {
            queryFilter['workerProfile.category'] = category;
        }

        // Sorting by nested workerProfile fields
        let sortOption = {};
        if (sortBy === 'top_rated') {
            sortOption = { 'workerProfile.rating': -1 };
        } else if (sortBy === 'jobs') {
            sortOption = { 'workerProfile.totalJobs': -1 };
        }

        const workers = await User.find(queryFilter)
            .select('-password -activeDeviceId')
            .sort(sortOption)
            .lean();

        return res.status(200).json({
            success: true,
            count: workers.length,
            searchRadiusKm: searchRadius,
            workers
        });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

// Screen 8: Worker Profile Details
export const getWorkerProfile = async (req, res) => {
    try {
        const { workerId } = req.params;
        const cacheKey = `worker:profile:${workerId}`;

        const cachedProfile = await redis.get(cacheKey);
        if (cachedProfile) {
            return res.status(200).json({ success: true, source: 'cache', worker: JSON.parse(cachedProfile) });
        }

        const ttl = parseInt(process.env.CACHE_TTL_WORKER_PROFILE, 10) || 600;

        const worker = await User.findOne({ _id: workerId, role: 'worker' })
            .select('-password -activeDeviceId')
            .lean();

        if (!worker || !worker.workerProfile) {
            return res.status(404).json({ success: false, message: 'Worker profile nahi milaa' });
        }

        await redis.set(cacheKey, JSON.stringify(worker), 'EX', ttl);

        return res.status(200).json({ success: true, source: 'db', worker });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

/**
 * PUT /api/workers/setup-profile
 * Flat body with data-URI / URL media fields → Cloudinary → nested workerProfile response.
 */
export const setupWorkerProfile = async (req, res) => {
    try {
        const userId = req.user.id;
        const body = req.body || {};

        const user = await User.findById(userId);
        if (!user) {
            return res.status(404).json({ success: false, message: 'User not found' });
        }

        const [
            avatarUrl,
            aadhaarFrontUrl,
            aadhaarBackUrl,
            panFrontUrl,
            panBackUrl,
        ] = await Promise.all([
            uploadDataUriOrUrl(body.avatar, 'gigconnect/avatars'),
            uploadDataUriOrUrl(body.aadhaarFrontPhoto, 'gigconnect/documents'),
            uploadDataUriOrUrl(body.aadhaarBackPhoto, 'gigconnect/documents'),
            uploadDataUriOrUrl(body.panFrontPhoto, 'gigconnect/documents'),
            uploadDataUriOrUrl(body.panBackPhoto, 'gigconnect/documents'),
        ]);

        const certInputs = Array.isArray(body.certifications) ? body.certifications : [];
        const certificationUrls = (
            await Promise.all(
                certInputs.map((c) => uploadDataUriOrUrl(c, 'gigconnect/certificates'))
            )
        ).filter(Boolean);

        if (body.name) user.name = String(body.name).trim();
        if (body.phone) user.phone = String(body.phone).trim();
        if (avatarUrl) user.avatar = avatarUrl;
        user.role = 'worker';
        // KYC pending until admin approves
        user.isVerified = false;
        if (user.isEmailVerified !== true && user.email) {
            // OTP-verified accounts already logged in — keep email verified flag
            user.isEmailVerified = true;
        }

        const rate = Number(body.rate) || 0;
        const categories = Array.isArray(body.categories)
            ? body.categories.map(String)
            : (body.category ? [String(body.category)] : []);
        const skills = Array.isArray(body.skills) ? body.skills.map(String) : categories;
        const categoryRates = Array.isArray(body.categoryRates)
            ? body.categoryRates.map((row) => ({
                category: row?.category,
                rate: Number(row?.rate) || 0,
            }))
            : [];

        const identityDocuments = [];
        if (body.aadhaarNumber || aadhaarFrontUrl || aadhaarBackUrl) {
            identityDocuments.push({
                docType: 'Aadhaar Card',
                docNumber: body.aadhaarNumber ? String(body.aadhaarNumber) : '',
                frontPhotoUrl: aadhaarFrontUrl,
                backPhotoUrl: aadhaarBackUrl,
                status: 'PENDING',
            });
        }
        if (body.panNumber || panFrontUrl || panBackUrl) {
            identityDocuments.push({
                docType: 'PAN Card',
                docNumber: body.panNumber ? String(body.panNumber).toUpperCase() : '',
                frontPhotoUrl: panFrontUrl,
                backPhotoUrl: panBackUrl,
                status: 'PENDING',
            });
        }

        const bank = body.bank && typeof body.bank === 'object'
            ? {
                accountHolderName: body.bank.accountHolderName || '',
                accountNumber: body.bank.accountNumber || '',
                ifscCode: body.bank.ifscCode || '',
            }
            : undefined;
        const upi = body.upi && typeof body.upi === 'object'
            ? { upiId: body.upi.upiId || '' }
            : undefined;

        const prev = user.workerProfile?.toObject?.() || user.workerProfile || {};

        user.workerProfile = {
            dateOfBirth: body.dateOfBirth || null,
            gender: body.gender || null,
            selfieImageUrl: avatarUrl || prev.selfieImageUrl || null,
            category: body.category || categories[0] || null,
            categories,
            rate,
            hourlyRate: rate,
            categoryRates,
            experienceYears: Number(body.experienceYears) || 0,
            bio: body.bio || null,
            rating: prev.rating ?? 5.0,
            totalJobs: prev.totalJobs ?? 0,
            recentWorkPhotos: prev.recentWorkPhotos || [],
            badges: prev.badges || [],
            skills,
            certifications: certificationUrls,
            workAddress: body.workAddress || null,
            identityDocuments,
            payoutMethod: body.payoutMethod || null,
            bank,
            upi,
        };

        user.kycDocuments = {
            aadhaarNumber: body.aadhaarNumber || null,
            aadhaarFrontPhoto: aadhaarFrontUrl,
            aadhaarBackPhoto: aadhaarBackUrl,
            panNumber: body.panNumber || null,
            panFrontPhoto: panFrontUrl,
            panBackPhoto: panBackUrl,
            selfieImageUrl: avatarUrl,
            certificateUrl: certificationUrls[0] || null,
            govermentIdType: 'Aadhaar Card',
            govermentIdNumber: body.aadhaarNumber || null,
            status: 'submitted',
        };

        user.payoutDetails = {
            payoutMethod: body.payoutMethod || null,
            bank,
            upi,
        };

        await user.save();
        await redis.del(`worker:profile:${userId}`);

        const plain = user.toObject({ versionKey: false });
        delete plain.password;
        delete plain.activeDeviceId;

        return res.status(200).json({
            success: true,
            message: 'Profile and documents uploaded successfully',
            user: {
                _id: plain._id,
                name: plain.name,
                email: plain.email,
                phone: plain.phone,
                role: plain.role,
                avatar: plain.avatar,
                isVerified: plain.isVerified,
                isEmailVerified: plain.isEmailVerified === true,
                workerProfile: plain.workerProfile,
            },
        });
    } catch (error) {
        console.error('setupWorkerProfile error:', error);
        return res.status(500).json({ success: false, message: error.message });
    }
};
