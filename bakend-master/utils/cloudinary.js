import { v2 as cloudinary } from 'cloudinary';
import dotenv from 'dotenv';
dotenv.config();

cloudinary.config({
    cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
    api_key: process.env.CLOUDINARY_API_KEY,
    api_secret: process.env.CLOUDINARY_API_SECRET,
});

/**
 * Uploads an image buffer directly to Cloudinary
 * @param {Buffer} fileBuffer - The memory buffer of the file uploaded via Multer
 * @param {string} folderName - Cloudinary folder name
 * @returns {Promise<object>} - Resolves with Cloudinary upload response object
 */
export const uploadToCloudinary = (fileBuffer, folderName = 'gigconnect') => {
    return new Promise((resolve, reject) => {
        const uploadStream = cloudinary.uploader.upload_stream(
            { folder: folderName },
            (error, result) => {
                if (error) return reject(error);
                resolve(result);
            }
        );
        uploadStream.end(fileBuffer);
    });
};
