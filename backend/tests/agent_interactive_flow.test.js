import test from 'node:test';
import assert from 'node:assert/strict';
import mongoose from 'mongoose';
import dotenv from 'dotenv';
dotenv.config();

import redis from '../config/redis.js';
import { processFlexiAgentMessage } from '../agent/index.js';

test('AI Agent Interactive Conversation Flow (LangGraph Architecture)', async (t) => {
    console.log('\n========================================================');
    console.log('🤖 Fixly "Hey Flexi" Multi-Agent LangGraph Test');
    console.log('========================================================');

    if (mongoose.connection.readyState === 0) {
        try {
            await mongoose.connect(process.env.MONGO_URI);
            console.log('✅ MongoDB connected for test suite');
        } catch (err) {
            console.warn('⚠️ MongoDB connection error:', err.message);
        }
    }

    t.after(async () => {
        if (mongoose.connection.readyState === 1) {
            await mongoose.disconnect();
        }
        try {
            await redis.quit();
        } catch (e) {}
    });

    const dummyUserId = '64f1bc000000000000000001';
    try {
        await redis.del(`flexi:session:${dummyUserId}`);
    } catch (e) {}

    // TURN 1: Initial speech requesting plumber
    await t.test('Turn 1: Spoken Hindi voice-to-text input', async () => {
        const input = 'नमस्ते फ्लेक्सी, मुझे घर के लिए एक प्लंबर चाहिए नल से पानी टपक रहा है';
        console.log(`\n🗣️ [User Voice Input]: "${input}"`);

        const res1 = await processFlexiAgentMessage({
            userId: dummyUserId,
            message: input,
            conversationState: {},
            explicitLanguage: 'hi',
        });

        console.log(`🤖 [Agent Reply]: "${res1.reply}"`);
        console.log(`⚡ [Action]: ${res1.action}`);
        console.log(`📊 [Extracted Category]: ${res1.state.category}`);

        assert.equal(res1.state.category, 'Plumbing');
        assert.ok(res1.reply.length > 10);
        assert.equal(res1.action, 'PROMPT_CONFIRMATION');
    });

    // TURN 2: Emergency SOS trigger
    await t.test('Turn 2: Customer specifies urgency (Emergency SOS)', async () => {
        const input = 'हाँ तुरंत चाहिए बहुत ज्यादा लीकेज है urgent sos';
        console.log(`\n🗣️ [User Voice Input]: "${input}"`);

        const res2 = await processFlexiAgentMessage({
            userId: dummyUserId,
            message: input,
            conversationState: { category: 'Plumbing' },
            explicitLanguage: 'hi',
        });

        console.log(`🤖 [Agent Reply]: "${res2.reply}"`);
        console.log(`⚡ [Action]: ${res2.action}`);
        console.log(`📊 [Urgency Type]: ${res2.state.bookingType}`);

        assert.equal(res2.state.bookingType, 'EMERGENCY_SOS');
        assert.equal(res2.state.isEmergency, true);
        assert.equal(res2.action, 'CONFIRM_EMERGENCY_BOOKING');
    });

    // TURN 3: Customer queries active booking status
    await t.test('Turn 3: Customer queries active booking status', async () => {
        const input = 'मेरी बुकिंग का स्टेटस बताओ';
        console.log(`\n🗣️ [User Voice Input]: "${input}"`);

        const res3 = await processFlexiAgentMessage({
            userId: dummyUserId,
            message: input,
            conversationState: {},
            explicitLanguage: 'hi',
        });

        console.log(`🤖 [Agent Reply]: "${res3.reply}"`);
        console.log(`⚡ [Action]: ${res3.action}`);

        assert.ok(res3.action === 'BOOKING_STATUS' || res3.action === 'NO_BOOKINGS');
    });

    // TURN 4: Off-topic Guardrail rejection
    await t.test('Turn 4: Off-topic Guardrail Rejection', async () => {
        const input = 'आज का क्रिकेट मैच का स्कोर क्या है?';
        console.log(`\n🗣️ [User Voice Input]: "${input}"`);

        const res4 = await processFlexiAgentMessage({
            userId: dummyUserId,
            message: input,
            conversationState: {},
            explicitLanguage: 'hi',
        });

        console.log(`🤖 [Agent Reply]: "${res4.reply}"`);
        console.log(`⚡ [Action]: ${res4.action}`);

        assert.equal(res4.action, 'OFF_TOPIC_GUARD');
        assert.ok(res4.reply.includes('माफ़ कीजिए') || res4.reply.includes('Fixly'));
    });

    console.log('\n========================================================');
    console.log('✅ ALL LANGGRAPH CONVERSATION STEPS VERIFIED!');
    console.log('========================================================\n');
});
