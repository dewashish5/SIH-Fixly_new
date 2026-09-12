// middleware/uploadMiddleware.js
import multer from 'multer';

// Memory storage use kar rahe hain taaki directly cloud (Cloudinary/S3) par upload kar sakein
const storage = multer.memoryStorage();

const upload = multer({
    storage,
    limits: { fileSize: 5 * 1024 * 1024 } // Limit: 5MB per image
});

export default upload;