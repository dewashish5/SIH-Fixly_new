import { uploadToCloudinary, uploadMulterFiles } from '../utils/cloudinary.js';

// POST /api/upload  field: file
export const uploadSingle = async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({ success: false, message: 'file required' });
        }
        const result = await uploadToCloudinary(req.file.buffer);
        return res.status(201).json({
            success: true,
            url: result.secure_url,
            publicId: result.public_id,
        });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

// POST /api/upload/many  field: files
export const uploadMany = async (req, res) => {
    try {
        if (!req.files?.length) {
            return res.status(400).json({ success: false, message: 'files required' });
        }
        const urls = await uploadMulterFiles(req.files);
        return res.status(201).json({ success: true, urls });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};
