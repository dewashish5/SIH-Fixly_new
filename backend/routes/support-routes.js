import express from 'express';
import { protect } from '../middleware/authMiddleware.js';
import {
    getActiveOrCreateTicket,
    sendUserMessage,
    escalateActiveTicket,
    resetUserTicket,
    createTicket,
    listMyTickets,
    getTicket,
    addTicketMessage,
    closeTicket,
} from '../controllers/supportController.js';

const router = express.Router();

router.use(protect);

// Live Chat & AI Assistant flows (for both Customer and Worker)
router.get('/active-ticket', getActiveOrCreateTicket);
router.post('/message', sendUserMessage);
router.post('/escalate', escalateActiveTicket);
router.post('/reset', resetUserTicket);

// Traditional Ticket flows
router.post('/tickets', createTicket);
router.get('/tickets', listMyTickets);
router.get('/tickets/:id', getTicket);
router.post('/tickets/:id/messages', addTicketMessage);
router.patch('/tickets/:id/close', closeTicket);

export default router;
