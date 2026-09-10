import Banner from '../models/Banner.js';

/**
 * Validate a promotional coupon code and calculate discount amount
 *
 * @param {Object} params
 * @param {string} params.couponCode - The coupon code to check (e.g. FIXLY50)
 * @param {number} params.baseAmount - Total order amount before coupon discount
 * @param {string} [params.serviceCategory] - Service category (e.g. electrical, plumbing)
 * @param {string} [params.userRole] - Customer or user role
 * @returns {Promise<{isValid: boolean, message?: string, couponCode?: string, discountAmount?: number, finalAmount?: number, banner?: Object}>}
 */
export const validateAndCalculateCoupon = async ({
    couponCode,
    baseAmount = 0,
    serviceCategory = null,
    userRole = 'customer'
}) => {
    if (!couponCode || typeof couponCode !== 'string' || !couponCode.trim()) {
        return { isValid: false, message: 'Coupon code is required' };
    }

    const code = couponCode.toUpperCase().trim();
    const banner = await Banner.findOne({ code, isActive: true });

    if (!banner) {
        return { isValid: false, message: `Coupon code '${code}' is invalid or inactive` };
    }

    // 1. Expiration Check
    if (banner.validUntil && new Date(banner.validUntil) < new Date()) {
        return { isValid: false, message: `Coupon code '${code}' has expired` };
    }

    // 2. Target User Role Check
    if (banner.targetUserRole && banner.targetUserRole !== 'all' && userRole) {
        if (banner.targetUserRole !== userRole) {
            return { isValid: false, message: `Coupon code '${code}' is not applicable for your account` };
        }
    }

    // 3. Category Restriction Check
    if (banner.category && banner.category !== 'all' && serviceCategory) {
        const catA = String(banner.category).toLowerCase().trim();
        const catB = String(serviceCategory).toLowerCase().trim();
        if (catA !== catB && !catB.includes(catA) && !catA.includes(catB)) {
            return { isValid: false, message: `Coupon code '${code}' is only valid for ${banner.category} services` };
        }
    }

    // 4. Minimum Order Value Check
    const orderAmt = Number(baseAmount) || 0;
    if (banner.minOrderValue && orderAmt < banner.minOrderValue) {
        return {
            isValid: false,
            message: `Minimum order amount of ₹${banner.minOrderValue} required to use coupon '${code}'`
        };
    }

    // 5. Calculate Discount Amount
    let discountAmount = 0;
    if (banner.discountPercent && banner.discountPercent > 0) {
        const calculated = Math.round(orderAmt * (banner.discountPercent / 100));
        const cap = banner.maxDiscount && banner.maxDiscount > 0 ? banner.maxDiscount : 500;
        discountAmount = Math.min(calculated, cap);
    } else if (banner.discountAmount && banner.discountAmount > 0) {
        discountAmount = Math.min(banner.discountAmount, orderAmt);
    } else if (banner.discount) {
        // Parse discount string like "50% OFF" or "₹100 FLAT"
        const percentMatch = String(banner.discount).match(/(\d+)\s*%/);
        const amountMatch = String(banner.discount).match(/(?:₹|RS|INR)?\s*(\d+)/i);
        if (percentMatch) {
            const pct = parseInt(percentMatch[1], 10);
            discountAmount = Math.min(Math.round(orderAmt * (pct / 100)), banner.maxDiscount || 500);
        } else if (amountMatch) {
            discountAmount = Math.min(parseInt(amountMatch[1], 10), orderAmt);
        }
    }

    discountAmount = Math.max(0, Math.min(discountAmount, orderAmt));
    const finalAmount = Math.max(0, orderAmt - discountAmount);

    return {
        isValid: true,
        couponCode: banner.code,
        title: banner.title,
        discount: banner.discount,
        discountAmount,
        finalAmount,
        minOrderValue: banner.minOrderValue || 0,
        maxDiscount: banner.maxDiscount || 0
    };
};

export default {
    validateAndCalculateCoupon
};
