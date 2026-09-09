import fs from 'fs';

let content = fs.readFileSync('backend/utils/cloudinary.js', 'utf8');

const newCode = `import { v2 as cloudinary } from 'cloudinary';
import dotenv from 'dotenv';
import Settings from '../models/Settings.js';
dotenv.config();

// Default config
cloudinary.config({
    cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
    api_key: process.env.CLOUDINARY_API_KEY,
    api_secret: process.env.CLOUDINARY_API_SECRET
});

async function configureCloudinary() {
    try {
        const settings = await Settings.findOne({});
        let url = settings?.apiKeys?.cloudinaryUrl || process.env.CLOUDINARY_URL;
        if (url && url.startsWith('cloudinary://')) {
            const parsed = new URL(url);
            cloudinary.config({
                cloud_name: parsed.hostname,
                api_key: parsed.username,
                api_secret: parsed.password
            });
        }
    } catch(e) {}
}

/**
 * Uploads a file buffer, disk path, or base64 string directly to Cloudinary
`;

content = content.replace(/import \{ v2 as cloudinary \}.*?\/\*\*/s, newCode);
content = content.replace(/(export const uploadToCloudinary = \(.*?\) => \{.*?)return new Promise\(/s, "$1    await configureCloudinary();\n    return new Promise(");
content = content.replace(/(export const uploadDataUriOrUrl = async \(.*?\) => \{)/, "$1\n    await configureCloudinary();");

fs.writeFileSync('backend/utils/cloudinary.js', content);
