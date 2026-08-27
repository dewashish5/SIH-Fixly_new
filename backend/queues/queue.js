import dotenv from "dotenv";
dotenv.config();
import { Queue } from "bullmq";
import Redis from "ioredis";

// Reuse the redis connection or create a new one for BullMQ
const connectionRedis = new Redis(process.env.REDIS_URL, {
    maxRetriesPerRequest: null
});

// Pass it using the "connection" key
const emailQueue = new Queue("emailQueue", { connection: connectionRedis });

export default emailQueue;