import { transporter } from '../config/nodemailer.js';

export const sendEmail = async ({ to, subject, html }) => {
    try {
        const info = await transporter.sendMail({
            from: `"Support Team" <${process.env.SMTP_USER}>`,
            to,
            subject,
            html
        });
        console.log(`Email sent successfully: ${info.messageId}`);
        return info;
    } catch (error) {
        console.error(`Failed to send email to ${to}:`, error.message);
        throw error; // Error throw karna zaroori hai taaki BullMQ ko pata chale job fail ho gayi
    }
};