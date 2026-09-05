import swaggerAutogen from 'swagger-autogen';
import fs from 'fs';

const doc = {
    info: {
        title: 'GigConnect Backend API Platform',
        description: 'Clean, systematic, and fully categorized RESTful API documentation for GigConnect services, workers, bookings, admin operations, and background workflows.',
        version: '1.0.0'
    },
    host: 'localhost:8000',
    basePath: '/',
    schemes: ['http', 'https'],
    securityDefinitions: {
        bearerAuth: {
            type: 'apiKey',
            in: 'header',
            name: 'Authorization',
            description: 'Enter JWT Bearer token: Bearer <token>'
        }
    },
    tags: [
        { name: 'Auth', description: 'Authentication, registration, OTP verification & session tokens' },
        { name: 'Workers', description: 'Worker discovery, profile setup, availability, ratings & reviews' },
        { name: 'Services', description: 'Service catalog, categories (24h Redis cache), and service pricing details' },
        { name: 'Bookings', description: 'Booking lifecycle, GPS tracking, job actions, extra parts & invoice' },
        { name: 'Admin', description: 'Admin control center for customers, workers, bookings, services & settings' },
        { name: 'Payments', description: 'Razorpay order creation, payment signature verification & transactions' },
        { name: 'Reviews', description: 'Customer reviews, ratings & quality badge feedback' },
        { name: 'Home', description: 'Home screen banners, featured offers & top categories' },
        { name: 'Users', description: 'Customer profile details, saved addresses & user settings' },
        { name: 'KYC & Verification', description: 'Worker identity verification & skill certifications' },
        { name: 'Worker Wallet', description: 'Worker wallet balances, payouts, earnings & withdrawal requests' },
        { name: 'Support', description: 'Customer support tickets & real-time support message threads' },
        { name: 'Notifications', description: 'Push notification tokens, alerts & notification read status' },
        { name: 'Cooperative', description: 'Worker cooperative governance, members & welfare policies' },
        { name: 'Welfare', description: 'Social welfare schemes, insurance coverage & claim filing' },
        { name: 'AI Assistant', description: 'AI worker matching, problem diagnostics & regional demand forecasting' },
        { name: 'Upload', description: 'Direct media file uploads (Single & Multiple)' },
        { name: 'General', description: 'System health check and platform operational status' }
    ],
    definitions: {
        CustomerRegisterInput: {
            name: "John Customer",
            email: "john.customer@example.com",
            password: "SecurePassword123",
            role: "customer",
            phone: "+919876543210",
            location: {
                type: "Point",
                coordinates: [77.2090, 28.6139]
            }
        },
        WorkerRegisterInput: {
            name: "Ramesh Worker",
            email: "ramesh.worker@example.com",
            password: "SecurePassword123",
            role: "worker",
            phone: "+919876543210",
            location: {
                type: "Point",
                coordinates: [77.2090, 28.6139]
            }
        },
        RegisterInput: {
            name: "John Doe",
            email: "john.doe@example.com",
            password: "SecurePassword123",
            role: "customer",
            phone: "+919876543210",
            location: {
                type: "Point",
                coordinates: [77.2090, 28.6139]
            }
        },
        Worker3StepOnboardingInput: {
            step1_identity: {
                fullName: "Dewashish Hatekar",
                dateOfBirth: "1998-05-12",
                gender: "male",
                phone: "9876543210",
                email: "dewashishhatekar05@gmail.com",
                aadhaarNumber: "123456789012",
                aadhaarFrontPhoto: "https://example.com/aadhaar_front.jpg",
                aadhaarBackPhoto: "https://example.com/aadhaar_back.jpg",
                panNumber: "ABCDE1234F",
                panFrontPhoto: "https://example.com/pan_front.jpg",
                panBackPhoto: "https://example.com/pan_back.jpg",
                selfieVerified: true,
                selfieImageUrl: "https://example.com/selfie.jpg",
                govermentIdType: "Aadhaar Card",
                govermentIdNumber: "123456789012"
            },
            step2_workProfile: {
                certificateUploaded: true,
                certifications: ["certificate.pdf"],
                categories: ["plumber", "electrician"],
                category: "plumber",
                skills: ["plumber", "electrician", "Pipe Fitting"],
                experienceYears: 4,
                bio: "Experienced plumber and electrician with 4+ years of field experience.",
                rate: 350,
                categoryRates: [
                    { category: "plumber", rate: 350 },
                    { category: "electrician", rate: 500 },
                    { category: "Pipe Fitting", rate: 300 }
                ],
                location: {
                    type: "Point",
                    coordinates: [77.2090, 28.6139],
                    address: "Connaught Place, New Delhi"
                }
            },
            step3_payoutWelfare: {
                hasEshram: true,
                eshramUan: "ESHRAM1234567890",
                payoutMethod: "bank",
                bank: {
                    accountHolderName: "Dewashish Hatekar",
                    accountNumber: "123456789012",
                    confirmAccountNumber: "123456789012",
                    ifscCode: "HDFC0001234",
                    bankVerified: true
                },
                upi: {
                    upiId: "dewashish@upi",
                    upiVerified: false
                }
            }
        },
        WorkerProfileSetupInput: {
            name: "Dewashish Hatekar",
            phone: "9876543210",
            dateOfBirth: "1998-05-12",
            gender: "male",
            avatar: "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQEASABIAAD...",
            category: "electrician",
            categories: ["electrician", "plumber"],
            rate: 500,
            categoryRates: [
                { category: "electrician", rate: 500 }
            ],
            experienceYears: 4,
            bio: "Experienced electrician and plumber with 4+ years of field experience.",
            skills: ["electrician", "plumbing"],
            certifications: [
                "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAA...",
                "data:application/pdf;base64,JVBERi0xLjQN..."
            ],
            aadhaarNumber: "123456789012",
            aadhaarFrontPhoto: "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQEASABIAAD...",
            aadhaarBackPhoto: "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQEASABIAAD...",
            panNumber: "ABCDE1234F",
            panFrontPhoto: "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQEASABIAAD...",
            panBackPhoto: "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQEASABIAAD...",
            workAddress: "Connaught Place, New Delhi",
            payoutMethod: "bank",
            bank: {
                accountHolderName: "Dewashish Hatekar",
                accountNumber: "123456789012",
                ifscCode: "HDFC0001234"
            },
            upi: {
                upiId: "dewashish@upi"
            }
        },
        LoginInput: {
            email: "john.doe@example.com",
            password: "SecurePassword123",
            deviceId: "device-uuid-12345",
            location: {
                type: "Point",
                coordinates: [77.2090, 28.6139]
            }
        },
        GoogleLoginInput: {
            email: "john.doe@example.com",
            name: "John Doe",
            avatar: "https://lh3.googleusercontent.com/a/default-user",
            role: "customer",
            phone: "+1234567890",
            deviceId: "device-uuid-12345",
            location: {
                type: "Point",
                coordinates: [77.2090, 28.6139]
            }
        },
        VerifyOtpInput: {
            email: "john.doe@example.com",
            otp: "123456",
            deviceId: "device-uuid-12345"
        },
        RefreshTokenInput: {
            userId: "64f1bc000000000000000001",
            deviceId: "device-uuid-12345",
            refreshToken: "eyJhbGciOi..."
        },
        LogoutInput: {
            userId: "64f1bc000000000000000001",
            deviceId: "device-uuid-12345"
        },
        CreateBookingInput: {
            serviceId: "64f1bc000000000000000002",
            workerId: "64f1bd000000000000000003",
            problemDescription: "Kitchen sink is leaking from the main drain pipe.",
            problemPhotos: ["https://example.com/photo1.jpg"],
            addressLine: "123 Main Street, Apt 4B, New Delhi",
            coordinates: [77.2090, 28.6139]
        },
        VerifyArrivalOtpInput: {
            otp: "8492"
        },
        AddExtraPartsInput: {
            extraItems: [
                { title: "U-bend Pipe", price: 25 },
                { title: "Rubber Gasket", price: 5 }
            ]
        },
        SubmitReviewInput: {
            bookingId: "64f1be000000000000000004",
            workerId: "64f1bd000000000000000003",
            rating: 5,
            comment: "Excellent work! He resolved the leak quickly.",
            traits: ["Professional", "On Time", "Clean Workspace"]
        },
        CreatePaymentOrderInput: {
            bookingId: "64f1be000000000000000004",
            amount: 130
        },
        VerifyPaymentInput: {
            razorpay_order_id: "order_Kz...",
            razorpay_payment_id: "pay_Kz...",
            razorpay_signature: "abc123xyz...",
            bookingId: "64f1be000000000000000004"
        }
    }
};

const outputFile = './swagger-output.json';
const routesFiles = ['./server.js'];

// Explicit Route Summaries Mapping for systematic documentation
const ROUTE_SUMMARIES = {
    // Auth
    'POST /api/auth/register': 'Register New Customer or Worker',
    'POST /api/auth/verify-otp': 'Verify Registration / Login OTP',
    'POST /api/auth/login': 'Login with Email & Password',
    'POST /api/auth/google': 'Login / Register with Google OAuth',
    'POST /api/auth/forgot-password': 'Send Password Reset OTP',
    'POST /api/auth/reset-password': 'Reset Password with OTP',
    'POST /api/auth/refresh-token': 'Refresh JWT Access Token',
    'POST /api/auth/logout': 'Logout User & Clear Session',
    'GET /api/auth/me': 'Get Current Authenticated User Profile',
    'PUT /api/auth/me': 'Update Current User Profile',
    'PATCH /api/auth/me': 'Partially Update User Profile',
    'PUT /api/auth/profile': 'Setup / Update Worker Profile with Documents',

    // Workers
    'GET /api/workers/': 'Find Nearby Available Workers (Geo-query & Filters)',
    'PUT /api/workers/setup-profile': 'Setup 3-Step Worker Profile & Documents',
    'GET /api/workers/me/availability': 'Get Worker Live Online / Offline Status',
    'PATCH /api/workers/me/availability': 'Toggle Worker Online / Offline Availability',
    'PUT /api/workers/me/availability/schedule': 'Update Worker Weekly Working Schedule',
    'GET /api/workers/me/wallet': 'Get Worker Wallet Balance & Info',
    'POST /api/workers/me/withdraw': 'Request Wallet Payout / Withdrawal',
    'GET /api/workers/me/earnings': 'Get Detailed Worker Earnings History',
    'GET /api/workers/me/earnings/summary': 'Get Worker Daily / Weekly / Monthly Earnings Summary',
    'GET /api/workers/me/payouts': 'Get Worker Payout Records',
    'GET /api/workers/me/transactions': 'Get Worker Transaction History',
    'GET /api/workers/me/welfare': 'Get Worker Welfare Benefits & Enrollment',
    'GET /api/workers/me/welfare/transactions': 'Get Worker Welfare Contributions',
    'GET /api/workers/me/insurance': 'Get Worker Insurance Policies',
    'GET /api/workers/me/insurance/claims': 'List Worker Insurance Claims',
    'POST /api/workers/me/insurance/claims': 'Submit New Insurance Claim',
    'GET /api/workers/me/certificates': 'Get Worker Uploaded Certificates',
    'POST /api/workers/me/certificates': 'Upload New Skill Certificate',
    'GET /api/workers/me/certificates/{id}': 'Get Certificate Details by ID',
    'DELETE /api/workers/me/certificates/{id}': 'Delete Skill Certificate',
    'GET /api/workers/me/membership': 'Get Worker Cooperative Membership Details',
    'GET /api/workers/{workerId}': 'Get Worker Public Profile & Badges by ID',
    'GET /api/workers/{workerId}/reliability': 'Get Worker Reliability & Performance Score',
    'GET /api/workers/{workerId}/reviews': 'Get Customer Reviews for Worker',

    // Services
    'GET /api/services/categories': 'Get All Categories & Grouped Services (24h Redis Cached)',
    'GET /api/services/search': 'Search Services by Keyword or Category',
    'GET /api/services/extra-parts': 'Get Extra Parts Catalog for Bookings',
    'GET /api/services/{serviceId}': 'Get Service Details & Pricing by ID',
    'POST /api/services/': 'Create New Service (Uses Cloudinary)',

    // Bookings
    'POST /api/bookings/': 'Create New Service Booking',
    'POST /api/bookings/estimate': 'Calculate Service Price Estimate',
    'GET /api/bookings/history': 'Get Customer Booking History',
    'GET /api/bookings/worker/active': 'Get Worker Active Ongoing Job',
    'GET /api/bookings/worker/incoming': 'Get Worker Incoming Booking Requests',
    'GET /api/bookings/worker/completed': 'Get Worker Completed Jobs History',
    'GET /api/bookings/{bookingId}': 'Get Booking Details by ID',
    'POST /api/bookings/{bookingId}/accept': 'Worker: Accept Incoming Booking',
    'POST /api/bookings/{bookingId}/decline': 'Worker: Decline Incoming Booking',
    'POST /api/bookings/{bookingId}/start-job': 'Worker: Start Service Job',
    'POST /api/bookings/{bookingId}/verify-otp': 'Verify Customer Arrival OTP',
    'PATCH /api/bookings/{bookingId}/add-parts': 'Add Extra Parts / Materials to Booking Invoice',
    'POST /api/bookings/{bookingId}/complete': 'Worker: Complete Service Job & Generate Final Invoice',
    'PATCH /api/bookings/{bookingId}/cancel': 'Cancel Booking with Reason',
    'GET /api/bookings/{bookingId}/track': 'Get Live GPS Tracking for Active Booking (Redis Cached)',
    'GET /api/bookings/{bookingId}/invoice': 'Get Booking Final Invoice Breakdown',
    'POST /api/bookings/{bookingId}/sos': 'Trigger Emergency SOS for Booking',
    'GET /api/bookings/{bookingId}/review': 'Get Review for Booking',

    // Admin
    'POST /api/admin/login': 'Admin Login (Secure Credential Auth)',
    'GET /api/admin/me': 'Get Admin Profile',
    'PUT /api/admin/me': 'Update Admin Profile Information',
    'GET /api/admin/dashboard': 'Get High-Level Admin Dashboard KPI Stats',
    'GET /api/admin/analytics': 'Get Business & Financial Analytics Overview',
    'GET /api/admin/ai-insights': 'Get AI Generated Operational Insights',
    'GET /api/admin/reports': 'Get Comprehensive Platform Reports',
    'GET /api/admin/customers': 'List All Registered Customers (Paginated & Filtered)',
    'GET /api/admin/customers/{id}': 'Get Customer Profile by ID',
    'PATCH /api/admin/customers/{id}/status': 'Toggle Customer Active / Suspended Status',
    'GET /api/admin/workers': 'List All Workers with Verification & Category Filters',
    'POST /api/admin/workers': 'Register New Worker Manually by Admin',
    'GET /api/admin/workers/{id}': 'Get Worker Details by ID',
    'PUT /api/admin/workers/{id}': 'Update Worker Profile & Verification Badges',
    'PATCH /api/admin/workers/{id}/status': 'Approve, Reject or Suspend Worker Account',
    'GET /api/admin/workers/{id}/verification': 'Get Worker KYC & Identity Documents for Review',
    'PATCH /api/admin/workers/{id}/verification': 'Approve or Reject Worker Identity Documents',
    'GET /api/admin/workers/{workerId}/certificates': 'List Worker Skill Certificates for Admin Review',
    'PATCH /api/admin/workers/{workerId}/certificates/{certificateId}': 'Approve / Reject Skill Certificate',
    'GET /api/admin/bookings': 'List All Bookings across Platform (Filtered by Status & Date)',
    'GET /api/admin/bookings/{id}': 'Get Booking Details by ID',
    'PATCH /api/admin/bookings/{id}/assign': 'Manually Reassign Booking to Different Worker',
    'PATCH /api/admin/bookings/{id}/status': 'Update Booking Lifecycle Status',
    'PATCH /api/admin/bookings/{bookingId}/assign': 'Manually Reassign Booking to Different Worker',
    'PATCH /api/admin/bookings/{bookingId}/status': 'Update Booking Lifecycle Status',
    'GET /api/admin/categories': 'Get All Service Categories for Admin',
    'POST /api/admin/categories': 'Create New Category with Single Image Upload & Instant Redis Push',
    'GET /api/admin/services': 'List All Services & Pricing Catalog',
    'POST /api/admin/services': 'Create New Service with Image Upload & Redis Push',
    'PUT /api/admin/services/{id}': 'Update Service Details (Invalidates Redis Cache)',
    'DELETE /api/admin/services/{id}': 'Delete Service from Catalog (Invalidates Redis Cache)',
    'POST /api/admin/upload': 'Upload Single Media File to Cloudinary',
    'GET /api/admin/payments': 'List All Platform Financial Transactions',
    'GET /api/admin/payments/stats': 'Get Revenue, Platform Fees & Financial Summary',
    'GET /api/admin/reviews': 'Moderate All Customer Reviews & Ratings',
    'DELETE /api/admin/reviews/{id}': 'Delete Flagged / Inappropriate Review',
    'GET /api/admin/notifications': 'List Sent Broadcast Notifications',
    'POST /api/admin/notifications/broadcast': 'Send Mass Push / Email Broadcast to Users',
    'PUT /api/admin/notifications/mark-read': 'Mark Notifications as Read',
    'DELETE /api/admin/notifications/{id}': 'Delete Notification by ID',
    'GET /api/admin/settings': 'Get Global Platform Governance Settings',
    'PUT /api/admin/settings': 'Update Platform Commission Rates & Search Radius',
    'GET /api/admin/support/tickets': 'List Support Helpdesk Tickets',
    'GET /api/admin/support/tickets/{id}': 'Get Support Ticket Details & Thread',
    'PATCH /api/admin/support/tickets/{id}': 'Update Ticket Priority / Status',
    'POST /api/admin/support/tickets/{id}/messages': 'Send Admin Reply to Support Ticket',
    'GET /api/admin/cooperative': 'Get Cooperative Governance Overview',
    'PUT /api/admin/cooperative': 'Update Cooperative Governance Policy',
    'GET /api/admin/cooperative/members': 'List Cooperative Enrolled Worker Members',
    'GET /api/admin/welfare/summary': 'Get Worker Welfare Fund & Insurance Summary',
    'GET /api/admin/worker-payouts': 'List Pending & Completed Worker Payouts',

    // Payments
    'POST /api/payments/create-order': 'Create Razorpay Order for Booking Payment',
    'POST /api/payments/verify': 'Verify Razorpay Signature & Confirm Booking Payment',
    'GET /api/payments/wallet-history': 'Get Customer Payment & Wallet History',
    'GET /api/payments/worker-wallet': 'Get Worker Wallet Financial Balance',

    // Reviews
    'POST /api/reviews/{bookingId}': 'Submit Review, Rating & Skill Badges for Completed Job',

    // Home
    'GET /api/home/home': 'Get Home Dashboard Data (Banners, Categories & Top Services)',
    'GET /api/home/categories': 'Get All Categories for Home Screen',
    'POST /api/home/categories': 'Create Category via Home Controller',
    'GET /api/home/services/{serviceId}': 'Get Service Details for Home Screen',
    'GET /api/home/extra-parts': 'Get Extra Parts Catalog for Home Screen',

    // Users
    'GET /api/users/me': 'Get Customer Profile Information',
    'PUT /api/users/me': 'Update Customer Profile Details',
    'PATCH /api/users/me': 'Partially Update Customer Profile',
    'GET /api/users/me/addresses': 'List Customer Saved Delivery Addresses',
    'POST /api/users/me/addresses': 'Add New Saved Delivery Address',
    'PUT /api/users/me/addresses/{id}': 'Update Saved Delivery Address',
    'DELETE /api/users/me/addresses/{id}': 'Delete Saved Delivery Address',
    'PATCH /api/users/me/emergency-contact': 'Update Customer Emergency Contact',
    'PATCH /api/users/me/language': 'Update Preferred App Language',
    'PATCH /api/users/me/location': 'Update Customer Default GPS Location Coordinates',

    // KYC & Verification
    'GET /api/verification/me': 'Get Worker Verification & KYC Submission Status',
    'POST /api/verification/submit': 'Submit Initial Worker KYC Documents',
    'POST /api/verification/resubmit': 'Resubmit Rejected Worker KYC Documents',
    'GET /api/worker-certificates/': 'List Worker Certificates',
    'POST /api/worker-certificates/': 'Upload New Skill Certificate for Verification',
    'GET /api/worker-certificates/{id}': 'Get Certificate Details by ID',
    'DELETE /api/worker-certificates/{id}': 'Delete Certificate by ID',

    // Worker Wallet
    'GET /api/worker-wallet/wallet': 'Get Worker Live Wallet Balance & Pending Payouts',
    'GET /api/worker-wallet/earnings': 'Get Detailed Worker Earnings Breakdown',
    'GET /api/worker-wallet/earnings/summary': 'Get Worker Daily, Weekly & Monthly Earnings Overview',
    'GET /api/worker-wallet/payouts': 'List Worker Completed & Processing Payouts',
    'GET /api/worker-wallet/transactions': 'List Worker Wallet Debit & Credit Transactions',
    'POST /api/worker-wallet/withdraw': 'Submit Payout Withdrawal Request to Bank Account / UPI',

    // Support
    'GET /api/support/tickets': 'List User Support Tickets',
    'POST /api/support/tickets': 'Create New Customer / Worker Support Ticket',
    'GET /api/support/tickets/{id}': 'Get Support Ticket Details & Message History',
    'PATCH /api/support/tickets/{id}/close': 'Close Resolved Support Ticket',
    'POST /api/support/tickets/{id}/messages': 'Send Message in Support Ticket Thread',

    // Notifications
    'GET /api/notifications/': 'List User In-App Notifications',
    'POST /api/notifications/device-token': 'Register Device Push Token for FCM',
    'DELETE /api/notifications/device-token': 'Remove Device Push Token on Logout',
    'PATCH /api/notifications/read-all': 'Mark All In-App Notifications as Read',
    'PATCH /api/notifications/{id}/read': 'Mark Single Notification as Read',
    'DELETE /api/notifications/{id}': 'Delete Notification by ID',

    // Cooperative
    'GET /api/cooperative/info': 'Get Cooperative Registration & Welfare Policy Info',

    // Welfare
    'GET /api/welfare/': 'Get Worker Welfare Program Overview & Fund Status',
    'GET /api/welfare/insurance': 'Get Worker Health & Accidental Insurance Policy Details',
    'GET /api/welfare/insurance/claims': 'List Worker Insurance Claims',
    'POST /api/welfare/insurance/claims': 'Submit Insurance Claim Form with Medical Proof',
    'GET /api/welfare/transactions': 'Get Worker Welfare Contribution History',

    // AI Assistant
    'POST /api/ai/match-workers': 'AI Worker Matching based on Skills, Distance & Reliability',
    'POST /api/ai/service-discovery': 'AI Conversational Service Recommendation',
    'POST /api/ai/analyze-issue': 'AI Visual & Audio Problem Diagnosis for Repairs',
    'GET /api/ai/demand-forecast': 'AI Surge & Demand Forecasting by Geographic Region',

    // Upload
    'POST /api/upload/': 'Upload Single Image / Document to Cloudinary',
    'POST /api/upload/many': 'Upload Multiple Media Files (Batch Upload)',

    // General
    'GET /': 'Health Check & Platform Status'
};

const TAG_ORDER = [
    'Auth',
    'Workers',
    'Services',
    'Bookings',
    'Admin',
    'Payments',
    'Reviews',
    'Home',
    'Users',
    'KYC & Verification',
    'Worker Wallet',
    'Support',
    'Notifications',
    'Cooperative',
    'Welfare',
    'AI Assistant',
    'Upload',
    'General'
];

function getTagForPath(path) {
    if (path.startsWith('/api/auth')) return 'Auth';
    if (path.startsWith('/api/workers')) return 'Workers';
    if (path.startsWith('/api/services')) return 'Services';
    if (path.startsWith('/api/bookings')) return 'Bookings';
    if (path.startsWith('/api/admin')) return 'Admin';
    if (path.startsWith('/api/payments')) return 'Payments';
    if (path.startsWith('/api/reviews')) return 'Reviews';
    if (path.startsWith('/api/home')) return 'Home';
    if (path.startsWith('/api/users')) return 'Users';
    if (path.startsWith('/api/verification') || path.startsWith('/api/worker-certificates')) return 'KYC & Verification';
    if (path.startsWith('/api/worker-wallet')) return 'Worker Wallet';
    if (path.startsWith('/api/support')) return 'Support';
    if (path.startsWith('/api/notifications')) return 'Notifications';
    if (path.startsWith('/api/cooperative')) return 'Cooperative';
    if (path.startsWith('/api/welfare')) return 'Welfare';
    if (path.startsWith('/api/ai')) return 'AI Assistant';
    if (path.startsWith('/api/upload')) return 'Upload';
    return 'General';
}

function generateFallbackSummary(method, path) {
    const cleanPath = path.replace('/api/', '').replace(/{[^}]+}/g, '').replace(/\/+/g, ' ').trim();
    const action = method.toUpperCase() === 'GET' ? 'Get' : method.toUpperCase() === 'POST' ? 'Create / Submit' : method.toUpperCase() === 'PUT' ? 'Update' : method.toUpperCase() === 'PATCH' ? 'Modify' : 'Delete';
    return `${action} ${cleanPath}`;
}

async function runSwagger() {
    console.log('⏳ Generating base Swagger documentation...');
    await swaggerAutogen()(outputFile, routesFiles, doc);

    console.log('🔧 Post-processing Swagger schema: Systematic Tagging, Ordering & Summaries...');
    const swaggerContent = JSON.parse(fs.readFileSync(outputFile, 'utf8'));

    // 1. Tag and Summarize every operation
    const categorizedPaths = {};
    TAG_ORDER.forEach(tag => {
        categorizedPaths[tag] = {};
    });

    for (const [path, methods] of Object.entries(swaggerContent.paths)) {
        const tag = getTagForPath(path);
        if (!categorizedPaths[tag]) categorizedPaths[tag] = {};

        for (const [method, op] of Object.entries(methods)) {
            const opKey = `${method.toUpperCase()} ${path}`;
            const summary = ROUTE_SUMMARIES[opKey] || op.summary || generateFallbackSummary(method, path);

            op.tags = [tag];
            op.summary = summary;
            if (!op.description || op.description.trim() === '') {
                op.description = summary;
            }

            // Standardize bearerAuth security requirement if under protected paths
            const isProtected = path.startsWith('/api/admin') ||
                                path.includes('/me') ||
                                path.startsWith('/api/bookings') ||
                                path.startsWith('/api/worker-wallet') ||
                                path.startsWith('/api/users');

            if (isProtected && (!op.security || op.security.length === 0)) {
                op.security = [{ bearerAuth: [] }];
            }
        }

        categorizedPaths[tag][path] = methods;
    }

    // 2. Re-assemble paths systematically grouped by TAG_ORDER
    const orderedPaths = {};
    TAG_ORDER.forEach(tag => {
        const pathsForTag = categorizedPaths[tag] || {};
        const sortedPathKeys = Object.keys(pathsForTag).sort();
        for (const p of sortedPathKeys) {
            orderedPaths[p] = pathsForTag[p];
        }
    });

    swaggerContent.paths = orderedPaths;
    swaggerContent.tags = doc.tags;

    fs.writeFileSync(outputFile, JSON.stringify(swaggerContent, null, 2), 'utf8');
    console.log('✅ Swagger documentation successfully redesigned and formatted!');
    console.log(`📊 Total routes systematically organized: ${Object.keys(orderedPaths).length} across ${TAG_ORDER.length} clean categories.`);
}

runSwagger().catch(err => {
    console.error('❌ Error generating Swagger docs:', err);
    process.exit(1);
});