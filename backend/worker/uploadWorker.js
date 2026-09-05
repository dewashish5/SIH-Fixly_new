import { Worker } from 'bullmq';
import fs from 'fs';
import redis from '../config/redis.js';
import { uploadToCloudinary } from '../utils/cloudinary.js';
import mongoose from 'mongoose';

// Import all models to ensure they are registered in Mongoose
import User from '../models/User.js';
import Booking from '../models/Booking.js';
import Review from '../models/Review.js';
import Service from '../models/Service.js';

import { v2 as cloudinary } from 'cloudinary';

const uploadWorker = new Worker('uploadQueue', async (job) => {
    const { modelName, recordId, fieldPath, filePath, isArray, folder = 'gigconnect' } = job.data;

    try {
        console.log(`Processing upload job ${job.id}: Uploading to Cloudinary folder '${folder}' for ${modelName} (${recordId}) field '${fieldPath}'`);
        
        let imageUrl = null;
        let localPathToDelete = null;

        const pathStr = typeof filePath === 'object' && filePath ? (filePath.path || filePath.filepath || '') : String(filePath || '');

        if (pathStr.startsWith('http://') || pathStr.startsWith('https://')) {
            imageUrl = pathStr;
        } else if (pathStr.startsWith('data:image/') || pathStr.startsWith('data:application/') || (pathStr.length > 500 && !pathStr.includes('/') && !pathStr.includes('\\'))) {
            // Upload Base64 directly to Cloudinary with resource_type: 'auto'
            const uploadResult = await new Promise((resolve, reject) => {
                cloudinary.uploader.upload(pathStr, { folder: folder || 'gigconnect', resource_type: 'auto' }, (err, res) => {
                    if (err) return reject(err);
                    resolve(res);
                });
            });
            imageUrl = uploadResult.secure_url;
        } else if (pathStr) {
            const cleanPath = pathStr.replace(/^file:\/\//, '');
            if (fs.existsSync(cleanPath)) {
                localPathToDelete = cleanPath;
                const fileBuffer = await fs.promises.readFile(cleanPath);
                const uploadResult = await uploadToCloudinary(fileBuffer, folder || 'gigconnect');
                imageUrl = uploadResult.secure_url;
            } else {
                console.warn(`File path not found on server disk: ${cleanPath}. Skipping Cloudinary upload.`);
                return;
            }
        }

        if (localPathToDelete && fs.existsSync(localPathToDelete)) {
            try {
                await fs.promises.unlink(localPathToDelete);
            } catch (err) {
                console.error(`Failed to clean up temp file ${localPathToDelete}:`, err.message);
            }
        }

        if (!imageUrl) return;

        // Resolve model and update database asynchronously
        const Model = mongoose.model(modelName);
        if (isArray) {
            await Model.findByIdAndUpdate(recordId, {
                $push: { [fieldPath]: imageUrl }
            }, { returnDocument: 'after' });
        } else {
            const updatedDoc = await Model.findByIdAndUpdate(recordId, {
                $set: { [fieldPath]: imageUrl }
            }, { returnDocument: 'after' });

            // Synchronize avatar to workerProfile.selfieImageUrl if avatar field was updated
            if (modelName === 'User' && fieldPath === 'avatar' && updatedDoc) {
                await Model.findByIdAndUpdate(recordId, {
                    $set: { 'workerProfile.selfieImageUrl': imageUrl }
                });
            }

            // Automatically sync identityDocuments array if worker document photo was uploaded
            if (modelName === 'User' && fieldPath.startsWith('workerProfile.') && updatedDoc && updatedDoc.workerProfile) {
                const wp = updatedDoc.workerProfile;
                const identityDocs = wp.identityDocuments || [];
                
                const existingAadhaar = identityDocs.find(d => d.docType === 'Aadhaar Card') || {};
                const existingPan = identityDocs.find(d => d.docType === 'PAN Card') || {};

                const updatedIdentityDocs = [
                    {
                        docType: 'Aadhaar Card',
                        docNumber: wp.aadhaarNumber || existingAadhaar.docNumber || null,
                        frontPhotoUrl: (fieldPath === 'workerProfile.aadhaarFrontPhoto' ? imageUrl : wp.aadhaarFrontPhoto) || existingAadhaar.frontPhotoUrl || null,
                        backPhotoUrl: (fieldPath === 'workerProfile.aadhaarBackPhoto' ? imageUrl : wp.aadhaarBackPhoto) || existingAadhaar.backPhotoUrl || null,
                        status: existingAadhaar.status || 'PENDING'
                    },
                    {
                        docType: 'PAN Card',
                        docNumber: wp.panNumber || existingPan.docNumber || null,
                        frontPhotoUrl: (fieldPath === 'workerProfile.panFrontPhoto' ? imageUrl : wp.panFrontPhoto) || existingPan.frontPhotoUrl || null,
                        backPhotoUrl: (fieldPath === 'workerProfile.panBackPhoto' ? imageUrl : wp.panBackPhoto) || existingPan.backPhotoUrl || null,
                        status: existingPan.status || 'PENDING'
                    }
                ];

                await Model.findByIdAndUpdate(recordId, {
                    $set: { 'workerProfile.identityDocuments': updatedIdentityDocs }
                }, { returnDocument: 'after' });
            }
        }

        console.log(`Job ${job.id} success: ${modelName} (${recordId}) field ${fieldPath} updated with Cloudinary URL: ${imageUrl}`);
    } catch (error) {
        console.error(`Upload job ${job.id} failed:`, error.message);
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
