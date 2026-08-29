import dotenv from 'dotenv';
dotenv.config();

import redis from '../config/redis.js';
import Service from '../models/Service.js';

// Screen 1: Home Dashboard Data (Redis Cached)
export const getHomeData = async (req, res) => {
    try {
        const cacheKey = 'app:home:dashboard';
        const cachedData = await redis.get(cacheKey);

        if (cachedData) {
            return res.status(200).json({ success: true, source: 'cache', data: JSON.parse(cachedData) });
        }

        const limit = parseInt(process.env.HOME_SERVICES_LIMIT, 10) || 6;
        const ttl = parseInt(process.env.CACHE_TTL_HOME, 10) || 3600;

        const categories = await Service.distinct('category');
        const topServices = await Service.find({ isActive: true }).limit(limit).lean();

        const responsePayload = {
            categories,
            topServices,
            featuredOffers: [
                { id: 'off_1', title: 'Spring Cleaning Special', discount: '20% OFF', code: 'SPRING20' },
                { id: 'off_2', title: 'First-Time User Discount', discount: '15% OFF', code: 'NEW15' }
            ]
        };

        await redis.set(cacheKey, JSON.stringify(responsePayload), 'EX', ttl);

        return res.status(200).json({ success: true, source: 'db', data: responsePayload });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

// Screen 2: All Categories & Sub-Services (Redis Cached)
export const getCategories = async (req, res) => {
    try {
        const cacheKey = 'app:services:categories';
        const cachedData = await redis.get(cacheKey);

        if (cachedData) {
            return res.status(200).json({ success: true, source: 'cache', categories: JSON.parse(cachedData) });
        }

        const ttl = parseInt(process.env.CACHE_TTL_CATEGORIES, 10) || 3600;

        const services = await Service.find({ isActive: true }).lean();
        const groupedCategories = services.reduce((acc, service) => {
            acc[service.category] = acc[service.category] || [];
            acc[service.category].push(service);
            return acc;
        }, {});

        await redis.set(cacheKey, JSON.stringify(groupedCategories), 'EX', ttl);

        return res.status(200).json({ success: true, source: 'db', categories: groupedCategories });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

// Screen 3: Service Pricing & Details
export const getServiceDetails = async (req, res) => {
    try {
        const { serviceId } = req.params;
        const cacheKey = `service:details:${serviceId}`;

        const cachedService = await redis.get(cacheKey);
        if (cachedService) {
            return res.status(200).json({ success: true, service: JSON.parse(cachedService) });
        }

        const ttl = parseInt(process.env.CACHE_TTL_SERVICE_DETAILS, 10) || 1800;

        const service = await Service.findById(serviceId).lean();
        if (!service) return res.status(404).json({ success: false, message: 'Service not found' });

        await redis.set(cacheKey, JSON.stringify(service), 'EX', ttl);

        return res.status(200).json({ success: true, service });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

export const getExtraPartsCatalog = async (req, res) => {
    try {
        // Yahan extra parts ka catalog fetch karne ka logic likhein
        res.status(200).json({
            success: true,
            message: 'Extra parts catalog fetched successfully',
            data: []
        });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};