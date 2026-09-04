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