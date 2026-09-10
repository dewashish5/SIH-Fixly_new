import readline from "readline";
import mongoose from "mongoose";
import dotenv from "dotenv";
dotenv.config();

import connectDB from "./config/db.js";
import redis from "./config/redis.js";
import User from "./models/User.js";
import { processFixlyAgentMessage } from "./agent/index.js";
import { ensureTestWorkersOnline } from "./agent/services/workerService.js";

// ANSI Terminal Colors
const CYAN = "\x1b[36m";
const GREEN = "\x1b[32m";
const YELLOW = "\x1b[33m";
const MAGENTA = "\x1b[35m";
const BLUE = "\x1b[34m";
const RED = "\x1b[31m";
const BOLD = "\x1b[1m";
const RESET = "\x1b[0m";

async function main() {
    console.clear();
    console.log(`${BOLD}${CYAN}========================================================================${RESET}`);
    console.log(`${BOLD}${CYAN}   🚀 FIXLY CONVERSATIONAL AI AGENT - TERMINAL INTERACTIVE CONSOLE     ${RESET}`);
    console.log(`${BOLD}${CYAN}========================================================================${RESET}`);
    console.log(`${YELLOW}Connecting to MongoDB and Redis...${RESET}`);

    try {
        await connectDB();
        await redis.ping();
        console.log(`${GREEN}✅ Connected to MongoDB & Redis successfully.${RESET}`);

        // Ensure workers are online for smooth interactive testing
        await ensureTestWorkersOnline();
        console.log(`${GREEN}✅ Verified workers activated as online for testing.${RESET}`);

        // Find or create test customer
        let testUser = await User.findOne({ role: "customer" }).lean();
        if (!testUser) {
            testUser = await User.create({
                name: "Test Customer",
                email: "test.customer@fixly.local",
                phone: "+91 9999900000",
                password: "Password123!",
                role: "customer",
                isVerified: true,
                savedAddresses: [{
                    label: "Home",
                    addressLine: "Flat 402, Green Valley Apartments, Noida",
                    city: "Noida",
                    pincode: "201301",
                    location: { type: "Point", coordinates: [77.3639, 28.6280] }
                }]
            });
        }

        let currentLang = "en";
        const userId = String(testUser._id);
        console.log(`${BLUE}👤 Active Test User: ${BOLD}${testUser.name}${RESET} (ID: ${userId})`);
        console.log(`${YELLOW}🌐 Active Language: ${BOLD}${currentLang === 'hi' ? 'हिंदी (Pure Hindi - Devanagari)' : 'English (Pure English)'}${RESET}`);
        console.log(`${MAGENTA}Commands:${RESET}`);
        console.log(` • Type ${BOLD}'hi'${RESET} or ${BOLD}'en'${RESET} to toggle language (Pure Hindi vs Pure English)`);
        console.log(` • Type ${BOLD}'reset'${RESET} to clear session and start fresh`);
        console.log(` • Type ${BOLD}'workers'${RESET} to list all DB workers`);
        console.log(` • Type ${BOLD}'exit'${RESET} to quit console`);
        console.log(`${CYAN}------------------------------------------------------------------------${RESET}\n`);

        const rl = readline.createInterface({
            input: process.stdin,
            output: process.stdout,
            terminal: Boolean(process.stdin.isTTY)
        });

        process.stdout.write(`${BOLD}${GREEN}[${currentLang}] You > ${RESET}`);

        for await (const line of rl) {
            const text = line.trim();

            if (!text) {
                process.stdout.write(`${BOLD}${GREEN}[${currentLang}] You > ${RESET}`);
                continue;
            }

            if (text.toLowerCase() === "exit" || text.toLowerCase() === "quit") {
                console.log(`\n${YELLOW}Exiting Fixly Console. Goodbye!${RESET}`);
                break;
            }

            if (text.toLowerCase() === "hi" || text.toLowerCase() === "hindi" || text.toLowerCase() === "lang hi") {
                currentLang = "hi";
                console.log(`\n${GREEN}🌐 Language set to: ${BOLD}हिंदी (Pure Hindi - Devanagari)${RESET}\n`);
                process.stdout.write(`${BOLD}${GREEN}[${currentLang}] You > ${RESET}`);
                continue;
            }

            if (text.toLowerCase() === "en" || text.toLowerCase() === "english" || text.toLowerCase() === "lang en") {
                currentLang = "en";
                console.log(`\n${GREEN}🌐 Language set to: ${BOLD}English (Pure English)${RESET}\n`);
                process.stdout.write(`${BOLD}${GREEN}[${currentLang}] You > ${RESET}`);
                continue;
            }

            if (text.toLowerCase() === "workers") {
                const workers = await User.find({ role: "worker", isVerified: true })
                    .select("name workerProfile phone")
                    .lean();
                console.log(`\n${BOLD}${MAGENTA}--- VERIFIED WORKERS IN DATABASE ---${RESET}`);
                workers.forEach((w, i) => {
                    console.log(` ${i + 1}. ${BOLD}${w.name}${RESET} | Cat: ${w.workerProfile?.category} | Rate: ₹${w.workerProfile?.rate}/hr | Rating: ${w.workerProfile?.rating}★ | ID: ${w._id}`);
                });
                console.log(`-------------------------------------\n`);
                process.stdout.write(`${BOLD}${GREEN}[${currentLang}] You > ${RESET}`);
                continue;
            }

            try {
                // Send message to Fixly AI Agent (same pipeline as HTTP API)
                const res = await processFixlyAgentMessage({
                    userId,
                    message: text,
                    conversationState: {},
                    explicitLanguage: currentLang
                });

                // 1. AI Reply
                console.log(`\n${BOLD}${CYAN}🤖 Fixly AI:${RESET} ${res.reply}`);

                // 2. Action & Step Status
                console.log(`${YELLOW}⚡ [Action]:${RESET} ${BOLD}${res.action}${RESET} | ${YELLOW}[Step]:${RESET} ${res.state?.step || "NONE"} | ${YELLOW}[Category]:${RESET} ${res.state?.category || "None"}`);

                // 3. Workers Card Data (if returned)
                if (res.data?.workers && res.data.workers.length > 0) {
                    console.log(`\n${BOLD}${MAGENTA}📦 [DATA.WORKERS AVAILABLE (${res.data.workers.length})]:${RESET}`);
                    res.data.workers.forEach((w, idx) => {
                        console.log(`   ${idx + 1}. ${BOLD}${w.name}${RESET} (⭐ ${w.rating}, ${w.experienceYears}y exp, ₹${w.hourlyRate}/hr, ~${w.distanceKm} km away) [ID: ${w._id}]`);
                    });
                }

                // 4. Estimate & Policy (if returned)
                if (res.data?.estimate) {
                    console.log(`\n${BOLD}${GREEN}💰 [DATA.ESTIMATE & FAIR WAGE POLICY]:${RESET}`);
                    console.log(`   • Base Service Fee:  ₹${res.data.estimate.baseServiceFee}`);
                    if (res.data.estimate.urgentFee > 0) {
                        console.log(`   • Emergency SOS Fee: ₹${res.data.estimate.urgentFee}`);
                    }
                    console.log(`   • Platform Fee:      ₹0 (Fixly 0% middleman)`);
                    console.log(`   • Total Amount:      ₹${res.data.estimate.totalAmount}`);
                    console.log(`   🛡️ ${res.data.policy?.fairWageNotice || "100% directly to worker"}`);
                }

                // 5. Booking Confirmation Details (if created)
                if (res.data?.booking) {
                    console.log(`\n${BOLD}${GREEN}🎉 [DATA.BOOKING CREATED SUCCESSFULLY]:${RESET}`);
                    console.log(`   • Booking ID:   ${res.data.booking.bookingId}`);
                    console.log(`   • Status:       ${res.data.booking.status}`);
                    console.log(`   • Worker:       ${res.data.booking.worker?.name || "Auto-assigned nearest worker"}`);
                    console.log(`   • Total Amount: ₹${res.data.booking.invoice?.totalAmount}`);
                    console.log(`   • Address:      ${res.data.booking.serviceAddress?.addressLine}`);
                }

                // 6. Suggested Quick Reply Chips
                if (res.suggestedReplies && res.suggestedReplies.length > 0) {
                    console.log(`\n${BLUE}💡 [Suggested Chips]:${RESET} ${res.suggestedReplies.map(r => `[${r}]`).join("  ")}`);
                }

                console.log(`\n${CYAN}------------------------------------------------------------------------${RESET}\n`);
            } catch (err) {
                console.log(`\n${RED}❌ Error processing message:${RESET}`, err.message);
                console.log(`\n${CYAN}------------------------------------------------------------------------${RESET}\n`);
            }

            process.stdout.write(`${BOLD}${GREEN}[${currentLang}] You > ${RESET}`);
        }

        rl.close();
        await mongoose.disconnect();
        await redis.quit();
        process.exit(0);

    } catch (err) {
        console.error(`${RED}Startup error:${RESET}`, err);
        process.exit(1);
    }
}

main();
