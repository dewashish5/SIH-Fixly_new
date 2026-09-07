# Implementation Plan: Comprehensive Backend Integration Guide Rewrite

Rewrite `backend_changes.md` to provide a complete, copy-paste ready, file-by-file integration guide for the backend developer managing the production backend repository.

## Proposed Changes

### Documentation

#### [MODIFY] [backend_changes.md](file:///Users/dewashishhatekar/Developer/Projects/SIH-Fixly/backend_changes.md)

Structure the document into:
1. **Executive Summary & Scope**: Overview of commit `70ceced78dbfa61b7ad8ffaa4e63e2bad09e42c8`, file breakdown (11 backend files), architectural intent.
2. **Feature Deep Dives & Data Flows**:
   - **Feature 1: Customer Booking Update & Worker Re-dispatch**:
     - Flow: Client PATCH → Auth & ownership check → status guards → field mutation → state reset (`PENDING`, `worker=null`) → Socket.IO emission (`booking:updated`) → Worker notification (`NEW_BOOKING_AVAILABLE`).
   - **Feature 2: Promotional Coupon Banners System**:
     - Model schema (`Banner`), auto-seeding logic (`seedDefaultBannersIfEmpty`), public customer endpoint (`GET /api/home/banners`), integration in `homeController.js` (`getHomeData`), and secure Admin CRUD (`GET`, `POST`, `PUT`, `DELETE` on `/api/admin/banners`).
   - **Feature 3: Worker Category Matching & Alias Normalization**:
     - Alias mapping logic, regex safety, matching against `workerProfile.category`, `categories`, and `categoryRates.category`.
3. **Complete Code Implementation File-by-File**:
   - `backend/models/Banner.js` (Complete File)
   - `backend/utils/workerCategoryFilter.js` (Complete File)
   - `backend/controllers/bannerController.js` (Complete File)
   - `backend/routes/home-routes.js` (Complete File / Exact additions)
   - `backend/routes/booking-routes.js` (Complete File / Exact additions)
   - `backend/routes/admin-routes.js` (Exact additions + context)
   - `backend/controllers/bookingController.js` (Complete `updateBooking` controller implementation)
   - `backend/controllers/homeController.js` (Exact diff / updated `getHomeData`)
   - `backend/controllers/workerController.js` (Exact diff / updated `getNearbyWorkers`)
   - `backend/tests/bookingUpdateRoute.test.js` (Complete File)
   - `backend/tests/workerCategoryFilter.test.js` (Complete File)
4. **Step-by-Step Integration & Verification Guide**:
   - Order of operations to apply changes.
   - Socket.IO & notification dependencies check.
   - Automated tests execution via `node --test`.
   - Sample cURL requests for testing all new endpoints.

## Verification Plan

### Automated Verification
- Verify that `backend_changes.md` exists and contains full code snippets without missing functions.
- Run tests in backend to confirm code accuracy:
  ```bash
  node --test backend/tests/bookingUpdateRoute.test.js
  node --test backend/tests/workerCategoryFilter.test.js
  ```
