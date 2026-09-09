import Redis from 'ioredis';

const redis = new Redis(process.env.REDIS_URL || 'redis://localhost:6379', {
    maxRetriesPerRequest: null, // BullMQ ke background queues/workers ke liye mandatory hai
    enableReadyCheck: false,
    retryStrategy(times) {
        if (process.env.NODE_ENV === 'test') {
            return null; // Stop retrying in test mode
        }
        const delay = Math.min(times * 200, 2000);
        return delay;
    }
});

redis.on('connect', () => {
    console.log('Redis connected successfully ✅');
});

redis.on('error', (err) => {
    console.error('Redis connection error:', err);
});

export const redisConnection = redis;
export default redis;