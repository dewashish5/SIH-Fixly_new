import swaggerAutogen from 'swagger-autogen';

const doc = {
    info: {
        title: 'GigConnect Backend API',
        description: 'Auto-generated Swagger documentation for GigConnect services',
    },
    host: 'localhost:8000', // Apka port number
    schemes: ['http', 'https'],
    securityDefinitions: {
        bearerAuth: {
            type: 'apiKey',
            in: 'header',
            name: 'Authorization',
            description: 'Enter JWT token with Bearer prefix (e.g., Bearer <token>)'
        }
    },
    definitions: {
        RegisterInput: {
            name: "John Doe",
            email: "john.doe@example.com",
            password: "SecurePassword123",
            role: "customer",
            phone: "+1234567890",
            location: {
                type: "Point",
                coordinates: [77.2090, 28.6139]
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
            coordinates: [77.2090, 28.6139],
            scheduledTime: "2026-08-30T10:00:00.000Z",
            invoice: {
                baseServiceFee: 85,
                platformFee: 15,
                totalAmount: 100
            }
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

swaggerAutogen()(outputFile, routesFiles, doc);