import { translateService, translateServices, CATEGORY_DICTIONARY } from '../services/translationService.js';

export const getRequestLanguage = (req) => {
    const supported = ['en', 'hi', 'ta', 'te', 'kn', 'bn', 'mr', 'gu', 'pa'];
    const qLang = req.query?.lang;
    if (qLang && supported.includes(qLang.toLowerCase())) return qLang.toLowerCase();

    const userLang = req.user?.preferredLanguage;
    if (userLang && supported.includes(userLang.toLowerCase())) return userLang.toLowerCase();

    const header = req.headers?.['accept-language'];
    if (header) {
        const clean = header.toLowerCase();
        for (const lang of supported) {
            if (clean.startsWith(lang) || clean.includes(lang)) return lang;
        }
    }

    return 'en';
};

export const localizeService = async (service, lang = 'en') => {
    if (!service) return service;
    return await translateService(service, lang);
};

export const localizeServices = async (services, lang = 'en') => {
    if (!Array.isArray(services)) return [];
    return await translateServices(services, lang);
};

export const localizeCategories = (categories, lang = 'en') => {
    if (!Array.isArray(categories)) return [];
    if (!lang || lang === 'en') return categories;
    return categories.map(cat => {
        const lower = String(cat).toLowerCase().trim();
        return CATEGORY_DICTIONARY[lower]?.[lang] || cat;
    });
};
