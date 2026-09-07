export const getRequestLanguage = (req) => {
    const qLang = req.query?.lang;
    if (qLang && (qLang === 'hi' || qLang === 'en')) return qLang;

    const userLang = req.user?.preferredLanguage;
    if (userLang && (userLang === 'hi' || userLang === 'en')) return userLang;

    const header = req.headers?.['accept-language'];
    if (header && header.toLowerCase().includes('hi')) return 'hi';

    return 'en';
};

export const localizeService = (service, lang = 'en') => {
    if (!service) return service;
    const isDoc = typeof service.toObject === 'function';
    const obj = isDoc ? service.toObject() : { ...service };

    if (lang === 'hi') {
        obj.displayTitle = obj.titleI18n?.hi || obj.title;
        obj.displayCategory = obj.categoryI18n?.hi || obj.category;
        obj.displayDescription = obj.descriptionI18n?.hi || obj.description || '';
        obj.displayWhatsIncluded = (obj.whatsIncludedI18n?.hi && obj.whatsIncludedI18n.hi.length)
            ? obj.whatsIncludedI18n.hi
            : obj.whatsIncluded;
    } else {
        obj.displayTitle = obj.titleI18n?.en || obj.title;
        obj.displayCategory = obj.categoryI18n?.en || obj.category;
        obj.displayDescription = obj.descriptionI18n?.en || obj.description || '';
        obj.displayWhatsIncluded = (obj.whatsIncludedI18n?.en && obj.whatsIncludedI18n.en.length)
            ? obj.whatsIncludedI18n.en
            : obj.whatsIncluded;
    }

    return obj;
};

export const localizeServices = (services, lang = 'en') => {
    if (!Array.isArray(services)) return [];
    return services.map((s) => localizeService(s, lang));
};
