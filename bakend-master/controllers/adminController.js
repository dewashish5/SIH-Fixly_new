import jwt from 'jsonwebtoken';
import User from '../models/User.js';
import Booking from '../models/Booking.js';
import Service from '../models/Service.js';
import Review from '../models/Review.js';
import Transaction from '../models/Transaction.js';
import { uploadToCloudinary } from '../utils/cloudinary.js';

const pageParams = (query) => {
    const page = Math.max(1, parseInt(query.page, 10) || 1);
    const limit = Math.min(100, Math.max(1, parseInt(query.limit, 10) || 10));
    const skip = (page - 1) * limit;
    return { page, limit, skip };
};

const paginate = (page, limit, total) => ({
    page,
    limit,
    total,
    totalPages: Math.max(1, Math.ceil(total / limit)),
});

export const adminLogin = async (req, res) => {
    try {
        const email = String(req.body.email || '').toLowerCase().trim();
        const password = String(req.body.password || '');
        if (!email || !password) {
            return res.status(400).json({ success: false, message: 'Email and password required' });
        }

        const user = await User.findOne({ email });
        if (!user || user.role !== 'admin') {
            return res.status(401).json({ success: false, message: 'Invalid admin credentials' });
        }
        if (!user.password || !(await user.comparePassword(password))) {
            return res.status(401).json({ success: false, message: 'Invalid admin credentials' });
        }

        const token = jwt.sign(
            { id: user._id, role: user.role },
            process.env.JWT_SECRET,
            { expiresIn: process.env.JWT_ACCESS_EXPIRY || '1d' }
        );

        return res.status(200).json({
            success: true,
            token,
            user: {
                _id: user._id,
                name: user.name,
                email: user.email,
                role: user.role,
                avatar: user.avatar,
            },
        });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

export const adminMe = async (req, res) => {
    try {
        const user = await User.findById(req.user.id).select('-password -activeDeviceId');
        if (!user || user.role !== 'admin') {
            return res.status(401).json({ success: false, message: 'Not an admin' });
        }
        return res.status(200).json({ success: true, user });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

export const updateAdminMe = async (req, res) => {
    try {
        const { name, email, avatar } = req.body;
        const updates = {};
        if (name !== undefined) updates.name = name;
        if (email !== undefined) updates.email = String(email).toLowerCase().trim();
        if (avatar !== undefined) updates.avatar = avatar;

        const user = await User.findByIdAndUpdate(
            req.user.id,
            { $set: updates },
            { new: true }
        ).select('-password -activeDeviceId');

        if (!user || user.role !== 'admin') {
            return res.status(401).json({ success: false, message: 'Not an admin' });
        }

        return res.status(200).json({
            success: true,
            user: {
                _id: user._id,
                name: user.name,
                email: user.email,
                role: user.role,
                avatar: user.avatar,
            },
            message: 'Admin profile updated successfully',
        });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

export const getDashboard = async (req, res) => {
    try {
        const [
            totalCustomers,
            totalWorkers,
            pendingApprovals,
            totalBookings,
            revenueAgg,
            recentBookings,
            topServices,
        ] = await Promise.all([
            User.countDocuments({ role: 'customer' }),
            // Workers tab = verified only
            User.countDocuments({ role: 'worker', isVerified: true }),
            User.countDocuments({
                role: 'worker',
                isVerified: { $ne: true },
                $or: [
                    { 'kycDocuments.status': 'submitted' },
                    { workerProfile: { $ne: null } },
                ],
            }),
            Booking.countDocuments(),
            Transaction.aggregate([
                { $match: { status: 'success' } },
                { $group: { _id: null, total: { $sum: '$amount' } } },
            ]),
            Booking.find()
                .sort({ createdAt: -1 })
                .limit(10)
                .populate('customer', 'name email phone')
                .populate('worker', 'name email phone')
                .populate('service', 'title category basePrice')
                .lean(),
            Service.find({ isActive: true }).sort({ basePrice: -1 }).limit(5).lean(),
        ]);

        return res.status(200).json({
            success: true,
            stats: {
                totalCustomers,
                totalWorkers,
                pendingApprovals,
                totalBookings,
                totalRevenue: revenueAgg[0]?.total || 0,
            },
            recentBookings,
            topServices,
        });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

export const listCustomers = async (req, res) => {
    try {
        const { page, limit, skip } = pageParams(req.query);
        const filter = { role: 'customer' };
        if (req.query.q) {
            const q = String(req.query.q);
            filter.$or = [
                { name: new RegExp(q, 'i') },
                { email: new RegExp(q, 'i') },
                { phone: new RegExp(q, 'i') },
            ];
        }
        const [total, data] = await Promise.all([
            User.countDocuments(filter),
            User.find(filter).select('-password -activeDeviceId').sort({ createdAt: -1 }).skip(skip).limit(limit).lean(),
        ]);
        return res.status(200).json({ success: true, data, pagination: paginate(page, limit, total) });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

export const getCustomerById = async (req, res) => {
    try {
        const user = await User.findOne({ _id: req.params.id, role: 'customer' }).select('-password');
        if (!user) return res.status(404).json({ success: false, message: 'Customer not found' });
        return res.status(200).json({ success: true, data: user });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

export const toggleCustomerStatus = async (req, res) => {
    try {
        const user = await User.findOneAndUpdate(
            { _id: req.params.id, role: 'customer' },
            { isVerified: Boolean(req.body.isVerified) },
            { new: true }
        ).select('-password');
        if (!user) return res.status(404).json({ success: false, message: 'Customer not found' });
        return res.status(200).json({ success: true, data: user });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

export const listWorkers = async (req, res) => {
    try {
        const { page, limit, skip } = pageParams(req.query);
        const filter = { role: 'worker' };
        if (req.query.q) {
            const q = String(req.query.q);
            filter.$or = [
                { name: new RegExp(q, 'i') },
                { email: new RegExp(q, 'i') },
                { phone: new RegExp(q, 'i') },
            ];
        }
        if (req.query.pendingApproval === 'true' || req.query.pendingApproval === '1') {
            filter.isVerified = { $ne: true };
            // Submitted KYC OR finished app onboarding profile (legacy rows may lack kycDocuments)
            filter.$and = [
                ...(filter.$or ? [{ $or: filter.$or }] : []),
                {
                    $or: [
                        { 'kycDocuments.status': 'submitted' },
                        { workerProfile: { $ne: null } },
                    ],
                },
            ];
            delete filter.$or;
        } else if (req.query.kycStatus) {
            filter['kycDocuments.status'] = String(req.query.kycStatus);
        }
        if (req.query.isVerified === 'true') filter.isVerified = true;
        if (req.query.isVerified === 'false') filter.isVerified = false;
        const [total, data] = await Promise.all([
            User.countDocuments(filter),
            User.find(filter).select('-password -activeDeviceId').sort({ createdAt: -1 }).skip(skip).limit(limit).lean(),
        ]);
        return res.status(200).json({ success: true, data, pagination: paginate(page, limit, total) });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

export const getWorkerById = async (req, res) => {
    try {
        const user = await User.findOne({ _id: req.params.id, role: 'worker' }).select('-password');
        if (!user) return res.status(404).json({ success: false, message: 'Worker not found' });

        // Legacy Flutter rows sometimes stored docs only under workerProfile.identityDocuments
        const plain = user.toObject();
        if (!plain.kycDocuments?.status || plain.kycDocuments.status === 'none') {
            const docs = plain.workerProfile?.identityDocuments || [];
            const aadhaar = docs.find((d) => /aadhaar/i.test(d.docType || ''));
            const pan = docs.find((d) => /pan/i.test(d.docType || ''));
            if (docs.length || plain.workerProfile) {
                plain.kycDocuments = {
                    ...(plain.kycDocuments || {}),
                    aadhaarNumber: plain.kycDocuments?.aadhaarNumber || aadhaar?.docNumber || null,
                    aadhaarFrontPhoto: plain.kycDocuments?.aadhaarFrontPhoto || aadhaar?.frontPhotoUrl || null,
                    aadhaarBackPhoto: plain.kycDocuments?.aadhaarBackPhoto || aadhaar?.backPhotoUrl || null,
                    panNumber: plain.kycDocuments?.panNumber || pan?.docNumber || null,
                    panFrontPhoto: plain.kycDocuments?.panFrontPhoto || pan?.frontPhotoUrl || null,
                    panBackPhoto: plain.kycDocuments?.panBackPhoto || pan?.backPhotoUrl || null,
                    selfieImageUrl:
                        plain.kycDocuments?.selfieImageUrl ||
                        plain.workerProfile?.selfieImageUrl ||
                        plain.avatar ||
                        null,
                    certificateUrl:
                        plain.kycDocuments?.certificateUrl ||
                        (Array.isArray(plain.workerProfile?.certifications)
                            ? plain.workerProfile.certifications[0]
                            : null),
                    status: plain.isVerified
                        ? 'approved'
                        : docs.length || plain.workerProfile
                          ? 'submitted'
                          : plain.kycDocuments?.status || 'none',
                    declineReason: plain.kycDocuments?.declineReason || null,
                };
            }
        }

        return res.status(200).json({ success: true, data: plain });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

export const updateWorker = async (req, res) => {
    try {
        const allowed = ['name', 'phone', 'avatar', 'isVerified', 'workerProfile'];
        const patch = {};
        for (const key of allowed) {
            if (req.body[key] !== undefined) patch[key] = req.body[key];
        }
        const user = await User.findOneAndUpdate(
            { _id: req.params.id, role: 'worker' },
            patch,
            { new: true }
        ).select('-password');
        if (!user) return res.status(404).json({ success: false, message: 'Worker not found' });
        return res.status(200).json({ success: true, data: user });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

export const updateWorkerStatus = async (req, res) => {
    try {
        const patch = {};
        const kycStatus = req.body.kycStatus ? String(req.body.kycStatus) : null;
        const declineReason =
            req.body.declineReason !== undefined ? String(req.body.declineReason).trim() : undefined;

        if (req.body.isVerified === true || kycStatus === 'approved') {
            patch.isVerified = true;
            patch['kycDocuments.status'] = 'approved';
            patch['kycDocuments.declineReason'] = null;
        } else if (kycStatus === 'rejected' || req.body.isVerified === false) {
            if (kycStatus === 'rejected') {
                if (!declineReason) {
                    return res.status(400).json({
                        success: false,
                        message: 'declineReason required when rejecting worker',
                    });
                }
                patch.isVerified = false;
                patch['kycDocuments.status'] = 'rejected';
                patch['kycDocuments.declineReason'] = declineReason;
            } else {
                // Legacy suspend / unverify without KYC reject text
                patch.isVerified = false;
                if (kycStatus) patch['kycDocuments.status'] = kycStatus;
                if (declineReason !== undefined) {
                    patch['kycDocuments.declineReason'] = declineReason || null;
                }
            }
        } else {
            if (req.body.isVerified !== undefined) patch.isVerified = Boolean(req.body.isVerified);
            if (kycStatus) patch['kycDocuments.status'] = kycStatus;
            if (declineReason !== undefined) {
                patch['kycDocuments.declineReason'] = declineReason || null;
            }
        }

        if (Object.keys(patch).length === 0) {
            return res.status(400).json({ success: false, message: 'No status fields provided' });
        }

        const user = await User.findOneAndUpdate(
            { _id: req.params.id, role: 'worker' },
            patch,
            { new: true }
        ).select('-password');
        if (!user) return res.status(404).json({ success: false, message: 'Worker not found' });
        return res.status(200).json({ success: true, data: user });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

export const addWorker = async (req, res) => {
    try {
        const { name, email, phone, password = 'Worker@123', category, hourlyRate } = req.body;
        if (!name || !email) {
            return res.status(400).json({ success: false, message: 'name and email required' });
        }
        const exists = await User.findOne({ email: String(email).toLowerCase() });
        if (exists) return res.status(400).json({ success: false, message: 'Email already exists' });

        const user = await User.create({
            name,
            email: String(email).toLowerCase(),
            phone: phone || null,
            password,
            role: 'worker',
            isVerified: false,
            isEmailVerified: true,
            workerProfile: {
                category: category || 'General',
                hourlyRate: Number(hourlyRate) || 0,
                rate: Number(hourlyRate) || 0,
                skills: category ? [category] : [],
            },
        });
        const plain = user.toObject();
        delete plain.password;
        return res.status(201).json({ success: true, data: plain });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

export const listBookings = async (req, res) => {
    try {
        const { page, limit, skip } = pageParams(req.query);
        const filter = {};
        if (req.query.status) filter.status = req.query.status;
        const [total, data] = await Promise.all([
            Booking.countDocuments(filter),
            Booking.find(filter)
                .sort({ createdAt: -1 })
                .skip(skip)
                .limit(limit)
                .populate('customer', 'name email phone')
                .populate('worker', 'name email phone')
                .populate('service', 'title category basePrice')
                .lean(),
        ]);
        return res.status(200).json({ success: true, data, pagination: paginate(page, limit, total) });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

export const getBookingById = async (req, res) => {
    try {
        const booking = await Booking.findById(req.params.id)
            .populate('customer', 'name email phone')
            .populate('worker', 'name email phone')
            .populate('service')
            .lean();
        if (!booking) return res.status(404).json({ success: false, message: 'Booking not found' });
        return res.status(200).json({ success: true, data: booking });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

export const assignWorkerToBooking = async (req, res) => {
    try {
        const booking = await Booking.findByIdAndUpdate(
            req.params.bookingId,
            { worker: req.body.workerId, status: 'ACCEPTED' },
            { new: true }
        );
        if (!booking) return res.status(404).json({ success: false, message: 'Booking not found' });
        return res.status(200).json({ success: true, data: booking });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

export const updateBookingStatus = async (req, res) => {
    try {
        const booking = await Booking.findByIdAndUpdate(
            req.params.bookingId,
            { status: req.body.status },
            { new: true }
        );
        if (!booking) return res.status(404).json({ success: false, message: 'Booking not found' });
        return res.status(200).json({ success: true, data: booking });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

export const listServices = async (req, res) => {
    try {
        const { page, limit, skip } = pageParams(req.query);
        const filter = {};
        if (req.query.q) filter.title = new RegExp(String(req.query.q), 'i');
        const [total, data] = await Promise.all([
            Service.countDocuments(filter),
            Service.find(filter).sort({ createdAt: -1 }).skip(skip).limit(limit).lean(),
        ]);
        return res.status(200).json({ success: true, data, pagination: paginate(page, limit, total) });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

export const createServiceAdmin = async (req, res) => {
    try {
        const service = await Service.create(req.body);
        return res.status(201).json({ success: true, data: service });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

export const updateServiceAdmin = async (req, res) => {
    try {
        const service = await Service.findByIdAndUpdate(req.params.id, req.body, { new: true });
        if (!service) return res.status(404).json({ success: false, message: 'Service not found' });
        return res.status(200).json({ success: true, data: service });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

export const deleteServiceAdmin = async (req, res) => {
    try {
        const service = await Service.findByIdAndDelete(req.params.id);
        if (!service) return res.status(404).json({ success: false, message: 'Service not found' });
        return res.status(200).json({ success: true, message: 'Deleted' });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

export const listPayments = async (req, res) => {
    try {
        const { page, limit, skip } = pageParams(req.query);
        const [total, data] = await Promise.all([
            Transaction.countDocuments(),
            Transaction.find().sort({ createdAt: -1 }).skip(skip).limit(limit).lean(),
        ]);
        return res.status(200).json({ success: true, data, pagination: paginate(page, limit, total) });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

export const paymentStats = async (req, res) => {
    try {
        const agg = await Transaction.aggregate([
            {
                $group: {
                    _id: '$status',
                    count: { $sum: 1 },
                    amount: { $sum: '$amount' },
                },
            },
        ]);
        return res.status(200).json({ success: true, stats: agg });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

export const listReviews = async (req, res) => {
    try {
        const { page, limit, skip } = pageParams(req.query);
        const [total, data, ratingStats] = await Promise.all([
            Review.countDocuments(),
            Review.find()
                .sort({ createdAt: -1 })
                .skip(skip)
                .limit(limit)
                .populate('customer', 'name')
                .populate('worker', 'name')
                .lean(),
            Review.aggregate([
                {
                    $group: {
                        _id: null,
                        avgRating: { $avg: '$rating' },
                        count: { $sum: 1 },
                    },
                },
            ]),
        ]);
        return res.status(200).json({
            success: true,
            data,
            ratingStats: ratingStats[0] || { avgRating: 0, count: 0 },
            pagination: paginate(page, limit, total),
        });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

export const deleteReview = async (req, res) => {
    try {
        await Review.findByIdAndDelete(req.params.id);
        return res.status(200).json({ success: true, message: 'Deleted' });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

// ponytail: notifications not modeled — empty OK stubs so panel stops 404ing
export const getNotifications = async (_req, res) => {
    return res.status(200).json({ success: true, data: [] });
};
export const broadcastNotification = async (_req, res) => {
    return res.status(200).json({ success: true, message: 'Broadcast queued (stub)' });
};
export const markNotificationsRead = async (_req, res) => {
    return res.status(200).json({ success: true });
};
export const deleteNotification = async (_req, res) => {
    return res.status(200).json({ success: true });
};

export const getAnalytics = async (_req, res) => {
    return res.status(200).json({ success: true, analytics: {} });
};
export const getAIInsights = async (_req, res) => {
    return res.status(200).json({ success: true, insights: [] });
};
export const getReports = async (_req, res) => {
    return res.status(200).json({ success: true, reports: {} });
};

let settingsStore = {
    platformCommissionPercent: 5,
    cooperativeWelfarePercent: 5,
    autoDispatchEnabled: true,
    emergencyHotline: '+91 98765 43210',
    emailNotifications: true,
    smsAlerts: true,
    payoutSchedule: 'Instant Automated UPI',
    twoFactorAuth: false,
    // Canned texts for Approvals → Decline (admin can edit; still overridable per reject)
    workerDeclineTemplates: [
        'Your request to join as a worker has been declined.',
        'Documents unclear or incomplete. Please re-upload clear Aadhaar and PAN photos.',
        'Identity details do not match our records. Please correct and resubmit.',
    ],
};

export const getSettings = async (_req, res) => {
    return res.status(200).json({ success: true, settings: settingsStore });
};
export const updateSettings = async (req, res) => {
    settingsStore = { ...settingsStore, ...req.body };
    return res.status(200).json({ success: true, settings: settingsStore });
};

export const adminUpload = async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({ success: false, message: 'file required' });
        }
        const result = await uploadToCloudinary(req.file.buffer, 'gigconnect/admin');
        return res.status(201).json({ success: true, url: result.secure_url });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};
