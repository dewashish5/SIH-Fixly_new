import Booking from '../models/Booking.js';
import { fail, ok } from '../utils/http.js';

export const getDemandForecast = async (req, res) => {
    try {
        const { serviceId, lat, lng } = req.query;
        const horizon = String(req.query.horizon || '24h');
        const hours = horizon.endsWith('h') ? Number(horizon.replace('h', '')) || 24 : 24;
        
        const now = new Date();
        const thirtyDaysAgo = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
        
        const baseQuery = { createdAt: { $gte: thirtyDaysAgo } };
        if (serviceId) baseQuery.service = serviceId;
        
        // Geographic heatmap filtering (10km radius)
        if (lat && lng) {
            baseQuery['location.coordinates'] = {
                $near: {
                    $geometry: { type: 'Point', coordinates: [Number(lng), Number(lat)] },
                    $maxDistance: 10000
                }
            };
        }

        const recentBookings = await Booking.find(baseQuery).select('createdAt location status');
        
        // Same day of week distribution
        const targetDay = now.getDay();
        const sameDayBookings = recentBookings.filter(b => b.createdAt.getDay() === targetDay);
        
        const hourlyCounts = Array(24).fill(0);
        sameDayBookings.forEach(b => {
            hourlyCounts[b.createdAt.getHours()]++;
        });
        
        const numTargetDays = 4; // Approx 4 weeks in 30 days
        const hourlyAverages = hourlyCounts.map(count => count / numTargetDays);

        // Trend multiplier: last 7 days vs prev 7 days
        const sevenDaysAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
        const fourteenDaysAgo = new Date(now.getTime() - 14 * 24 * 60 * 60 * 1000);
        
        const last7DaysCount = recentBookings.filter(b => b.createdAt >= sevenDaysAgo).length;
        const prev7DaysCount = recentBookings.filter(b => b.createdAt >= fourteenDaysAgo && b.createdAt < sevenDaysAgo).length;
        
        let trendMultiplier = 1;
        if (prev7DaysCount > 0) {
            trendMultiplier = Math.max(0.5, Math.min(2, last7DaysCount / prev7DaysCount));
        }

        const forecast = [];
        now.setMinutes(0, 0, 0);
        
        for (let i = 0; i < Math.min(hours, 24); i += 1) {
            const time = new Date(now.getTime() + i * 60 * 60 * 1000);
            const hour = time.getHours();
            
            const expectedBookings = Math.round((hourlyAverages[hour] || 0) * trendMultiplier);
            
            let demandLevel = 'LOW';
            if (expectedBookings >= 10) demandLevel = 'HIGH';
            else if (expectedBookings >= 4) demandLevel = 'MEDIUM';
            
            forecast.push({ time: time.toISOString(), demandLevel, expectedBookings });
        }
        
        let heatmap = [];
        if (lat && lng) {
            heatmap = recentBookings.map(b => {
                const coordinates = b.location?.coordinates;
                if (coordinates && coordinates.length === 2) {
                    return { lat: coordinates[1], lng: coordinates[0], weight: 1 };
                }
                return null;
            }).filter(Boolean);
        }

        return ok(res, { forecast, data: forecast, heatmap });
    } catch (error) {
        return fail(res, 500, 'INTERNAL_ERROR', error.message);
    }
};
