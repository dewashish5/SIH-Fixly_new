import { uploadToCloudinary } from './cloudinary.js';
import fs from 'fs';

/**
 * Sequential & Controlled-Concurrency Upload Queue
 * Processes file and Base64 uploads to Cloudinary sequence-by-sequence
 * to guarantee orderly execution, prevent network timeouts, and save
 * resolved Cloudinary URLs directly to the database.
 */
export class UploadQueue {
    constructor(concurrency = 2) {
        this.concurrency = concurrency;
        this.running = 0;
        this.queue = [];
    }

    /**
     * Add an upload task to the queue
     * @param {string|object} fileSource - Base64 string, URL, or Multer file object
     * @param {string} folder - Target Cloudinary folder (e.g., 'gigconnect/avatars')
     * @returns {Promise<string|null>} - Resolves with Cloudinary secure_url
     */
    add(fileSource, folder = 'gigconnect') {
        if (!fileSource) return Promise.resolve(null);
        return new Promise((resolve, reject) => {
            this.queue.push({ fileSource, folder, resolve, reject });
            this.processNext();
        });
    }

    async processNext() {
        if (this.running >= this.concurrency || this.queue.length === 0) {
            return;
        }

        this.running++;
        const { fileSource, folder, resolve } = this.queue.shift();

        try {
            const url = await this.executeUpload(fileSource, folder);
            resolve(url);
        } catch (err) {
            console.error(`[UploadQueue] Error uploading to folder ${folder}:`, err.message);
            resolve(null);
        } finally {
            this.running--;
            this.processNext();
        }
    }

    async executeUpload(fileSource, folder) {
        if (!fileSource) return null;

        // 1. If already an HTTP/HTTPS URL, return as is
        if (typeof fileSource === 'string' && (fileSource.startsWith('http://') || fileSource.startsWith('https://'))) {
            return fileSource;
        }

        // 2. If Multer file object from req.files or req.file
        if (typeof fileSource === 'object' && fileSource) {
            const filePath = fileSource.path || fileSource.filepath;
            if (filePath && fs.existsSync(filePath)) {
                try {
                    const result = await uploadToCloudinary(filePath, folder);
                    await fs.promises.unlink(filePath).catch(() => {});
                    return result?.secure_url || null;
                } catch (err) {
                    if (fs.existsSync(filePath)) {
                        await fs.promises.unlink(filePath).catch(() => {});
                    }
                    throw err;
                }
            }
            if (fileSource.buffer) {
                const result = await uploadToCloudinary(fileSource.buffer, folder);
                return result?.secure_url || null;
            }
        }

        // 3. If Base64 string (Data URI or raw base64)
        if (typeof fileSource === 'string' && (
            fileSource.startsWith('data:image') ||
            fileSource.startsWith('data:application/pdf') ||
            fileSource.startsWith('data:application/') ||
            (fileSource.length > 500 && !fileSource.includes('/') && !fileSource.includes('\\'))
        )) {
            const result = await uploadToCloudinary(fileSource, folder);
            return result?.secure_url || null;
        }

        // 4. If local disk path string
        if (typeof fileSource === 'string' && fileSource.trim()) {
            const cleanPath = fileSource.replace(/^file:\/\//, '');
            if (fs.existsSync(cleanPath)) {
                const result = await uploadToCloudinary(cleanPath, folder);
                await fs.promises.unlink(cleanPath).catch(() => {});
                return result?.secure_url || null;
            }
        }

        return null;
    }
}

// Export singleton instance of UploadQueue
export const uploadQueueManager = new UploadQueue(2);
