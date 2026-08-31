/**
 * Local Mongo seed for Fixly.
 *
 * Run (from bakend-master root):
 *   MONGO_URI=mongodb://127.0.0.1:27017/Fixly node scripts/seed-local.js
 *
 * Docker Compose Mongo:
 *   MONGO_URI=mongodb://localhost:27017/Fixly node scripts/seed-local.js
 *
 * Upserts: service catalog, admin, demo customer, verified worker.
 */
import dotenv from 'dotenv';
dotenv.config();

import mongoose from 'mongoose';
import User from '../models/User.js';
import Service from '../models/Service.js';

const MONGO_URI = process.env.MONGO_URI || 'mongodb://127.0.0.1:27017/Fixly';

const SERVICES = [
    {
        title: 'Fan Installation',
        category: 'electrician',
        image: 'https://placehold.co/600x400/01668F/FFFFFF?text=Fan+Install',
        basePrice: 299,
        estimatedTime: '45 mins',
        whatsIncluded: ['Ceiling fan mount', 'Wiring check', 'Test run'],
        isActive: true
    },
    {
        title: 'Switchboard Repair',
        category: 'electrician',
        image: 'https://placehold.co/600x400/01668F/FFFFFF?text=Switchboard',
        basePrice: 199,
        estimatedTime: '30 mins',
        whatsIncluded: ['Fault diagnosis', 'Switch/socket fix', 'Safety check'],
        isActive: true
    },
    {
        title: 'Tap Leak Fix',
        category: 'plumber',
        image: 'https://placehold.co/600x400/01668F/FFFFFF?text=Tap+Leak',
        basePrice: 249,
        estimatedTime: '40 mins',
        whatsIncluded: ['Washer/gasket replace', 'Leak test', 'Cleanup'],
        isActive: true
    },
    {
        title: 'Drain Unclogging',
        category: 'plumber',
        image: 'https://placehold.co/600x400/01668F/FFFFFF?text=Drain',
        basePrice: 349,
        estimatedTime: '1 Hour',
        whatsIncluded: ['Blockage clear', 'Pipe flush', 'Flow check'],
        isActive: true
    },
    {
        title: 'Door Hinge Repair',
        category: 'carpenter',
        image: 'https://placehold.co/600x400/01668F/FFFFFF?text=Door+Hinge',
        basePrice: 279,
        estimatedTime: '45 mins',
        whatsIncluded: ['Hinge align/replace', 'Door swing test', 'Touch-up'],
        isActive: true
    },
    {
        title: 'Furniture Assembly',
        category: 'carpenter',
        image: 'https://placehold.co/600x400/01668F/FFFFFF?text=Furniture',
        basePrice: 499,
        estimatedTime: '2 Hours',
        whatsIncluded: ['Flat-pack assembly', 'Hardware install', 'Level check'],
        isActive: true
    }
];

const NEAR_POINT = {
    type: 'Point',
    coordinates: [77.39, 28.53] // [lng, lat]
};

async function upsertService(data) {
    const doc = await Service.findOneAndUpdate(
        { title: data.title, category: data.category },
        { $set: data },
        { upsert: true, new: true, setDefaultsOnInsert: true }
    );
    return doc;
}

async function upsertUserByEmail(email, fields) {
    let user = await User.findOne({ email: email.toLowerCase().trim() });
    if (!user) {
        user = new User({ email: email.toLowerCase().trim(), ...fields });
        await user.save(); // pre('save') hashes password
        return { user, created: true };
    }

    const { password, ...rest } = fields;
    Object.assign(user, rest);
    if (password) {
        user.password = password; // re-hash via pre-save when modified
    }
    await user.save();
    return { user, created: false };
}

async function seed() {
    console.log(`Connecting: ${MONGO_URI}`);
    await mongoose.connect(MONGO_URI);
    console.log('Mongo connected');

    for (const svc of SERVICES) {
        const doc = await upsertService(svc);
        console.log(`Service upserted: ${doc.category} / ${doc.title}`);
    }

    const { user: admin, created: adminCreated } = await upsertUserByEmail('admin@fixly.local', {
        name: 'Fixly Admin',
        password: 'Admin123!',
        role: 'admin',
        authProvider: 'local',
        isVerified: true,
        location: NEAR_POINT,
        phone: '9999999999'
    });
    console.log(`Admin ${adminCreated ? 'created' : 'updated'}: ${admin.email}`);

    const { user: customer, created: customerCreated } = await upsertUserByEmail('customer@fixly.local', {
        name: 'Demo Customer',
        password: 'Customer123!',
        role: 'customer',
        authProvider: 'local',
        isVerified: true,
        location: {
            type: 'Point',
            coordinates: [77.391, 28.531]
        },
        phone: '9888888888',
        savedAddresses: [{
            label: 'Home',
            addressLine: 'Sector 62, Noida',
            city: 'Noida',
            pincode: '201301',
            location: {
                type: 'Point',
                coordinates: [77.391, 28.531]
            }
        }]
    });
    console.log(`Customer ${customerCreated ? 'created' : 'updated'}: ${customer.email}`);

    const { user: worker, created: workerCreated } = await upsertUserByEmail('worker@fixly.local', {
        name: 'Demo Worker',
        password: 'Worker123!',
        role: 'worker',
        authProvider: 'local',
        isVerified: true,
        location: {
            type: 'Point',
            coordinates: [77.389, 28.529]
        },
        phone: '9777777777',
        workerProfile: {
            category: 'electrician',
            hourlyRate: 250,
            experienceYears: 4,
            bio: 'Local verified electrician for Fixly demo',
            rating: 4.8,
            totalJobs: 42,
            recentWorkPhotos: [],
            badges: ['Background Checked', 'Verified'],
            skills: ['wiring', 'fan', 'switchboard'],
            certifications: ['ITI Electrical']
        }
    });
    console.log(`Worker ${workerCreated ? 'created' : 'updated'}: ${worker.email}`);

    console.log('\nSeed done.');
    console.log('Admin login: admin@fixly.local / Admin123!');
    console.log('Customer:    customer@fixly.local / Customer123!');
    console.log('Worker:      worker@fixly.local / Worker123!');
}

seed()
    .catch((err) => {
        console.error('Seed failed:', err);
        process.exitCode = 1;
    })
    .finally(async () => {
        await mongoose.disconnect();
    });
