import dotenv from 'dotenv';
dotenv.config();

import mongoose from 'mongoose';
import User from '../models/User.js';
import Service from '../models/Service.js';
import Booking from '../models/Booking.js';
import Review from '../models/Review.js';
import Transaction from '../models/Transaction.js';

const MONGO_URI = process.env.MONGO_URI || 'mongodb://localhost:27017/Cooperative';

const sampleServices = [
  {
    title: 'Plumbing Leakage & Pipe Repair',
    category: 'Plumbing',
    image: 'https://images.unsplash.com/photo-1585704032915-c3400ca199e7?w=500&auto=format&fit=crop&q=80',
    basePrice: 350,
    estimatedTime: '1 Hour',
    whatsIncluded: ['Pipe Leakage Check', 'Tape & Joint Sealing', 'Tap/Mixer Replacement'],
    isActive: true
  },
  {
    title: 'Short Circuit & Electrical Wiring Repair',
    category: 'Electrical',
    image: 'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?w=500&auto=format&fit=crop&q=80',
    basePrice: 400,
    estimatedTime: '1.5 Hours',
    whatsIncluded: ['MCB & Fuse Inspection', 'Short Circuit Detection', 'Switchboard Repair'],
    isActive: true
  },
  {
    title: 'AC Jet Servicing & Gas Refill',
    category: 'AC Repair',
    image: 'https://images.unsplash.com/photo-1621905252507-b35492cc74b4?w=500&auto=format&fit=crop&q=80',
    basePrice: 599,
    estimatedTime: '2 Hours',
    whatsIncluded: ['High Pressure Foam Jet Wash', 'Gas Pressure Check', 'Filter Cleaning'],
    isActive: true
  },
  {
    title: 'Furniture Repair & Custom Carpentry',
    category: 'Carpentry',
    image: 'https://images.unsplash.com/photo-1538688525198-9b88f6f53126?w=500&auto=format&fit=crop&q=80',
    basePrice: 450,
    estimatedTime: '2 Hours',
    whatsIncluded: ['Door Hinge Adjustment', 'Drawer Lock Fitting', 'Wood Sanding & Fix'],
    isActive: true
  },
  {
    title: 'Full House Deep Cleaning & Sanitization',
    category: 'Cleaning',
    image: 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=500&auto=format&fit=crop&q=80',
    basePrice: 1299,
    estimatedTime: '4 Hours',
    whatsIncluded: ['Floor Scrubbing', 'Kitchen & Bathroom Degreasing', 'Window Glass Wash'],
    isActive: true
  },
  {
    title: 'Wall Painting & Waterproofing Touchup',
    category: 'Painting',
    image: 'https://images.unsplash.com/photo-1562259949-e8e7689d7828?w=500&auto=format&fit=crop&q=80',
    basePrice: 899,
    estimatedTime: '3 Hours',
    whatsIncluded: ['Wall Putty Primer', 'Double Coat Emulsion Paint', 'Floor Protection Cover'],
    isActive: true
  }
];

const sampleWorkers = [
  {
    name: 'Sarah Jenkins',
    email: 'sarah.jenkins@gigconnect.com',
    phone: '+91 9876543209',
    avatar: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=500&auto=format&fit=crop&q=80',
    password: 'WorkerPass123!',
    role: 'worker',
    isVerified: true,
    location: { type: 'Point', coordinates: [77.3639, 28.6280] },
    savedAddresses: [{ label: 'Home', addressLine: 'Sector 62, Noida', city: 'Noida', pincode: '201301', location: { type: 'Point', coordinates: [77.3639, 28.6280] } }],
    workerProfile: {
      category: 'Plumbing',
      categories: ['Plumbing'],
      rate: 85,
      hourlyRate: 85,
      experienceYears: 7,
      bio: 'Master Plumber with 7+ years experience in leak detection and residential piping.',
      rating: 4.9,
      totalJobs: 142,
      isOnline: true,
      recentWorkPhotos: ['https://images.unsplash.com/photo-1585704032915-c3400ca199e7?w=500'],
      badges: ['Master Plumber', 'Top Rated', 'Verified Worker'],
      skills: ['Pipe Fitting', 'Leak Detection', 'Bathroom Fitting', 'Water Heater Repair']
    }
  },
  {
    name: 'Rajesh Kumar',
    email: 'rajesh.worker@gigconnect.com',
    phone: '+91 9876543210',
    avatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=500&auto=format&fit=crop&q=80',
    password: 'WorkerPass123!',
    role: 'worker',
    isVerified: true,
    location: { type: 'Point', coordinates: [77.3710, 28.6310] },
    savedAddresses: [{ label: 'Home', addressLine: 'Sector 62, Noida', city: 'Noida', pincode: '201301', location: { type: 'Point', coordinates: [77.3710, 28.6310] } }],
    workerProfile: {
      category: 'Plumbing',
      categories: ['Plumbing'],
      rate: 350,
      hourlyRate: 350,
      experienceYears: 6,
      bio: 'Expert plumber with 6+ years experience in commercial and residential piping.',
      rating: 4.9,
      totalJobs: 142,
      isOnline: true,
      recentWorkPhotos: ['https://images.unsplash.com/photo-1585704032915-c3400ca199e7?w=500'],
      badges: ['Background Checked', 'Top Rated Plumber', 'Verified Worker'],
      skills: ['Pipe Fitting', 'Bathroom Fitting', 'Leak Detection', 'Geyser Installation']
    }
  },
  {
    name: 'Amit Sharma',
    email: 'amit.electrician@gigconnect.com',
    phone: '+91 9876543211',
    avatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=500&auto=format&fit=crop&q=80',
    password: 'WorkerPass123!',
    role: 'worker',
    isVerified: true,
    location: { type: 'Point', coordinates: [77.2167, 28.6328] },
    savedAddresses: [{ label: 'Work Base', addressLine: 'Connaught Place, New Delhi', city: 'New Delhi', pincode: '110001', location: { type: 'Point', coordinates: [77.2167, 28.6328] } }],
    workerProfile: {
      category: 'Electrical',
      categories: ['Electrical'],
      rate: 400,
      hourlyRate: 400,
      experienceYears: 8,
      bio: 'Licensed electrician specializing in short-circuits, heavy load meters & MCB boxes.',
      rating: 4.8,
      totalJobs: 98,
      isOnline: true,
      recentWorkPhotos: ['https://images.unsplash.com/photo-1621905251189-08b45d6a269e?w=500'],
      badges: ['Background Checked', 'Certified Electrician', 'Verified Worker'],
      skills: ['Wiring Repair', 'MCB Box Setup', '3-Phase Connection', 'Inverter Setup']
    }
  },
  {
    name: 'Vikram Singh',
    email: 'vikram.ac@gigconnect.com',
    phone: '+91 9876543212',
    avatar: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=500&auto=format&fit=crop&q=80',
    password: 'WorkerPass123!',
    role: 'worker',
    isVerified: true,
    location: { type: 'Point', coordinates: [77.0882, 28.4950] },
    savedAddresses: [{ label: 'Hub', addressLine: 'Cyber City, Gurgaon', city: 'Gurgaon', pincode: '122002', location: { type: 'Point', coordinates: [77.0882, 28.4950] } }],
    workerProfile: {
      category: 'AC Repair',
      categories: ['AC Repair'],
      rate: 500,
      hourlyRate: 500,
      experienceYears: 5,
      bio: 'Professional HVAC & split AC service technician. Specialist in R32/R410 gas refilling.',
      rating: 4.9,
      totalJobs: 210,
      isOnline: true,
      recentWorkPhotos: ['https://images.unsplash.com/photo-1621905252507-b35492cc74b4?w=500'],
      badges: ['Top Rated AC Tech', 'Verified Worker'],
      skills: ['Jet Servicing', 'Gas Leak Repair', 'Compressor Replacement', 'PCB Repair']
    }
  }
];

const sampleCustomers = [
  {
    name: 'Priya Sharma',
    email: 'priya.sharma@example.com',
    phone: '+91 9123456789',
    password: 'CustomerPass123!',
    role: 'customer',
    isVerified: true,
    savedAddresses: [{ label: 'Home', addressLine: 'Tower 4, Jaypee Greens, Noida', city: 'Noida', pincode: '201304', location: { type: 'Point', coordinates: [77.3500, 28.5355] } }]
  },
  {
    name: 'Rohan Verma',
    email: 'rohan.verma@example.com',
    phone: '+91 9123456790',
    password: 'CustomerPass123!',
    role: 'customer',
    isVerified: true,
    savedAddresses: [{ label: 'Apartment', addressLine: 'Flat 302, DLF Phase 5, Gurgaon', city: 'Gurgaon', pincode: '122009', location: { type: 'Point', coordinates: [77.0900, 28.4590] } }]
  }
];

const seedDatabase = async () => {
  try {
    console.log('⏳ Connecting to MongoDB...');
    await mongoose.connect(MONGO_URI);
    console.log('✅ Connected to MongoDB successfully');

    // 1. Clear existing seed collections
    console.log('🧹 Clearing old seed data...');
    await Service.deleteMany({});
    await User.deleteMany({ role: { $in: ['worker', 'customer'] } });
    await Booking.deleteMany({});
    await Review.deleteMany({});
    await Transaction.deleteMany({});

    // 2. Insert Services
    console.log('📦 Seeding Services catalog...');
    const insertedServices = await Service.insertMany(sampleServices);
    console.log(`✅ Seeded ${insertedServices.length} Services`);

    // 3. Insert Workers
    console.log('👷 Seeding Worker profiles...');
    const insertedWorkers = await User.create(sampleWorkers);
    console.log(`✅ Seeded ${insertedWorkers.length} Workers`);

    // 4. Insert Customers
    console.log('👤 Seeding Customer profiles...');
    const insertedCustomers = await User.create(sampleCustomers);
    console.log(`✅ Seeded ${insertedCustomers.length} Customers`);

    // 5. Insert 20 Bookings across all 5 categories for realistic dynamic aggregation
    console.log('📅 Seeding 20 Bookings with realistic category distribution...');
    
    // 5 Plumbing (25%), 4 Electrical (20%), 3 Cleaning (15%), 3 Carpentry (15%), 5 AC Repair/Others (25%)
    const bookingConfigs = [
      // Plumbing (5)
      { serviceIdx: 0, status: 'COMPLETED', amount: 465 },
      { serviceIdx: 0, status: 'COMPLETED', amount: 350 },
      { serviceIdx: 0, status: 'ACCEPTED', amount: 350 },
      { serviceIdx: 0, status: 'IN_PROGRESS', amount: 350 },
      { serviceIdx: 0, status: 'COMPLETED', amount: 500 },

      // Electrical (4)
      { serviceIdx: 1, status: 'ACCEPTED', amount: 420 },
      { serviceIdx: 1, status: 'COMPLETED', amount: 400 },
      { serviceIdx: 1, status: 'COMPLETED', amount: 400 },
      { serviceIdx: 1, status: 'COMPLETED', amount: 450 },

      // Cleaning (3)
      { serviceIdx: 4, status: 'COMPLETED', amount: 1349 },
      { serviceIdx: 4, status: 'COMPLETED', amount: 1299 },
      { serviceIdx: 4, status: 'ACCEPTED', amount: 1299 },

      // Carpentry (3)
      { serviceIdx: 3, status: 'COMPLETED', amount: 520 },
      { serviceIdx: 3, status: 'COMPLETED', amount: 450 },
      { serviceIdx: 3, status: 'ACCEPTED', amount: 450 },

      // AC Repair / Others (5)
      { serviceIdx: 2, status: 'COMPLETED', amount: 1029 },
      { serviceIdx: 2, status: 'COMPLETED', amount: 599 },
      { serviceIdx: 2, status: 'COMPLETED', amount: 599 },
      { serviceIdx: 5, status: 'COMPLETED', amount: 899 },
      { serviceIdx: 5, status: 'ACCEPTED', amount: 899 }
    ];

    const sampleBookings = bookingConfigs.map((cfg, idx) => ({
      customer: insertedCustomers[idx % insertedCustomers.length]._id,
      worker: insertedWorkers[idx % insertedWorkers.length]._id,
      service: insertedServices[cfg.serviceIdx]._id,
      status: cfg.status,
      problemDescription: `Service request #${idx + 1} for ${insertedServices[cfg.serviceIdx].title}`,
      serviceAddress: {
        addressLine: 'Sector 62, Noida',
        location: { type: 'Point', coordinates: [77.3639, 28.6280] }
      },
      scheduledTime: new Date(Date.now() - (idx % 7) * 24 * 60 * 60 * 1000),
      invoice: {
        baseServiceFee: insertedServices[cfg.serviceIdx].basePrice,
        extraPartsTotal: cfg.amount - insertedServices[cfg.serviceIdx].basePrice > 0 ? cfg.amount - insertedServices[cfg.serviceIdx].basePrice : 0,
        platformFee: 20,
        totalAmount: cfg.amount,
        paymentStatus: cfg.status === 'COMPLETED' ? 'PAID' : 'PENDING',
        paymentMethod: 'UPI'
      }
    }));

    const insertedBookings = await Booking.insertMany(sampleBookings);
    console.log(`✅ Seeded ${insertedBookings.length} Bookings`);

    // 6. Insert Transactions for Completed Bookings with Razorpay Payment IDs
    console.log('💳 Seeding Transactions & Worker Wallets...');
    const completedBookings = insertedBookings.filter(b => b.status === 'COMPLETED');
    const sampleTransactions = completedBookings.map((b, idx) => {
      const razorpayPaymentId = `pay_rzp_${100000 + idx * 4231}`;
      const orderId = `order_rzp_${500000 + idx * 7123}`;
      return {
        customerId: b.customer,
        workerId: b.worker,
        bookingId: b._id,
        orderId,
        paymentId: razorpayPaymentId,
        signature: `sig_rzp_${Math.random().toString(36).substring(2, 12)}`,
        amount: b.invoice?.totalAmount || 500,
        currency: 'INR',
        status: 'success',
        paymentMethod: 'Razorpay'
      };
    });

    const insertedTransactions = await Transaction.insertMany(sampleTransactions);
    console.log(`✅ Seeded ${insertedTransactions.length} Transactions with Razorpay IDs`);

    // Credit Worker Profiles with Wallet Balances & Wallet Transactions
    for (const tx of insertedTransactions) {
      const worker = await User.findById(tx.workerId);
      if (worker) {
        if (!worker.workerProfile) worker.workerProfile = {};
        const payout = Math.round(tx.amount * 0.95);
        worker.workerProfile.walletBalance = (worker.workerProfile.walletBalance || 0) + payout;
        worker.workerProfile.totalEarnings = (worker.workerProfile.totalEarnings || 0) + payout;
        worker.workerProfile.totalJobs = (worker.workerProfile.totalJobs || 0) + 1;
        if (!worker.workerProfile.walletTransactions) worker.workerProfile.walletTransactions = [];
        worker.workerProfile.walletTransactions.push({
          transactionId: tx.paymentId,
          bookingId: tx.bookingId,
          amount: payout,
          type: 'CREDIT',
          description: `Payout credited for Booking (Razorpay ID: ${tx.paymentId})`,
          createdAt: tx.createdAt
        });
        await worker.save();
      }
    }

    // 7. Insert Reviews
    console.log('⭐ Seeding Reviews...');
    const sampleReviews = [
      {
        booking: insertedBookings[0]._id,
        customer: insertedCustomers[0]._id,
        worker: insertedWorkers[0]._id,
        rating: 5,
        feedback: 'Rajesh arrived within 20 minutes and fixed the kitchen pipe leakage perfectly. Very polite and professional!',
        badgesGiven: ['On Time', 'Clean Workspace', 'Expert Work']
      }
    ];

    const insertedReviews = await Review.insertMany(sampleReviews);
    console.log(`✅ Seeded ${insertedReviews.length} Reviews`);

    console.log('\n🎉 ============================================== 🎉');
    console.log('   DATABASE SEEDING COMPLETED SUCCESSFULLY!');
    console.log('🎉 ============================================== 🎉\n');

    process.exit(0);
  } catch (error) {
    console.error('❌ Database Seeding Failed:', error);
    process.exit(1);
  }
};

seedDatabase();
