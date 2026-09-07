import Banner from '../models/Banner.js';

// Default starter banners to seed if none exist
const DEFAULT_BANNERS = [
    {
        title: 'Flat 50% Off First Booking',
        code: 'FIXLY50',
        discount: '50% OFF',
        discountPercent: 50,
        description: 'Get 50% discount up to ₹150 on your first home repair service',
        gradient: ['#1E3A8A', '#3B82F6'],
        category: 'all',
        targetUserRole: 'all',
        minOrderValue: 249,
        maxDiscount: 150,
        validUntil: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
        isActive: true,
        priority: 10
    },
    {
        title: 'AC & Appliance Mega Saver',
        code: 'COOL20',
        discount: '20% OFF',
        discountPercent: 20,
        description: 'Save up to ₹250 on all AC and appliance servicing & repairs',
        gradient: ['#047857', '#10B981'],
        category: 'technician',
        targetUserRole: 'all',
        minOrderValue: 399,
        maxDiscount: 250,
        validUntil: new Date(Date.now() + 15 * 24 * 60 * 60 * 1000),
        isActive: true,
        priority: 8
    },
    {
        title: 'Super Weekend Special',
        code: 'WEEKEND100',
        discount: '₹100 FLAT',
        discountAmount: 100,
        description: 'Flat ₹100 instant cash discount on electrician & plumber orders',
        gradient: ['#7C2D12', '#EA580C'],
        category: 'all',
        targetUserRole: 'all',
        minOrderValue: 299,
        maxDiscount: 100,
        validUntil: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
        isActive: true,
        priority: 6
    }
];

// Helper to seed if collection is empty
export const seedDefaultBannersIfEmpty = async () => {
    try {
        const count = await Banner.countDocuments();
        if (count === 0) {
            await Banner.insertMany(DEFAULT_BANNERS);
            console.log('✅ Seeded default promotional coupon banners');
        }
    } catch (err) {
        console.warn('⚠️ Could not seed default banners:', err.message);
    }
};

// Customer API: Get all active coupon banners
export const getBanners = async (req, res) => {
    try {
        await seedDefaultBannersIfEmpty();

        const { category, targetUserRole } = req.query;
        const query = { isActive: true };

        if (category && category !== 'all') {
            query.$or = [{ category: 'all' }, { category }];
        }

        if (targetUserRole && targetUserRole !== 'all') {
            query.targetUserRole = { $in: ['all', targetUserRole] };
        }

        const banners = await Banner.find(query)
            .sort({ priority: -1, createdAt: -1 })
            .lean();

        return res.status(200).json({
            success: true,
            banners: banners.length > 0 ? banners : DEFAULT_BANNERS
        });
    } catch (error) {
        return res.status(500).json({
            success: false,
            message: error.message || 'Failed to fetch coupon banners',
            banners: DEFAULT_BANNERS
        });
    }
};

// Admin API: List all banners (active and inactive)
export const adminGetBanners = async (req, res) => {
    try {
        await seedDefaultBannersIfEmpty();
        const banners = await Banner.find().sort({ priority: -1, createdAt: -1 }).lean();
        return res.status(200).json({ success: true, count: banners.length, banners });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

// Admin API: Create a new banner / coupon
export const adminCreateBanner = async (req, res) => {
    try {
        const {
            title,
            code,
            discount,
            discountPercent,
            discountAmount,
            description,
            imageUrl,
            gradient,
            category,
            targetUserRole,
            minOrderValue,
            maxDiscount,
            validUntil,
            isActive,
            priority
        } = req.body;

        if (!title || !code || !discount) {
            return res.status(400).json({
                success: false,
                message: 'Title, coupon code, and discount are required fields'
            });
        }

        const existing = await Banner.findOne({ code: code.toUpperCase().trim() });
        if (existing) {
            return res.status(400).json({
                success: false,
                message: `Coupon code '${code.toUpperCase()}' already exists`
            });
        }

        const banner = await Banner.create({
            title,
            code: code.toUpperCase().trim(),
            discount,
            discountPercent: Number(discountPercent) || 0,
            discountAmount: Number(discountAmount) || 0,
            description: description || '',
            imageUrl: imageUrl || '',
            gradient: Array.isArray(gradient) && gradient.length > 0 ? gradient : ['#1E3A8A', '#3B82F6'],
            category: category || 'all',
            targetUserRole: targetUserRole || 'all',
            minOrderValue: Number(minOrderValue) || 0,
            maxDiscount: Number(maxDiscount) || 500,
            validUntil: validUntil ? new Date(validUntil) : new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
            isActive: isActive !== undefined ? Boolean(isActive) : true,
            priority: Number(priority) || 0
        });

        return res.status(201).json({
            success: true,
            message: 'Coupon banner created successfully',
            banner
        });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

// Admin API: Update an existing banner
export const adminUpdateBanner = async (req, res) => {
    try {
        const { id } = req.params;
        const banner = await Banner.findById(id);

        if (!banner) {
            return res.status(404).json({ success: false, message: 'Banner not found' });
        }

        const updates = { ...req.body };
        if (updates.code) updates.code = updates.code.toUpperCase().trim();

        const updated = await Banner.findByIdAndUpdate(id, updates, { new: true });

        return res.status(200).json({
            success: true,
            message: 'Coupon banner updated successfully',
            banner: updated
        });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

// Admin API: Delete a banner
export const adminDeleteBanner = async (req, res) => {
    try {
        const { id } = req.params;
        const banner = await Banner.findByIdAndDelete(id);

        if (!banner) {
            return res.status(404).json({ success: false, message: 'Banner not found' });
        }

        return res.status(200).json({
            success: true,
            message: 'Coupon banner deleted successfully'
        });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};
