import SupportTicket from '../models/SupportTicket.js';
import { fail, ok, isObjectId } from '../utils/http.js';
import { notifyUser, safeNotify } from '../services/notificationService.js';

const CATEGORIES = new Set([
    'SERVICE_DISPUTE', 'WORKER_CUSTOMER_ISSUE', 'PAYMENT', 'SAFETY', 'BOOKING', 'ACCOUNT', 'OTHER',
]);

export const createTicket = async (req, res) => {
    try {
        const { subject, description, category, bookingId, attachments } = req.body || {};
        if (!subject || !description) {
            return fail(res, 400, 'VALIDATION_ERROR', 'subject and description required');
        }
        const cat = CATEGORIES.has(category) ? category : 'OTHER';
        const ticket = await SupportTicket.create({
            ticketNumber: `TKT-${Date.now().toString(36).toUpperCase()}`,
            createdBy: req.user.id,
            booking: bookingId && isObjectId(bookingId) ? bookingId : null,
            category: cat,
            subject,
            description,
            attachments: Array.isArray(attachments) ? attachments : [],
            messages: [{
                sender: req.user.id,
                role: req.user.role,
                body: description,
            }],
        });
        return ok(res, { data: ticket }, 201);
    } catch (error) {
        return fail(res, 500, 'INTERNAL_ERROR', error.message);
    }
};

export const listMyTickets = async (req, res) => {
    try {
        const tickets = await SupportTicket.find({ createdBy: req.user.id }).sort({ updatedAt: -1 });
        return ok(res, { data: tickets });
    } catch (error) {
        return fail(res, 500, 'INTERNAL_ERROR', error.message);
    }
};

export const getTicket = async (req, res) => {
    try {
        const ticket = await SupportTicket.findById(req.params.id)
            .populate('messages.sender', 'name role');
        if (!ticket) return fail(res, 404, 'NOT_FOUND', 'Ticket not found');
        const owner = String(ticket.createdBy) === String(req.user.id);
        if (!owner && req.user.role !== 'admin') {
            return fail(res, 403, 'FORBIDDEN', 'You do not have access to this resource');
        }
        return ok(res, { data: ticket });
    } catch (error) {
        return fail(res, 500, 'INTERNAL_ERROR', error.message);
    }
};

export const addTicketMessage = async (req, res) => {
    try {
        const { body } = req.body || {};
        if (!body) return fail(res, 400, 'VALIDATION_ERROR', 'body required');
        const ticket = await SupportTicket.findById(req.params.id);
        if (!ticket) return fail(res, 404, 'NOT_FOUND', 'Ticket not found');
        const owner = String(ticket.createdBy) === String(req.user.id);
        if (!owner && req.user.role !== 'admin') {
            return fail(res, 403, 'FORBIDDEN', 'You do not have access to this resource');
        }
        ticket.messages.push({ sender: req.user.id, role: req.user.role, body });
        ticket.lastMessageAt = new Date();
        if (req.user.role === 'admin') ticket.status = 'WAITING_FOR_USER';
        await ticket.save();
        if (req.user.role === 'admin') {
            safeNotify(() => notifyUser({
                recipient: ticket.createdBy,
                eventType: 'SUPPORT_REPLY',
                entityId: ticket._id,
                dedupeKey: `SUPPORT_REPLY:${ticket._id}:${ticket.messages.length}`,
            }));
        }
        return ok(res, { data: ticket });
    } catch (error) {
        return fail(res, 500, 'INTERNAL_ERROR', error.message);
    }
};

export const closeTicket = async (req, res) => {
    try {
        const ticket = await SupportTicket.findOne({ _id: req.params.id, createdBy: req.user.id });
        if (!ticket) return fail(res, 404, 'NOT_FOUND', 'Ticket not found');
        ticket.status = 'CLOSED';
        ticket.resolvedAt = new Date();
        await ticket.save();
        return ok(res, { data: ticket });
    } catch (error) {
        return fail(res, 500, 'INTERNAL_ERROR', error.message);
    }
};

export const adminListTickets = async (req, res) => {
    try {
        const tickets = await SupportTicket.find(req.query.status ? { status: req.query.status } : {})
            .populate('createdBy', 'name email role')
            .sort({ updatedAt: -1 });
        return ok(res, { data: tickets });
    } catch (error) {
        return fail(res, 500, 'INTERNAL_ERROR', error.message);
    }
};

export const adminPatchTicket = async (req, res) => {
    try {
        const { status, assignedTo, priority } = req.body || {};
        const ticket = await SupportTicket.findById(req.params.id);
        if (!ticket) return fail(res, 404, 'NOT_FOUND', 'Ticket not found');
        if (status) ticket.status = status;
        if (assignedTo) ticket.assignedTo = assignedTo;
        if (priority) ticket.priority = priority;
        if (status === 'RESOLVED' || status === 'CLOSED') ticket.resolvedAt = new Date();
        await ticket.save();
        if (status) {
            safeNotify(() => notifyUser({
                recipient: ticket.createdBy,
                eventType: 'SUPPORT_STATUS_UPDATED',
                entityId: ticket._id,
                dedupeKey: `SUPPORT_STATUS_UPDATED:${ticket._id}:${ticket.status}`,
            }));
        }
        return ok(res, { data: ticket });
    } catch (error) {
        return fail(res, 500, 'INTERNAL_ERROR', error.message);
    }
};
