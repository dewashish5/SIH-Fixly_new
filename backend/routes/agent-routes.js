import express from 'express';
import { protect } from '../middleware/authMiddleware.js';
import { chatWithFlexiAgent } from '../controllers/agentController.js';

const router = express.Router();

// POST /api/ai/agent/chat (or /api/agent/chat)
router.post('/chat', protect, chatWithFlexiAgent);

export default router;
