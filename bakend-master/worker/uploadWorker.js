import { Worker } from 'bullmq';
import fs from 'fs';
import redis from '../config/redis.js';
import { uploadToCloudinary } from '../utils/cloudinary.js';
import mongoose from 'mongoose';

// Import all models to ensure they are registered in mongoose
import User from '../models/User.js';
import Booking from '../models/Booking.js';
import Review from '../models/Review.js';
import Service from '../models/Service.js';

const uploadWorker = new Worker('uploadQueue', async (job) => {
    const { modelName, recordId, fieldPath, filePath, isArray } = job.data;

    try {
        console.log(`Processing upload job ${job.id}: Uploading ${filePath} to Cloudinary for ${modelName} (${recordId})`);
        
        if (!fs.existsSync(filePath)) {
            throw new Error(`Temp file not found on disk: ${filePath}`);
        }

        // Read file from disk
        const fileBuffer = await fs.promises.readFile(filePath);

        // Upload to Cloudinary
        const uploadResult = await uploadToCloudinary(fileBuffer);
        const imageUrl = uploadResult.secure_url;

        // Delete local temp file from disk
        await fs.promises.unlink(filePath);

        // Resolve model and update database
        const Model = mongoose.model(modelName);
        if (isArray) {
            // Push URL to array field (e.g. problemPhotos)
            await Model.findByIdAndUpdate(recordId, {
                $push: { [fieldPath]: imageUrl }
            });
        } else {
            // Set URL on string field (e.g. avatar, image)
            await Model.findByIdAndUpdate(recordId, {
                $set: { [fieldPath]: imageUrl }
            });
        }

        console.log(`Job ${job.id} success: ${modelName} (${recordId}) field ${fieldPath} updated with Cloudinary URL: ${imageUrl}`);
    } catch (error) {
        console.error(`Upload job ${job.id} failed:`, error.message);
        
        // Clean up temp file if it still exists
        if (fs.existsSync(filePath)) {
            try {
                await fs.promises.unlink(filePath);
            } catch (err) {
                console.error(`Failed to clean up temp file ${filePath}:`, err.message);
            }
        }
        throw error;
    }
}, {
    connection: redis,
    concurrency: 5
});

uploadWorker.on('completed', (job) => {
    console.log(`Upload Job ${job.id} completed successfully.`);
});

uploadWorker.on('failed', (job, err) => {
    console.error(`Upload Job ${job.id} failed with error: ${err.message}`);
});

export default uploadWorker;
