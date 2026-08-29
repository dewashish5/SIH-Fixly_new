import dotenv from 'dotenv';
dotenv.config();
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import { createServer } from 'http';
import fs from 'fs';
import swaggerUi from 'swagger-ui-express';
import events from 'events';

import connectDB from './config/db.js';
import "./worker/emailWorker.js";

// Middlewares
import { initSocket } from './config/socket.js';
import { authLimiter, apiLimiter } from './middleware/rateLimiter.js';

// Route Imports
import authRoutes from './routes/auth-routes.js';
import bookingRoutes from './routes/booking-routes.js';
import workerRoutes from './routes/worker-routes.js';
import serviceRoutes from './routes/service-routes.js';
import paymentRoutes from './routes/payment-routes.js';
import reviewRoutes from './routes/review-routes.js';
import homeRoutes from './routes/home-routes.js';
import aiRoutes from './routes/ai-routes.js';

const app = express();
const httpServer = createServer(app);
const PORT = process.env.PORT || 8000;

// AWS ALB / Nginx Proxy support
app.set('trust proxy', 1);

// Security & Utility Middleware
app.use(helmet());
app.use(cors());
app.use(express.json({ limit: '10kb' }));

// Safe Custom NoSQL Injection Sanitizer (Compatible with Node.js v20+)
app.use((req, res, next) => {
    const sanitizeValue = (val) => {
        if (val && typeof val === 'object') {
            for (const key of Object.keys(val)) {
                if (key.startsWith('$') || key.includes('.')) {
                    delete val[key];
                } else {
                    sanitizeValue(val[key]);
                }
            }
        }
    };
    if (req.body) sanitizeValue(req.body);
    if (req.params) sanitizeValue(req.params);
    next();
});

// Set default max listeners cleanly
events.defaultMaxListeners = 20;

// Dynamic Swagger Auto-Load
try {
    const swaggerDocument = JSON.parse(
        fs.readFileSync(new URL('./swagger-output.json', import.meta.url))
    );
    app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerDocument));
} catch (error) {
    console.log('⚠️ Swagger docs file missing. Run "npm run swagger" to generate documentation.');
}

// Health Check Route
app.get('/', (req, res) => {
    res.status(200).json({
        status: 'success',
        message: 'GigConnect API Platform is active'
    });
});

// API Routes Mounting with Rate Limiters where appropriate
app.use('/api/auth', authLimiter, authRoutes);
app.use('/api/bookings', apiLimiter, bookingRoutes);
app.use('/api/workers', apiLimiter, workerRoutes);
app.use('/api/services', serviceRoutes);
app.use('/api/payments', paymentRoutes);
app.use('/api/reviews', reviewRoutes);
app.use('/api/home', homeRoutes);
app.use('/api/ai', aiRoutes);

// Global Error Handler
app.use((err, req, res, next) => {
    console.error('Global Error Captured:', err.stack || err);
    res.status(500).json({
        success: false,
        message: err.message || 'Internal Server Error'
    });
});

// Start Server & Database Connection
const start = async () => {
    try {
        await connectDB();

        const io = initSocket(httpServer);
        app.set('io', io);

        httpServer.listen(PORT, () => {
            console.log(`🚀 Server running on port ${PORT}`);
            console.log(`📑 Swagger Docs live at: http://localhost:${PORT}/api-docs`);
        });
    } catch (error) {
        console.error('Server startup error:', error);
        process.exit(1);
    }
};

start();

// import dotenv from 'dotenv';
// dotenv.config();
// import express from 'express';
// import cors from 'cors';
// import helmet from 'helmet';
// import mongoSanitize from 'express-mongo-sanitize';
// import { createServer } from 'http';
// import connectDB from './config/db.js';
// import authRouter from './routes/auth-routs.js';
// import "./worker/emailWorker.js";

// // Rate Limiters aur Socket import
// // import { authLimiter, apiLimiter } from './middlewares/rateLimiter.js';
// import { initSocket } from './config/socket.js';
// import { authLimiter } from './middleware/rateLimiter.js';

// const app = express();
// const httpServer = createServer(app);
// const PORT = process.env.PORT || 8000;

// // AWS ALB / Nginx Proxy ke peeche IP track karne ke liye VERY IMPORTANT
// // Varna Rate Limiter sabko Load Balancer ki ek hi IP samajh kar block kar dega
// app.set('trust proxy', 1);

// // Security & Utility Middleware
// app.use(helmet());
// app.use(cors());
// app.use(express.json({ limit: '10kb' })); // Payload size limit
// app.use(mongoSanitize()); // Prevent NoSQL Injection

// // Health Check Route (AWS Target Group Checks ke liye)
// app.get('/', (req, res) => {
//     res.status(200).json({
//         status: 'success',
//         message: 'Cooperative Gig Services Platform API is active'
//     });
// });

// // API Routes Mount with Strict Rate Limiters
// app.use('/api/auth', authLimiter, authRouter);

// // Future endpoints par apiLimiter lagayenge:
// // app.use('/api/bookings', apiLimiter, bookingRoutes);
// // app.use('/api/workers', apiLimiter, workerRoutes);

// // GLOBAL ERROR HANDLER (console.err ko console.error me fix kiya hai)
// app.use((err, req, res, next) => {
//     console.error('Global Error Captured:', err.stack || err);
//     res.status(500).json({
//         success: false,
//         message: err.message || 'Internal Server Error'
//     });
// });

// // Start Server & Database
// const start = async () => {
//     try {
//         await connectDB();

//         // 10,000 scale ke liye Socket.io HTTP server par initialize hoga
//         const io = initSocket(httpServer);
//         app.set('io', io); // Jisse controllers `req.app.get('io')` karke events emit kar sakein

//         // HTTP aur Socket dono ek hi port par listen karenge
//         httpServer.listen(PORT, () => {
//             console.log(`🚀 Server running on port ${PORT}`);
//         });
//     } catch (error) {
//         console.error('Server startup error:', error);
//         process.exit(1);
//     }
// };

// start();





// prev working

// import dotenv from 'dotenv';
// dotenv.config();
// import express from 'express';
// import cors from 'cors';
// import helmet from 'helmet';
// import { createServer } from 'http';
// import connectDB from './config/db.js';
// import authRouter from './routes/auth-router.js';
// import "./worker/emailWorker.js"; //email worker to start processing jobs


// const app = express();
// const httpServer = createServer(app);
// const PORT = process.env.PORT || 8000;

// // Security & Utility Middleware
// app.use(helmet());
// app.use(cors());
// app.use(express.json());

// // Health Check Route
// app.get('/', (req, res) => {
//     res.status(200).json({
//         status: 'success',
//         message: 'Cooperative Gig Services Platform API is active'
//     });
// });

// // 👇 YEH GLOBAL ERROR HANDLER ADD KAREIN (Taki "next is not a function" error pakdi jaye)
// app.use((err, req, res, next) => {
//     console.err('Global Error Captured:', err.stack || err);
//     res.status(500).json({
//         success: false,
//         message: err.message || 'Internal Server Error'
//     });
// });

// // API Routes Mount
// app.use('/api/auth', authRouter);


// // Start Server & Database
// const start = async () => {
//     try {
//         // Connect to MongoDB using the correct environment variable
//         await connectDB();

//         httpServer.listen(PORT, () => {
//             console.log(`Server running on port ${PORT}`);
//         });
//     } catch (error) {
//         console.error('Server startup error:', error);
//         process.exit(1);
//     }
// };

// start();