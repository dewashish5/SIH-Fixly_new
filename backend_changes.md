# FIXLY Backend Integration Guide (Commit `70ceced78dbfa61b7ad8ffaa4e63e2bad09e42c8`)

> **Audience:** Backend Engineers deploying or maintaining the production FIXLY Node.js / Express / MongoDB / Socket.IO backend.  
> **Purpose:** This document details every backend modification introduced in commit `70ceced78dbfa61b7ad8ffaa4e63e2bad09e42c8`. It includes full code implementations, architecture decisions, data flow diagrams, route declarations, lifecycle transitions, and testing steps.

---

## 1. Overview & Architectural Scope

In commit `70ceced78dbfa61b7ad8ffaa4e63e2bad09e42c8`, 11 backend files were added or modified across three main functional domains:

```
backend/
├── models/
│   └── Banner.js                        [NEW] Mongoose schema for promotional coupon banners
├── utils/
│   └── workerCategoryFilter.js          [NEW] Reusable category condition builder with aliases
├── controllers/
│   ├── bannerController.js              [NEW] Customer banner fetch + Admin banner CRUD + Auto-seed
│   ├── bookingController.js             [MODIFIED] Added customer booking update controller
│   ├── homeController.js                [MODIFIED] Injected active banners into home dashboard
│   └── workerController.js              [MODIFIED] Integrated workerCategoryFilter helper
├── routes/
│   ├── home-routes.js                   [MODIFIED] Added GET /api/home/banners
│   ├── booking-routes.js                [MODIFIED] Added PATCH /api/bookings/:bookingId
│   └── admin-routes.js                  [MODIFIED] Added CRUD endpoints under /api/admin/banners
└── tests/
    ├── bookingUpdateRoute.test.js       [NEW] Unit test verifying update booking route registration
    └── workerCategoryFilter.test.js     [NEW] Unit tests verifying category alias regex matching
```

---

## 2. Feature Architecture & Flow Deep-Dives

### Feature 1: Customer Booking Update & Dynamic Re-dispatch

#### Why It Was Done
Previously, once a booking was created, customers could not update problem descriptions or address coordinates from the mobile app without cancelling and recreating the booking. When a customer updates critical job details (e.g. "Pipe is burst, bring wrench", or moves pin location), existing worker assignments become invalid because the original worker may no longer be available for the new time or location.

#### State Transition & Flow
```
Customer App
    │
    ▼ (PATCH /api/bookings/:bookingId) [Auth: Bearer JWT]
bookingController.updateBooking()
    │
    ├── 1. Verification:
    │      - Booking exists? If not → 404
    │      - req.user.id === booking.customer? If not → 403 Forbidden
    │      - status in ['COMPLETED', 'CANCELLED']? If yes → 400 Bad Request
    │
    ├── 2. Sanitization & Mutation:
    │      - problemDescription → trimmed string
    │      - scheduledTime → ISO Date parsing & validation
    │      - serviceAddress → validates addressLine & GeoJSON Point [lng, lat]
    │
    ├── 3. Status Transition & State Reset:
    │      - booking.status = 'PENDING'
    │      - booking.worker = null (unassigns previous worker)
    │      - booking.declinedBy = null
    │      - booking.declineReason = null
    │      - booking.save()
    │
    ├── 4. Real-time Broadcasting (Socket.IO):
    │      - io.emit('booking:updated', { bookingId, booking: populatedBooking })
    │
    └── 5. Worker Notification Engine:
           - findEligibleWorkerIds(booking, category)
           - notifyUsers(workerIds, { eventType: 'NEW_BOOKING_AVAILABLE', ... })
```

---

### Feature 2: Promotional Coupon Banners System

#### Why It Was Done
Coupon banners were previously hardcoded in the Flutter mobile application. Storing banners in MongoDB enables:
1. Dynamic creation of marketing campaigns without releasing app store updates.
2. Filtering banners by category (e.g. `technician`, `cleaning`, `all`) and user audience (`new_user`, `vip`, `customer`).
3. Auto-seeding starter promotional coupons (`FIXLY50`, `COOL20`, `WEEKEND100`) on first startup.
4. Full administrative management (Create, Read, Update, Delete) via protected admin endpoints.

#### Data Flow & Integration
```
Mobile App Home Screen                     Admin Dashboard
       │                                         │
       ▼ (GET /api/home/banners)                 ▼ (GET/POST/PUT/DELETE /api/admin/banners)
       │                                         │ [Auth: adminProtect]
bannerController.getBanners()              bannerController.admin*()
       │                                         │
       ├── Auto-seed if empty:                   ├── Create: checks duplicate coupon code
       │   Banner.countDocuments() === 0         ├── Update: modifies banner fields
       │   → insert DEFAULT_BANNERS              └── Delete: deletes banner by ID
       │                                         │
       └── Filter query:                         ▼
           isActive: true                        MongoDB: banners collection
           category & targetUserRole
```

---

### Feature 3: Worker Category Matching & Alias Normalization

#### Why It Was Done
Workers define categories in varying formats:
- Primary category string: `workerProfile.category` (e.g., `'Plumbing'`)
- Categories array: `workerProfile.categories` (e.g., `['Plumbing', 'Electrician']`)
- Specific rate cards: `workerProfile.categoryRates.category` (e.g., `[{ category: 'Plumbing', rate: 250 }]`)

Furthermore, customer search terms often use aliases or different linguistic forms (e.g. `plumber` vs `plumbing`, `technician` vs `tech`, `domestic_helper` vs `helper`). `buildCategoryCondition` resolves aliases and uses case-insensitive regular expressions across all three fields simultaneously.

---

## 3. Full Implementation Code (File by File)

### 1. `backend/models/Banner.js`
*New file defining the Mongoose schema for promotional coupon banners.*

```javascript
import mongoose from 'mongoose';

const bannerSchema = new mongoose.Schema({
    title: { type: String, required: true, trim: true },
    code: { type: String, required: true, uppercase: true, trim: true },
    discount: { type: String, required: true, trim: true },
    discountPercent: { type: Number, default: 0 },
    discountAmount: { type: Number, default: 0 },
    description: { type: String, trim: true, default: '' },
    imageUrl: { type: String, default: '' },
    gradient: [{ type: String }],
    category: { type: String, default: 'all', index: true },
    targetUserRole: { type: String, enum: ['all', 'customer', 'new_user', 'vip'], default: 'all' },
    minOrderValue: { type: Number, default: 0 },
    maxDiscount: { type: Number, default: 500 },
    validUntil: { type: Date },
    isActive: { type: Boolean, default: true, index: true },
    priority: { type: Number, default: 0 }
}, { timestamps: true });

const Banner = mongoose.model('Banner', bannerSchema);

export default Banner;
```

---

### 2. `backend/utils/workerCategoryFilter.js`
*New utility helper module to construct category search queries across worker profiles.*

```javascript
export const buildCategoryCondition = (category) => {
    const trimmed = String(category ?? '').trim();
    if (!trimmed) return null;

    const escaped = trimmed.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    const categoryAliases = {
        plumber: 'plumb',
        electrician: 'electric',
        carpenter: 'carpent',
        painter: 'paint',
        gardener: 'garden',
        domestic_helper: 'domestic|helper',
        caregiving: 'caregiv|care',
        driver: 'driver',
        technician: 'technician|tech',
        cleaning: 'clean',
    };
    const matcher = categoryAliases[trimmed.toLowerCase()] ?? escaped;
    const categoryRegex = new RegExp(matcher, 'i');

    return {
        $or: [
            { 'workerProfile.category': { $regex: categoryRegex } },
            { 'workerProfile.categories': { $regex: categoryRegex } },
            { 'workerProfile.categoryRates.category': { $regex: categoryRegex } },
        ],
    };
};
```

---

### 3. `backend/controllers/bannerController.js`
*New controller managing coupon banner seeding, customer querying, and full admin CRUD.*

```javascript
import Banner from '../models/Banner.js';

// Default starter banners to seed if none exist
const DEFAULT_BANNERS = [
    {
        title: 'Flat 50% Off First Booking',
        code: 'FIXLY50',
        discount: '50% OFF',
        discountPercent: 50,
        description: 'Get 50% discount up to ₹150 on your first home repair service',
        gradient: ['#1E3A8A', '#3B82F6'],
        category: 'all',
        targetUserRole: 'all',
        minOrderValue: 249,
        maxDiscount: 150,
        validUntil: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
        isActive: true,
        priority: 10
    },
    {
        title: 'AC & Appliance Mega Saver',
        code: 'COOL20',
        discount: '20% OFF',
        discountPercent: 20,
        description: 'Save up to ₹250 on all AC and appliance servicing & repairs',
        gradient: ['#047857', '#10B981'],
        category: 'technician',
        targetUserRole: 'all',
        minOrderValue: 399,
        maxDiscount: 250,
        validUntil: new Date(Date.now() + 15 * 24 * 60 * 60 * 1000),
        isActive: true,
        priority: 8
    },
    {
        title: 'Super Weekend Special',
        code: 'WEEKEND100',
        discount: '₹100 FLAT',
        discountAmount: 100,
        description: 'Flat ₹100 instant cash discount on electrician & plumber orders',
        gradient: ['#7C2D12', '#EA580C'],
        category: 'all',
        targetUserRole: 'all',
        minOrderValue: 299,
        maxDiscount: 100,
        validUntil: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
        isActive: true,
        priority: 6
    }
];

// Helper to seed if collection is empty
export const seedDefaultBannersIfEmpty = async () => {
    try {
        const count = await Banner.countDocuments();
        if (count === 0) {
            await Banner.insertMany(DEFAULT_BANNERS);
            console.log('✅ Seeded default promotional coupon banners');
        }
    } catch (err) {
        console.warn('⚠️ Could not seed default banners:', err.message);
    }
};

// Customer API: Get all active coupon banners
export const getBanners = async (req, res) => {
    try {
        await seedDefaultBannersIfEmpty();

        const { category, targetUserRole } = req.query;
        const query = { isActive: true };

        if (category && category !== 'all') {
            query.$or = [{ category: 'all' }, { category }];
        }

        if (targetUserRole && targetUserRole !== 'all') {
            query.targetUserRole = { $in: ['all', targetUserRole] };
        }

        const banners = await Banner.find(query)
            .sort({ priority: -1, createdAt: -1 })
            .lean();

        return res.status(200).json({
            success: true,
            banners: banners.length > 0 ? banners : DEFAULT_BANNERS
        });
    } catch (error) {
        return res.status(500).json({
            success: false,
            message: error.message || 'Failed to fetch coupon banners',
            banners: DEFAULT_BANNERS
        });
    }
};

// Admin API: List all banners (active and inactive)
export const adminGetBanners = async (req, res) => {
    try {
        await seedDefaultBannersIfEmpty();
        const banners = await Banner.find().sort({ priority: -1, createdAt: -1 }).lean();
        return res.status(200).json({ success: true, count: banners.length, banners });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

// Admin API: Create a new banner / coupon
export const adminCreateBanner = async (req, res) => {
    try {
        const {
            title,
            code,
            discount,
            discountPercent,
            discountAmount,
            description,
            imageUrl,
            gradient,
            category,
            targetUserRole,
            minOrderValue,
            maxDiscount,
            validUntil,
            isActive,
            priority
        } = req.body;

        if (!title || !code || !discount) {
            return res.status(400).json({
                success: false,
                message: 'Title, coupon code, and discount are required fields'
            });
        }

        const existing = await Banner.findOne({ code: code.toUpperCase().trim() });
        if (existing) {
            return res.status(400).json({
                success: false,
                message: `Coupon code '${code.toUpperCase()}' already exists`
            });
        }

        const banner = await Banner.create({
            title,
            code: code.toUpperCase().trim(),
            discount,
            discountPercent: Number(discountPercent) || 0,
            discountAmount: Number(discountAmount) || 0,
            description: description || '',
            imageUrl: imageUrl || '',
            gradient: Array.isArray(gradient) && gradient.length > 0 ? gradient : ['#1E3A8A', '#3B82F6'],
            category: category || 'all',
            targetUserRole: targetUserRole || 'all',
            minOrderValue: Number(minOrderValue) || 0,
            maxDiscount: Number(maxDiscount) || 500,
            validUntil: validUntil ? new Date(validUntil) : new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
            isActive: isActive !== undefined ? Boolean(isActive) : true,
            priority: Number(priority) || 0
        });

        return res.status(201).json({
            success: true,
            message: 'Coupon banner created successfully',
            banner
        });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

// Admin API: Update an existing banner
export const adminUpdateBanner = async (req, res) => {
    try {
        const { id } = req.params;
        const banner = await Banner.findById(id);

        if (!banner) {
            return res.status(404).json({ success: false, message: 'Banner not found' });
        }

        const updates = { ...req.body };
        if (updates.code) updates.code = updates.code.toUpperCase().trim();

        const updated = await Banner.findByIdAndUpdate(id, updates, { new: true });

        return res.status(200).json({
            success: true,
            message: 'Coupon banner updated successfully',
            banner: updated
        });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

// Admin API: Delete a banner
export const adminDeleteBanner = async (req, res) => {
    try {
        const { id } = req.params;
        const banner = await Banner.findByIdAndDelete(id);

        if (!banner) {
            return res.status(404).json({ success: false, message: 'Banner not found' });
        }

        return res.status(200).json({
            success: true,
            message: 'Coupon banner deleted successfully'
        });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};
```

---

### 4. `backend/routes/home-routes.js`
*Added `GET /banners` route pointing to `bannerController.getBanners`.*

```javascript
import express from 'express';
import {
    getHomeData,
    getCategories,
    getServiceDetails,
    getExtraPartsCatalog,
    createCategory
} from '../controllers/homeController.js';
import { getBanners } from '../controllers/bannerController.js';
import { protect } from '../middleware/authMiddleware.js';
import upload from '../middleware/uploadMiddleware.js';

const router = express.Router();

router.get('/home', protect, getHomeData);
router.get('/banners', getBanners);
router.get('/categories', getCategories);
router.post('/categories', upload.single('image'), createCategory);
router.get('/services/:serviceId', getServiceDetails);
router.get('/extra-parts', getExtraPartsCatalog);

export default router;
```

---

### 5. `backend/routes/booking-routes.js`
*Added `PATCH /:bookingId` endpoint pointing to `updateBooking` controller.*

```javascript
import express from 'express';
import {
    calculateEstimate,
    createBooking,
    getBookingDetails,
    updateBooking,
    cancelBooking,
    getLiveTracking,
    getBookingInvoice,
    getBookingReview,
    acceptBooking,
    arriveAtLocation,
    startJob,
    completeJob,
    rescheduleBooking,
    updateBookingStatus,
    triggerSosAlert,
    declineBooking
} from '../controllers/bookingController.js';
import { protect } from '../middleware/authMiddleware.js';
import upload from '../middleware/uploadMiddleware.js';

const router = express.Router();

// Booking Creation & Setup
router.post('/estimate', protect, calculateEstimate);
router.post('/', protect, upload.array('photos', 5), createBooking);
router.get('/:bookingId/review', protect, getBookingReview);
router.get('/:bookingId', protect, getBookingDetails);
router.patch('/:bookingId', protect, updateBooking);
router.patch('/:bookingId/cancel', protect, cancelBooking);
router.post('/:bookingId/decline', protect, declineBooking);

// Worker Lifecycle Actions
router.patch('/:bookingId/accept', protect, acceptBooking);
router.patch('/:bookingId/arrive', protect, arriveAtLocation);
router.patch('/:bookingId/start', protect, startJob);
router.patch('/:bookingId/complete', protect, completeJob);
router.patch('/:bookingId/reschedule', protect, rescheduleBooking);
router.patch('/:bookingId/status', protect, updateBookingStatus);

// Tracking & Safety
router.get('/:bookingId/tracking', protect, getLiveTracking);
router.post('/:bookingId/sos', protect, triggerSosAlert);

// Billing & Invoice
router.get('/:bookingId/invoice', protect, getBookingInvoice);

export default router;
```

---

### 6. `backend/routes/admin-routes.js`
*Added admin routes for coupon banner management.*

```javascript
// ... existing imports ...
import {
    adminGetBanners,
    adminCreateBanner,
    adminUpdateBanner,
    adminDeleteBanner
} from '../controllers/bannerController.js';

// ... existing router configuration and routes ...

// Note: Ensure these are placed after router.use(adminProtect) so they are authenticated!

// Promotional Coupon Banners Management
router.get('/banners', adminGetBanners);
router.post('/banners', adminCreateBanner);
router.put('/banners/:id', adminUpdateBanner);
router.delete('/banners/:id', adminDeleteBanner);

export default router;
```

---

### 7. `backend/controllers/bookingController.js`
*Added `updateBooking` controller method. Insert right after `getBookingDetails`.*

```javascript
// Customer edits the problem details of an existing booking.
export const updateBooking = async (req, res) => {
    try {
        const { bookingId } = req.params;
        const { problemDescription, scheduledTime, serviceAddress } = req.body || {};
        const booking = await Booking.findById(bookingId);

        if (!booking) {
            return res.status(404).json({ success: false, message: 'Booking not found' });
        }
        if (String(booking.customer) !== String(req.user.id)) {
            return res.status(403).json({ success: false, message: 'You can only edit your own booking' });
        }
        if (['COMPLETED', 'CANCELLED'].includes(booking.status)) {
            return res.status(400).json({ success: false, message: 'Completed or cancelled bookings cannot be edited' });
        }

        if (problemDescription !== undefined) {
            booking.problemDescription = String(problemDescription).trim() || null;
        }
        if (scheduledTime !== undefined) {
            const parsedTime = new Date(scheduledTime);
            if (Number.isNaN(parsedTime.getTime())) {
                return res.status(400).json({ success: false, message: 'Invalid scheduledTime' });
            }
            booking.scheduledTime = parsedTime;
        }
        if (serviceAddress !== undefined) {
            if (!serviceAddress || typeof serviceAddress !== 'object') {
                return res.status(400).json({ success: false, message: 'Invalid serviceAddress' });
            }
            if (serviceAddress.addressLine !== undefined) {
                const addressLine = String(serviceAddress.addressLine).trim();
                if (!addressLine) {
                    return res.status(400).json({ success: false, message: 'addressLine cannot be empty' });
                }
                booking.serviceAddress.addressLine = addressLine;
            }
            if (Array.isArray(serviceAddress.coordinates)) {
                if (serviceAddress.coordinates.length !== 2 || serviceAddress.coordinates.some((value) => Number.isNaN(Number(value)))) {
                    return res.status(400).json({ success: false, message: 'Invalid service coordinates' });
                }
                booking.serviceAddress.location = {
                    type: 'Point',
                    coordinates: serviceAddress.coordinates.map(Number),
                };
            }
        }

        // Editing reopens the request so available workers can receive it again.
        booking.status = 'PENDING';
        booking.worker = null;
        booking.declinedBy = null;
        booking.declineReason = null;
        await booking.save();

        const populatedBooking = await Booking.findById(booking._id)
            .populate('service', 'name title category icon basePrice')
            .populate('worker', 'name phone avatar workerProfile rating')
            .populate('customer', 'name phone')
            .lean();
        const service = populatedBooking?.service;
        const category = service?.category;

        const io = req.app.get('io');
        if (io) {
            io.emit('booking:updated', { bookingId: booking._id, booking: populatedBooking });
        }
        safeNotify(async () => {
            if (!category) return;
            const workerIds = await findEligibleWorkerIds(booking, category);
            await notifyUsers(workerIds, {
                eventType: 'NEW_BOOKING_AVAILABLE',
                entityId: booking._id,
                bookingId: booking._id,
                dedupeKeyFor: (id) => `NEW_BOOKING_AVAILABLE:${booking._id}:${id}`,
            });
        });

        return res.status(200).json({
            success: true,
            message: 'Booking updated successfully',
            booking: populatedBooking,
        });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};
```

---

### 8. `backend/controllers/homeController.js`
*Updated `getHomeData` to fetch and return banners.*

```javascript
// Add imports:
import Banner from '../models/Banner.js';
import { seedDefaultBannersIfEmpty } from './bannerController.js';

// Update getHomeData function:
export const getHomeData = async (req, res) => {
    try {
        const cachedData = await redis.get('home_data');
        if (cachedData) {
            return res.status(200).json(JSON.parse(cachedData));
        }

        const limit = parseInt(process.env.HOME_SERVICES_LIMIT, 10) || 6;
        const ttl = parseInt(process.env.CACHE_TTL_HOME, 10) || 3600;

        await seedDefaultBannersIfEmpty();
        const categories = await Service.distinct('category');
        const topServices = await Service.find({ isActive: true }).limit(limit).lean();
        const banners = await Banner.find({ isActive: true }).sort({ priority: -1, createdAt: -1 }).lean();

        const responsePayload = {
            categories,
            topServices,
            banners,
            featuredOffers: banners.length > 0 ? banners : [
                { id: 'off_1', title: 'Spring Cleaning Special', discount: '20% OFF', code: 'SPRING20' },
                { id: 'off_2', title: 'First-Time User Discount', discount: '15% OFF', code: 'NEW15' }
            ]
        };

        await redis.setex('home_data', ttl, JSON.stringify(responsePayload));
        res.status(200).json(responsePayload);
    } catch (error) {
        res.status(500).json({ message: 'Server error fetching home data', error: error.message });
    }
};
```

---

### 9. `backend/controllers/workerController.js`
*Updated `getNearbyWorkers` to delegate category filtering to `buildCategoryCondition`.*

```javascript
// Add import at top:
import { buildCategoryCondition } from '../utils/workerCategoryFilter.js';

// In getNearbyWorkers():
// Replace old category filtering logic:
// ----------------------------------------------------
// OLD:
// if (category && category.trim()) {
//     const trimmedCat = category.trim();
//     const catRegex = new RegExp(`^${trimmedCat}$`, 'i');
//     andConditions.push({
//         $or: [
//             { 'workerProfile.category': { $regex: catRegex } },
//             { 'workerProfile.categories': { $elemMatch: { $regex: catRegex } } },
//             { 'workerProfile.categoryRates.category': { $elemMatch: { $regex: catRegex } } }
//         ]
//     });
// }
// ----------------------------------------------------
// NEW:
if (category && category.trim()) {
    andConditions.push(buildCategoryCondition(category));
}
```

---

### 10. `backend/tests/bookingUpdateRoute.test.js`
*Unit test validating route registration.*

```javascript
import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';

test('booking routes expose the customer booking update endpoint', () => {
    const routes = fs.readFileSync(new URL('../routes/booking-routes.js', import.meta.url), 'utf8');

    assert.match(routes, /router\.patch\('\/:bookingId',\s*protect,\s*updateBooking\)/);
});
```

---

### 11. `backend/tests/workerCategoryFilter.test.js`
*Unit test validating multi-field category resolution and alias handling.*

```javascript
import test from 'node:test';
import assert from 'node:assert/strict';

import { buildCategoryCondition } from '../utils/workerCategoryFilter.js';

const matches = (condition, profile) =>
    condition.$or.some((entry) => {
        const [path, value] = Object.entries(entry)[0];
        const field = path.split('.').reduce((current, key) => {
            if (Array.isArray(current)) return current.flatMap((item) => item?.[key] ?? []);
            return current?.[key];
        }, profile);
        const regex = value.$regex;
        return Array.isArray(field) ? field.some((item) => regex.test(item)) : regex.test(field ?? '');
    });

test('category filter matches primary, offered, and rated categories using category ids', () => {
    const condition = buildCategoryCondition('plumber');

    assert.equal(matches(condition, { workerProfile: { category: 'Plumbing' } }), true);
    assert.equal(matches(condition, { workerProfile: { categories: ['Plumbing', 'Electrician'] } }), true);
    assert.equal(matches(condition, { workerProfile: { categoryRates: [{ category: 'Plumbing' }] } }), true);
});

test('category filter does not match an unrelated category', () => {
    const condition = buildCategoryCondition('plumber');

    assert.equal(matches(condition, { workerProfile: { category: 'Cleaning' } }), false);
});
```

---

## 4. Step-by-Step Integration Guide for Existing Backend

Follow these steps in your backend codebase:

### Step 1: Create Model and Utilities
1. Create `backend/models/Banner.js` using the code above.
2. Create `backend/utils/workerCategoryFilter.js` using the code above.

### Step 2: Add Banner Controller and Routes
1. Create `backend/controllers/bannerController.js`.
2. Edit `backend/routes/home-routes.js`:
   - Import `getBanners` from `../controllers/bannerController.js`.
   - Add `router.get('/banners', getBanners);`.
3. Edit `backend/routes/admin-routes.js`:
   - Import `adminGetBanners`, `adminCreateBanner`, `adminUpdateBanner`, `adminDeleteBanner`.
   - Register the 4 routes after `router.use(adminProtect)`.

### Step 3: Integrate Booking Update Endpoint
1. Edit `backend/controllers/bookingController.js`:
   - Export `updateBooking` controller.
2. Edit `backend/routes/booking-routes.js`:
   - Import `updateBooking`.
   - Add `router.patch('/:bookingId', protect, updateBooking);`.

### Step 4: Update Home & Worker Controllers
1. In `backend/controllers/homeController.js`:
   - Import `Banner` and `seedDefaultBannersIfEmpty`.
   - Update `getHomeData` to query and return `banners`.
2. In `backend/controllers/workerController.js`:
   - Import `buildCategoryCondition`.
   - Replace category matching block with `andConditions.push(buildCategoryCondition(category));`.

---

## 5. Verification & Testing

### 5.1 Automated Unit Tests
Run Node's built-in test runner from the root directory:

```bash
node --test backend/tests/bookingUpdateRoute.test.js
node --test backend/tests/workerCategoryFilter.test.js
```

### 5.2 Manual API Testing with cURL

#### 1. Fetch Coupon Banners (Public)
```bash
curl -X GET "http://localhost:5000/api/home/banners?category=technician" \
  -H "Content-Type: application/json"
```

#### 2. Create Banner (Admin Protected)
```bash
curl -X POST "http://localhost:5000/api/admin/banners" \
  -H "Authorization: Bearer <ADMIN_JWT_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Monsoon Plumbing Offer",
    "code": "RAIN30",
    "discount": "30% OFF",
    "discountPercent": 30,
    "category": "plumber",
    "minOrderValue": 300,
    "maxDiscount": 150
  }'
```

#### 3. Update Customer Booking (Customer Protected)
```bash
curl -X PATCH "http://localhost:5000/api/bookings/<BOOKING_ID>" \
  -H "Authorization: Bearer <CUSTOMER_JWT_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "problemDescription": "Kitchen sink pipe broken, leaking heavily under the counter",
    "scheduledTime": "2026-09-10T14:30:00.000Z",
    "serviceAddress": {
      "addressLine": "Flat 402, Sunshine Heights, Mumbai",
      "coordinates": [72.8777, 19.0760]
    }
  }'
```

Expected response (`200 OK`):
```json
{
  "success": true,
  "message": "Booking updated successfully",
  "booking": {
    "_id": "<BOOKING_ID>",
    "status": "PENDING",
    "worker": null,
    "problemDescription": "Kitchen sink pipe broken, leaking heavily under the counter",
    "serviceAddress": {
      "addressLine": "Flat 402, Sunshine Heights, Mumbai",
      "location": {
        "type": "Point",
        "coordinates": [72.8777, 19.076]
      }
    }
  }
}
```

---

## 6. Socket.IO & Realtime Events Reference

| Event Name | Emitter | Payload | Purpose |
| :--- | :--- | :--- | :--- |
| `booking:updated` | Server (`bookingController.updateBooking`) | `{ bookingId, booking }` | Broadcasts booking changes to connected clients in real-time |
| `NEW_BOOKING_AVAILABLE` | Server (`notifyUsers`) | `{ eventType, entityId, bookingId }` | Re-notifies eligible workers in the category that the edited booking is open for acceptance |