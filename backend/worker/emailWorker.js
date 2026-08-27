import { Worker } from 'bullmq';
import redis from '../config/redis.js';
import { sendEmail } from '../utils/sendEmail.js';

const emailWorker = new Worker('emailQueue', async (job) => {
    const { to, subject, html } = job.data;

    // Call the modular send email function
    await sendEmail({ to, subject, html });

}, {
    connection: redis,
    concurrency: 10 // Optional: Ek sath kitni emails process karni hain background mein
});

emailWorker.on('completed', (job) => {
    console.log(`Job ${job.id} completed successfully.`);
});

emailWorker.on('failed', (job, err) => {
    console.log(`Job ${job.id} failed with error: ${err.message}`);
});

export default emailWorker;