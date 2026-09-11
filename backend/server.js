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
import "./worker/uploadWorker.js";
import "./worker/notificationWorker.js";
import "./worker/scheduledBookingWorker.js";

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
import uploadRoutes from './routes/upload-routes.js';
import adminRoutes from './routes/admin-routes.js';
import userRoutes from './routes/user-routes.js';
import verificationRoutes from './routes/verification-routes.js';
import workerCertificateRoutes from './routes/worker-certificate-routes.js';
import workerWalletRoutes from './routes/worker-wallet-routes.js';
import notificationRoutes from './routes/notification-routes.js';
import supportRoutes from './routes/support-routes.js';
import cooperativeRoutes from './routes/cooperative-routes.js';
import welfareRoutes from './routes/welfare-routes.js';
import webrtcRoutes from './routes/webrtc-call-routes.js';
import agentRoutes from './routes/agent-routes.js';
import emergencyRoutes from './routes/emergency-routes.js';
import appVersionRoutes from './routes/app-version-routes.js';

const app = express();
const httpServer = createServer(app);
const PORT = process.env.PORT || 8000;

// AWS ALB / Nginx Proxy support
app.set('trust proxy', 1);

// Security & Utility Middleware
app.use(helmet());
app.use(cors());
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ limit: '50mb', extended: true }));

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

// Dynamic Swagger Auto-Load with Clean Systematic UI Configuration
try {
    const swaggerDocument = JSON.parse(
        fs.readFileSync(new URL('./swagger-output.json', import.meta.url))
    );
    const swaggerUiOptions = {
        customSiteTitle: 'GigConnect API Platform Docs',
        swaggerOptions: {
            docExpansion: 'none', // Collapses all sections initially so user can browse cleanly
            filter: true, // Enables real-time keyword search bar
            tagsSorter: false, // Strictly preserves custom category order (Auth -> Workers -> Services -> Bookings -> Admin etc.)
            operationsSorter: 'alpha'
        }
    };
    app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerDocument, swaggerUiOptions));
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

// API Routes Mounting
app.use('/api/auth', authRoutes);
app.use('/api/bookings', apiLimiter, bookingRoutes);
app.use('/api/emergency', apiLimiter, emergencyRoutes);
app.use('/api/workers', workerRoutes);
app.use('/api/services', serviceRoutes);
app.use('/api/payments', paymentRoutes);
app.use('/api/reviews', reviewRoutes);
app.use('/api/home', homeRoutes);
app.use('/api/ai', aiRoutes);
app.use('/api/upload', uploadRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/users', userRoutes);
app.use('/api/verification', verificationRoutes);
app.use('/api/worker-certificates', workerCertificateRoutes);
app.use('/api/worker-wallet', workerWalletRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/support', supportRoutes);
app.use('/api/cooperative', cooperativeRoutes);
app.use('/api/welfare', welfareRoutes);
app.use('/api/webrtc', webrtcRoutes);
app.use('/api/ai/agent', agentRoutes);
app.use('/api/agent', agentRoutes);
app.use('/api/version', appVersionRoutes);
app.use('/api/app-version', appVersionRoutes);

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