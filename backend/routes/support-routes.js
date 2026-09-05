import express from 'express';
import { protect } from '../middleware/authMiddleware.js';
import {
    createTicket,
    listMyTickets,
    getTicket,
    addTicketMessage,
    closeTicket,
} from '../controllers/supportController.js';

const router = express.Router();
router.use(protect);
router.post('/tickets', createTicket);
router.get('/tickets', listMyTickets);
router.get('/tickets/:id', getTicket);
router.post('/tickets/:id/messages', addTicketMessage);
router.patch('/tickets/:id/close', closeTicket);
export default router;
