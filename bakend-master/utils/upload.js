import multer from 'multer';
import { uploadQueue } from '../queues/queue.js';

// Disk storage stores files temporarily in OS default temp folder
const storage = multer.diskStorage({});

const fileFilter = (req, file, cb) => {
    // Allow images, videos, PDFs, and document files
    if (
        !file.mimetype ||
        file.mimetype.startsWith('image/') ||
        file.mimetype.startsWith('video/') ||
        file.mimetype.startsWith('application/') ||
        file.mimetype === 'application/pdf'
    ) {
        cb(null, true);
    } else {
        cb(new Error('Only image, video, and document files are allowed!'), false);
    }
};

export const upload = multer({ storage, fileFilter });

/**
 * Queues a file upload task to Cloudinary in the background via BullMQ uploadQueue
 * @param {string} modelName - Target Mongoose Model name ('User', 'Booking')
 * @param {string|ObjectId} recordId - Target document _id
 * @param {string} fieldPath - Schema field path (e.g., 'avatar', 'workerProfile.aadhaarFrontPhoto')
 * @param {object|string} fileSource - Multer file object, disk path, or Base64 string
 * @param {boolean} isArray - True if field is an array of URLs
 * @param {string} folder - Cloudinary folder path
 */
export const queueFileUpload = async (modelName, recordId, fieldPath, fileSource, isArray = false, folder = 'gigconnect') => {
    if (!fileSource) return;
    try {
        const filePath = typeof fileSource === 'object' && fileSource ? (fileSource.path || fileSource.filepath || fileSource) : fileSource;
        await uploadQueue.add('uploadTask', {
            modelName,
            recordId: recordId.toString(),
            fieldPath,
            filePath,
            isArray,
            folder
        });
    } catch (err) {
        console.error(`Failed to enqueue upload task for ${modelName} (${recordId}):`, err.message);
    }
};