export const getRequestLanguage = (req) => {
    const supported = ['en', 'hi', 'ta', 'te', 'kn', 'bn', 'mr', 'gu'];
    const qLang = req.query?.lang;
    if (qLang && supported.includes(qLang)) return qLang;

    const userLang = req.user?.preferredLanguage;
    if (userLang && supported.includes(userLang)) return userLang;

    const header = req.headers?.['accept-language'];
    if (header) {
        for (const lang of supported) {
            if (header.toLowerCase().includes(lang)) return lang;
        }
    }

    return 'en';
};

export const localizeService = (service, lang = 'en') => {
    if (!service) return service;
    const isDoc = typeof service.toObject === 'function';
    const obj = isDoc ? service.toObject() : { ...service };

    if (lang !== 'en') {
        obj.displayTitle = obj.titleI18n?.[lang] || obj.title;
        obj.displayCategory = obj.categoryI18n?.[lang] || obj.category;
        obj.displayDescription = obj.descriptionI18n?.[lang] || obj.description || '';
        obj.displayWhatsIncluded = (obj.whatsIncludedI18n?.[lang] && obj.whatsIncludedI18n[lang].length)
            ? obj.whatsIncludedI18n[lang]
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
