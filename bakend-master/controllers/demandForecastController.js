import Booking from '../models/Booking.js';
import { fail, ok } from '../utils/http.js';

export const getDemandForecast = async (req, res) => {
    try {
        const horizon = String(req.query.horizon || '24h');
        const hours = horizon.endsWith('h') ? Number(horizon.replace('h', '')) || 24 : 24;
        const since = new Date(Date.now() - hours * 60 * 60 * 1000);
        const query = { createdAt: { $gte: since } };
        if (req.query.serviceId) query.service = req.query.serviceId;
        const count = await Booking.countDocuments(query);
        const perHour = hours ? count / hours : 0;
        const forecast = [];
        const now = new Date();
        now.setMinutes(0, 0, 0);
        for (let i = 0; i < Math.min(hours, 24); i += 1) {
            const time = new Date(now.getTime() + i * 60 * 60 * 1000);
            const expectedBookings = Math.round(perHour);
            let demandLevel = 'LOW';
            if (expectedBookings >= 10) demandLevel = 'HIGH';
            else if (expectedBookings >= 4) demandLevel = 'MEDIUM';
            forecast.push({ time: time.toISOString(), demandLevel, expectedBookings });
        }
        return ok(res, { forecast, data: forecast });
    } catch (error) {
        return fail(res, 500, 'INTERNAL_ERROR', error.message);
    }
};
