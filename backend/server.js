import dotenv from 'dotenv';
dotenv.config();
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import { createServer } from 'http';
import connectDB from './config/db.js';
import authRouter from './routes/auth-router.js';
import "./worker/emailWorker.js"; //email worker to start processing jobs


const app = express();
const httpServer = createServer(app);
const PORT = process.env.PORT || 8000;

// Security & Utility Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());

// Health Check Route
app.get('/', (req, res) => {
    res.status(200).json({
        status: 'success',
        message: 'Cooperative Gig Services Platform API is active'
    });
});

// 👇 YEH GLOBAL ERROR HANDLER ADD KAREIN (Taki "next is not a function" error pakdi jaye)
app.use((err, req, res, next) => {
    console.err('Global Error Captured:', err.stack || err);
    res.status(500).json({
        success: false,
        message: err.message || 'Internal Server Error'
    });
});

// API Routes Mount
app.use('/api/auth', authRouter);


// Start Server & Database
const start = async () => {
    try {
        // Connect to MongoDB using the correct environment variable
        await connectDB();

        httpServer.listen(PORT, () => {
            console.log(`Server running on port ${PORT}`);
        });
    } catch (error) {
        console.error('Server startup error:', error);
        process.exit(1);
    }
};

start();


// import express from 'express';
// import mongoose from 'mongoose';
// import dotenv from 'dotenv';
// import cors from 'cors';
// import helmet from 'helmet';
// import { createServer } from 'http';
// // import { Server } from 'socket.io';
// // import { createAdapter } from '@socket.io/redis-adapter';
// // import { createClient } from 'redis';

// // Load environment variables
// dotenv.config();

// const app = express();
// const httpServer = createServer(app);

// // Security & Utility Middleware
// app.use(helmet());
// app.use(cors());
// app.use(express.json());

// // MongoDB Connection
// const connectDB = async () => {
//     try {
//         await mongoose.connect(process.env.MONGO_URI || 'mongodb://localhost:27017/cooperative_db');
//         console.log('MongoDB Connected Successfully');
//     } catch (error) {
//         console.error('MongoDB Connection Error:', error);
//         process.exit(1);
//     }
// };
// connectDB();

// // Redis Clients for Socket.io Adapter
// // const pubClient = createClient({ url: process.env.REDIS_URL || 'redis://localhost:6379' });
// // const subClient = pubClient.duplicate();

// // await Promise.all([pubClient.connect(), subClient.connect()]);

// // Socket.io Setup
// // const io = new Server(httpServer, {
// //   cors: {
// //     origin: '*',
// //     methods: ['GET', 'POST']
// //   }
// // });

// // io.adapter(createAdapter(pubClient, subClient));

// // io.on('connection', (socket) => {
// //   console.log(`New client connected: ${socket.id}`);

// //   socket.on('disconnect', () => {
// //     console.log(`Client disconnected: ${socket.id}`);
// //   });
// // });

// // Health Check Route
// app.get('/', (req, res) => {
//     res.status(200).json({
//         status: 'success',
//         message: 'Cooperative Gig Services Platform API is active'
//     });
// });

// // Start Server
// const PORT = process.env.PORT || 8000;
// httpServer.listen(PORT, () => {
//     console.log(`Server running on port ${PORT}`);
// });