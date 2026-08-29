export const searchServices = async (req, res) => {
    res.status(200).json({ success: true, message: 'Search API active' });
};

export const getCategories = async (req, res) => {
    res.status(200).json({ success: true, message: 'Categories API active' });
};

export const getExtraPartsCatalog = async (req, res) => {
    res.status(200).json({ success: true, message: 'Extra parts API active' });
};

export const getServiceDetails = async (req, res) => {
    res.status(200).json({ success: true, message: 'Service details API active' });
};