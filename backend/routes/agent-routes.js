import express from 'express';
import { protect } from '../middleware/authMiddleware.js';
import {
  chatWithFlexiAgent,
  mintLiveToken,
  liveToolBridge,
} from '../controllers/agentController.js';

const router = express.Router();

// POST /api/ai/agent/chat
router.post('/chat', protect, chatWithFlexiAgent);
// POST /api/ai/agent/live-token — ephemeral Gemini Live auth for device WS
router.post('/live-token', protect, mintLiveToken);
// POST /api/ai/agent/live-tool — Flash brain bridge for Live tool calls
router.post('/live-tool', protect, liveToolBridge);

export default router;
