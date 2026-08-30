import multer from 'multer';
import { uploadQueue } from '../queues/queue.js';

// Disk storage stores files temporarily in the OS default temp folder (e.g. /tmp)
const storage = multer.diskStorage({});

const fileFilter = (req, file, cb) => {
    if (file.mimetype.startsWith('image/') || file.mimetype.startsWith('video/')) {
        cb(null, true);
    } else {
        cb(new Error('Only image and video files are allowed!'), false);
    }
};

// Multer upload middleware
export const upload = multer({ storage, fileFilter });

/**
 * Queues a file upload task to Cloudinary in the background
 * @param {string} modelName - The mongoose Model name (e.g., 'Booking', 'User')
 * @param {string|ObjectId} recordId - Target database document ID
 * @param {string} fieldPath - Document field path to save the URL (e.g., 'problemPhotos')
 * @param {object} file - The file object injected by Multer (contains file.path)
 * @param {boolean} isArray - Set to true if target field is an Array of URLs
 */
export const queueFileUpload = async (modelName, recordId, fieldPath, file, isArray = false) => {
    if (!file || !file.path) return;
    
    await uploadQueue.add('uploadFile', {
        modelName,
        recordId,
        fieldPath,
        filePath: file.path,
        isArray
    });
};