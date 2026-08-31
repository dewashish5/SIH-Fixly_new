import User from '../models/User.js';
import Booking from '../models/Booking.js';
import Service from '../models/Service.js';
import redis from '../config/redis.js';

const mapWorkerKyc = (worker) => {
    // No dedicated kyc field on User — use isVerified as KYC gate
    const verified = Boolean(worker.isVerified);
    return {
        ...worker,
        kyc: verified ? 'verified' : 'pending'
    };
};

// GET /api/admin/stats
export const getAdminStats = async (req, res) => {
    try {
        const [usersByRole, bookingsByStatus, servicesCount] = await Promise.all([
            User.aggregate([
                { $group: { _id: '$role', count: { $sum: 1 } } }
            ]),
            Booking.aggregate([
                { $group: { _id: '$status', count: { $sum: 1 } } }
            ]),
            Service.countDocuments()
        ]);

        const users = { customer: 0, worker: 0, admin: 0 };
        for (const row of usersByRole) {
            if (row._id) users[row._id] = row.count;
        }

        const bookings = {};
        for (const row of bookingsByStatus) {
            bookings[row._id] = row.count;
        }

        return res.status(200).json({
            success: true,
            stats: {
                users,
                bookings,
                services: servicesCount
            }
        });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

// GET /api/admin/workers?kyc=pending|verified|all
export const listWorkers = async (req, res) => {
    try {
        const kyc = (req.query.kyc || 'all').toLowerCase();
        const filter = { role: 'worker' };

        if (kyc === 'pending') {
            filter.isVerified = false;
        } else if (kyc === 'verified') {
            filter.isVerified = true;
        } else if (kyc !== 'all') {
            return res.status(400).json({
                success: false,
                message: "kyc must be 'pending', 'verified', or 'all'"
            });
        }

        const workers = await User.find(filter)
            .select('-password -activeDeviceId')
            .sort({ createdAt: -1 })
            .lean();

        return res.status(200).json({
            success: true,
            count: workers.length,
            workers: workers.map(mapWorkerKyc)
        });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

// PATCH /api/admin/workers/:id/kyc  body: { status: 'approved'|'rejected' }
export const updateWorkerKyc = async (req, res) => {
    try {
        const { id } = req.params;
        const { status } = req.body;

        if (!['approved', 'rejected'].includes(status)) {
            return res.status(400).json({
                success: false,
                message: "status must be 'approved' or 'rejected'"
            });
        }

        const worker = await User.findOne({ _id: id, role: 'worker' });
        if (!worker) {
            return res.status(404).json({ success: false, message: 'Worker not found' });
        }

        worker.isVerified = status === 'approved';

        if (worker.workerProfile) {
            const badges = new Set(worker.workerProfile.badges || []);
            if (status === 'approved') {
                badges.add('Verified');
            } else {
                badges.delete('Verified');
            }
            worker.workerProfile.badges = [...badges];
            worker.markModified('workerProfile');
        }

        await worker.save();

        if (worker.email) {
            await redis.del(`user:email:${worker.email}`);
        }
        await redis.del(`worker:profile:${worker._id}`);

        const safe = worker.toObject();
        delete safe.password;
        delete safe.activeDeviceId;

        return res.status(200).json({
            success: true,
            message: `Worker KYC ${status}`,
            worker: mapWorkerKyc(safe)
        });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

// GET /api/admin/customers
export const listCustomers = async (req, res) => {
    try {
        const customers = await User.find({ role: 'customer' })
            .select('-password -activeDeviceId')
            .sort({ createdAt: -1 })
            .lean();

        return res.status(200).json({
            success: true,
            count: customers.length,
            customers
        });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

// GET /api/admin/bookings
export const listBookings = async (req, res) => {
    try {
        const bookings = await Booking.find()
            .populate('customer', 'name email phone')
            .populate('worker', 'name email phone')
            .populate('service', 'title category basePrice')
            .sort({ createdAt: -1 })
            .lean();

        return res.status(200).json({
            success: true,
            count: bookings.length,
            bookings
        });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

// GET /api/admin/services
export const listServices = async (req, res) => {
    try {
        const services = await Service.find().sort({ category: 1, title: 1 }).lean();
        return res.status(200).json({
            success: true,
            count: services.length,
            services
        });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

// POST /api/admin/services
export const createAdminService = async (req, res) => {
    try {
        const { title, category, image, basePrice, estimatedTime, whatsIncluded, isActive } = req.body;

        if (!title || !category || !image || basePrice === undefined) {
            return res.status(400).json({
                success: false,
                message: 'title, category, image, and basePrice are required'
            });
        }

        let included = whatsIncluded;
        if (typeof whatsIncluded === 'string') {
            included = whatsIncluded.split(',').map((s) => s.trim()).filter(Boolean);
        }

        const service = await Service.create({
            title,
            category: String(category).toLowerCase().trim(),
            image,
            basePrice: parseFloat(basePrice),
            estimatedTime: estimatedTime || '1 Hour',
            whatsIncluded: included || [],
            isActive: isActive !== undefined ? Boolean(isActive) : true
        });

        await redis.del('app:home:dashboard');
        await redis.del('app:services:categories');

        return res.status(201).json({
            success: true,
            message: 'Service created',
            service
        });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

// PATCH /api/admin/services/:id
export const updateAdminService = async (req, res) => {
    try {
        const { id } = req.params;
        const allowed = ['title', 'category', 'image', 'basePrice', 'estimatedTime', 'whatsIncluded', 'isActive'];
        const updates = {};

        for (const key of allowed) {
            if (req.body[key] !== undefined) {
                updates[key] = req.body[key];
            }
        }

        if (updates.category) {
            updates.category = String(updates.category).toLowerCase().trim();
        }
        if (updates.basePrice !== undefined) {
            updates.basePrice = parseFloat(updates.basePrice);
        }
        if (typeof updates.whatsIncluded === 'string') {
            updates.whatsIncluded = updates.whatsIncluded.split(',').map((s) => s.trim()).filter(Boolean);
        }

        const service = await Service.findByIdAndUpdate(id, { $set: updates }, { new: true });
        if (!service) {
            return res.status(404).json({ success: false, message: 'Service not found' });
        }

        await redis.del('app:home:dashboard');
        await redis.del('app:services:categories');
        await redis.del(`service:details:${id}`);

        return res.status(200).json({
            success: true,
            message: 'Service updated',
            service
        });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};
