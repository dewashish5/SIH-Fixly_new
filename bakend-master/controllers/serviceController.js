import Service from '../models/Service.js';
import { uploadToCloudinary } from '../utils/cloudinary.js';
import redis from '../config/redis.js';

// 1. Create New Service / Category (Uses Multer + Cloudinary)
export const createService = async (req, res) => {
    try {
        const { title, category, basePrice, estimatedTime, whatsIncluded } = req.body;

        if (!title || !category || !basePrice) {
            return res.status(400).json({ success: false, message: 'Title, category aur basePrice required hain' });
        }

        if (!req.file) {
            return res.status(400).json({ success: false, message: 'Service image file upload karna mandatory hai' });
        }

        // Upload to Cloudinary using utility helper
        const uploadResult = await uploadToCloudinary(req.file.buffer);
        const imageUrl = uploadResult.secure_url;

        // Parse whatsIncluded list
        let whatsIncludedArray = [];
        if (whatsIncluded) {
            whatsIncludedArray = whatsIncluded.split(',').map(item => item.trim());
        }

        const newService = await Service.create({
            title,
            category: category.toLowerCase().trim(),
            image: imageUrl,
            basePrice: parseFloat(basePrice),
            estimatedTime: estimatedTime || '1 Hour',
            whatsIncluded: whatsIncludedArray
        });

        // Clear Redis cache so new category/service displays immediately
        await redis.del('app:home:dashboard');
        await redis.del('app:services:categories');

        return res.status(201).json({
            success: true,
            message: 'Service/Category created successfully',
            service: newService
        });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

// 2. Search Services
export const searchServices = async (req, res) => {
    try {
        const { query } = req.query;
        if (!query) {
            return res.status(400).json({ success: false, message: 'Search query string is required' });
        }

        const services = await Service.find({
            isActive: true,
            $or: [
                { title: { $regex: query, $options: 'i' } },
                { category: { $regex: query, $options: 'i' } }
            ]
        }).lean();

        return res.status(200).json({ success: true, services });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

// 3. Get All Categories (Grouped)
export const getCategories = async (req, res) => {
    // #swagger.tags = ['Services']
    try {
        const cacheKey = 'app:services:categories';
        const cachedData = await redis.get(cacheKey);

        if (cachedData) {
            return res.status(200).json({ success: true, source: 'cache', categories: JSON.parse(cachedData) });
        }

        const services = await Service.find({ isActive: true }).lean();
        const groupedCategories = services.reduce((acc, service) => {
            acc[service.category] = acc[service.category] || [];
            acc[service.category].push(service);
            return acc;
        }, {});

        const ttl = parseInt(process.env.CACHE_TTL_CATEGORIES, 10) || 3600;
        await redis.set(cacheKey, JSON.stringify(groupedCategories), 'EX', ttl);

        return res.status(200).json({ success: true, source: 'db', categories: groupedCategories });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

// 4. Get Service Details
export const getServiceDetails = async (req, res) => {
    // #swagger.tags = ['Services']
    try {
        const { serviceId } = req.params;
        const cacheKey = `service:details:${serviceId}`;

        const cachedService = await redis.get(cacheKey);
        if (cachedService) {
            return res.status(200).json({ success: true, source: 'cache', service: JSON.parse(cachedService) });
        }

        const service = await Service.findById(serviceId).lean();
        if (!service) return res.status(404).json({ success: false, message: 'Service details not found' });

        const ttl = parseInt(process.env.CACHE_TTL_SERVICE_DETAILS, 10) || 1800;
        await redis.set(cacheKey, JSON.stringify(service), 'EX', ttl);

        return res.status(200).json({ success: true, source: 'db', service });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

// 5. Extra Parts Catalog
export const getExtraPartsCatalog = async (req, res) => {
    try {
        const mockParts = [
            { id: 'part_1', title: 'U-bend Pipe Replacement', price: 25 },
            { id: 'part_2', title: 'Extra Gasket Seals', price: 5 },
            { id: 'part_3', title: 'Disposal Cleaning Fluid', price: 15 },
            { id: 'part_4', title: 'PVC Connection Adapter', price: 10 }
        ];
        return res.status(200).json({ success: true, catalog: mockParts });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};