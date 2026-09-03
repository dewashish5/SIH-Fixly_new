import { v2 as cloudinary } from 'cloudinary';
import dotenv from 'dotenv';
dotenv.config();

cloudinary.config({
    cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
    api_key: process.env.CLOUDINARY_API_KEY,
    api_secret: process.env.CLOUDINARY_API_SECRET,
});

/**
 * Uploads a buffer to Cloudinary (images/docs via resource_type auto).
 * @param {Buffer} fileBuffer - Multer memory buffer
 * @param {string} folderName - Cloudinary folder
 * @returns {Promise<object>} Cloudinary upload result
 */
export const uploadToCloudinary = (fileBuffer, folderName = 'gigconnect') => {
    return new Promise((resolve, reject) => {
        const uploadStream = cloudinary.uploader.upload_stream(
            { folder: folderName, resource_type: 'auto' },
            (error, result) => {
                if (error) return reject(error);
                resolve(result);
            }
        );
        uploadStream.end(fileBuffer);
    });
};

/** @param {Express.Multer.File[]} files */
export const uploadMulterFiles = async (files, folderName = 'gigconnect') => {
    if (!files?.length) return [];
    const results = await Promise.all(
        files.map((f) => uploadToCloudinary(f.buffer, folderName))
    );
    return results.map((r) => r.secure_url);
};

/**
 * Upload http URL (passthrough), data URI, or raw base64 → Cloudinary URL.
 * @returns {Promise<string|null>}
 */
export const uploadDataUriOrUrl = async (value, folderName = 'gigconnect') => {
    if (!value || typeof value !== 'string') return null;
    const trimmed = value.trim();
    if (!trimmed) return null;
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
        return trimmed;
    }
    const payload = trimmed.startsWith('data:')
        ? trimmed
        : `data:application/octet-stream;base64,${trimmed}`;
    const result = await cloudinary.uploader.upload(payload, {
        folder: folderName,
        resource_type: 'auto',
    });
    return result.secure_url;
};
