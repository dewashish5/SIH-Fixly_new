export const buildCategoryCondition = (category) => {
    const trimmed = String(category ?? '').trim();
    if (!trimmed) return null;

    const escaped = trimmed.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    const categoryAliases = {
        plumber: 'plumb',
        electrician: 'electric',
        carpenter: 'carpent',
        painter: 'paint',
        gardener: 'garden',
        domestic_helper: 'domestic|helper',
        caregiving: 'caregiv|care',
        driver: 'driver',
        technician: 'technician|tech',
        cleaning: 'clean',
    };
    const matcher = categoryAliases[trimmed.toLowerCase()] ?? escaped;
    const categoryRegex = new RegExp(matcher, 'i');

    return {
        $or: [
            { 'workerProfile.category': { $regex: categoryRegex } },
            { 'workerProfile.categories': { $regex: categoryRegex } },
            { 'workerProfile.categoryRates.category': { $regex: categoryRegex } },
        ],
    };
};
