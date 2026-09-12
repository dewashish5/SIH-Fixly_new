import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const LOG_FILE = path.join(__dirname, '../logs/ai_chat.log');

function appendToFile(text) {
    try {
        fs.appendFileSync(LOG_FILE, text + '\n', 'utf8');
    } catch (err) {
        console.error('Failed to write to ai_chat.log:', err.message);
    }
}

export const aiLogger = {
    logTurnStart: ({ userId, message, language, coordinates, addressLine, conversationState }) => {
        const timestamp = new Date().toISOString();
        const header = [
            '\n' + '='.repeat(80),
            '🗣️  [CUSTOMER TALKING / REQUEST]',
            `⏰ Timestamp:    ${timestamp}`,
            `👤 Customer ID:  ${userId || 'Anonymous / Guest'}`,
            `💬 Spoken Text:  "${message}"`,
            `🌐 Language:     ${language}`,
            `📍 Coordinates:  ${JSON.stringify(coordinates || null)}`,
            `🏠 Address:      "${addressLine || 'Not provided'}"`,
            `🧠 Prior State:  ${JSON.stringify(conversationState || {})}`,
            '-'.repeat(80),
        ].join('\n');

        console.log(header);
        appendToFile(header);
    },

    logInference: ({ engine, model, extracted, workersCount, issue, correction }) => {
        const lines = [
            '🤖 [AI PROCESSING & INTENT EXTRACTION]',
            `🔮 Engine:       ${engine} ${model ? `(${model})` : ''}`,
            `📊 Extracted:    Category: ${extracted?.category || 'None'} | Type: ${extracted?.bookingType || 'None'} | Confirm: ${extracted?.confirmation || false}`,
            `📝 Problem:      "${extracted?.problemDescription || ''}"`,
            `👷 Workers Avail: ${workersCount !== undefined ? workersCount : 'N/A'}`
        ];

        if (issue) {
            lines.push(`⚠️ Issue:        ${issue}`);
        }
        if (correction) {
            lines.push(`🔧 Auto-Correct: ${correction}`);
        }
        lines.push('-'.repeat(80));

        const output = lines.join('\n');
        console.log(output);
        appendToFile(output);
    },

    logTurnEnd: ({ action, reply, state, booking, suggestedReplies, error }) => {
        const lines = [
            '💬 [AI AGENT REPLY]',
            `⚡ Action:       ${action}`,
            `🗣️ Spoken Reply: "${reply}"`,
            `🔘 Suggestions:  ${JSON.stringify(suggestedReplies || [])}`,
            `📊 Next State:   ${JSON.stringify(state || {})}`
        ];

        if (booking) {
            lines.push(`🎉 Booking Created: #${booking.bookingId || booking._id} [${booking.status}] Worker: ${booking.worker ? (booking.worker.name || booking.worker) : 'Unassigned'}`);
        }

        if (error) {
            lines.push(`❌ Turn Error:   ${error}`);
            lines.push(`🩺 Status:       ⚠️ FAILED`);
        } else {
            lines.push(`🩺 Status:       ✅ HEALTHY (Proper Slot Transition)`);
        }

        lines.push('='.repeat(80) + '\n');

        const output = lines.join('\n');
        console.log(output);
        appendToFile(output);
    }
};
