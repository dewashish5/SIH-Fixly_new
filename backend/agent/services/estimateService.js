import Service from "../../models/Service.js";

/**
 * Calculate transparent cost estimate and cooperative fair wage policy
 */
export const calculateEstimate = async ({ category, workerRate = null, isEmergency = false, lang = "en" }) => {
    let service = null;
    if (category) {
        service = await Service.findOne({ category: new RegExp(`^${category}$`, 'i') }).lean();
    }
    if (!service) {
        service = await Service.findOne({ isActive: true }).lean();
    }

    const basePrice = workerRate || service?.basePrice || 250;
    const urgentFee = isEmergency ? 50 : 0;
    const platformFee = 0; // Fixly 0% Middleman Platform Fee
    const welfareContribution = Math.round(basePrice * 0.05); // 5% Social Security & Insurance
    const totalAmount = basePrice + urgentFee + platformFee;

    const isHi = lang === "hi";

    const estimate = {
        baseServiceFee: basePrice,
        urgentFee,
        platformFee,
        welfareContribution,
        totalAmount,
        currency: "INR"
    };

    const policy = {
        title: isHi ? "Fixly सहकारी निष्पक्ष मजदूरी नीति" : "Fixly Cooperative Fair Wage Guarantee",
        fairWageNotice: isHi
            ? "सेवा शुल्क का 100% सीधे कार्यकर्ता को दिया जाता है।"
            : "100% of the service fee goes directly to the cooperative worker.",
        welfareFundNotice: isHi
            ? "इसमें कार्यकर्ता सामाजिक सुरक्षा और दुर्घटना बीमा कोष का 5% शामिल है।"
            : "Includes 5% contribution to Worker Social Security & Medical Accident Fund.",
        platformCommission: "0% Platform Fee (No Middleman)"
    };

    return { estimate, policy };
};

export default {
    calculateEstimate
};
