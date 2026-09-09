import React, { useState, useEffect, useRef } from 'react';
import {
  MessageSquare,
  Bot,
  User,
  Headphones,
  Search,
  Send,
  CheckCircle2,
  AlertCircle,
  Clock,
  ArrowRight,
  RefreshCw,
  Phone,
  Mail,
  Shield,
  Briefcase,
  Sparkles,
  Zap,
  ChevronRight
} from 'lucide-react';
import { api } from '../../services/api';
import { useToast } from '../../context/ToastContext';
import Badge from '../../components/common/Badge';

const CANNED_RESPONSES = [
  "Hello! I am taking over this chat to assist you directly.",
  "We are checking your booking details right now.",
  "We have contacted your service technician for immediate update.",
  "Your refund for extra parts has been initiated and will credit in 24 hrs.",
  "Could you please share more details or a photo if applicable?",
  "Your ticket has been marked resolved. Feel free to reach out anytime!"
];

export default function SupportPage() {
  const { showToast } = useToast();

  const [tickets, setTickets] = useState([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [selectedTicketId, setSelectedTicketId] = useState(null);
  const [selectedTicket, setSelectedTicket] = useState(null);
  const [ticketDetailLoading, setTicketDetailLoading] = useState(false);

  // Filters & Search
  const [statusTab, setStatusTab] = useState('ALL'); // ALL, ESCALATED, AGENT_ACTIVE, BOT_ACTIVE, RESOLVED
  const [roleFilter, setRoleFilter] = useState('ALL'); // ALL, customer, worker
  const [searchQuery, setSearchQuery] = useState('');

  // Chat message input
  const [messageText, setMessageText] = useState('');
  const [sending, setSending] = useState(false);

  const messagesEndRef = useRef(null);

  // Fetch Tickets List
  const fetchTickets = async (silent = false) => {
    if (!silent) setLoading(true);
    try {
      const res = await api.getSupportTickets({
        status: statusTab !== 'ALL' ? statusTab : undefined,
        userRole: roleFilter !== 'ALL' ? roleFilter : undefined,
        search: searchQuery || undefined
      });
      if (res?.success && Array.isArray(res?.data)) {
        setTickets(res.data);
        // If nothing selected and tickets available, select first
        if (!selectedTicketId && res.data.length > 0) {
          setSelectedTicketId(res.data[0]._id);
        }
      }
    } catch (err) {
      if (!silent) {
        showToast(err.response?.data?.message || 'Failed to load support tickets', 'error');
      }
    } finally {
      if (!silent) setLoading(false);
      setRefreshing(false);
    }
  };

  // Fetch Selected Ticket Details
  const fetchTicketDetails = async (ticketId, silent = false) => {
    if (!ticketId) return;
    if (!silent) setTicketDetailLoading(true);
    try {
      const res = await api.getSupportTicketById(ticketId);
      if (res?.success && res?.data) {
        setSelectedTicket(res.data);
      }
    } catch (err) {
      if (!silent) {
        showToast('Failed to load conversation details', 'error');
      }
    } finally {
      if (!silent) setTicketDetailLoading(false);
    }
  };

  // Initial load and filter effect
  useEffect(() => {
    fetchTickets();
  }, [statusTab, roleFilter]);

  // Load ticket details on selection
  useEffect(() => {
    if (selectedTicketId) {
      fetchTicketDetails(selectedTicketId);
    }
  }, [selectedTicketId]);

  // Live polling for real-time updates every 4 seconds
  useEffect(() => {
    const interval = setInterval(() => {
      fetchTickets(true);
      if (selectedTicketId) {
        fetchTicketDetails(selectedTicketId, true);
      }
    }, 4000);
    return () => clearInterval(interval);
  }, [selectedTicketId, statusTab, roleFilter]);

  // Auto scroll to latest message
  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [selectedTicket?.messages]);

  // Handle Send Message
  const handleSendMessage = async (customText = null) => {
    const textToSend = (customText || messageText).trim();
    if (!textToSend || !selectedTicketId || sending) return;

    setSending(true);
    try {
      const res = await api.sendSupportMessage(selectedTicketId, textToSend);
      if (res?.success) {
        setMessageText('');
        fetchTicketDetails(selectedTicketId, true);
        fetchTickets(true);
        showToast('Reply sent successfully', 'success');
      }
    } catch (err) {
      showToast(err.response?.data?.message || 'Failed to send message', 'error');
    } finally {
      setSending(false);
    }
  };

  // Handle Take Over Chat
  const handleTakeover = async () => {
    if (!selectedTicketId) return;
    try {
      const res = await api.takeoverSupportTicket(selectedTicketId);
      if (res?.success) {
        showToast('You have taken over this support chat from AI!', 'success');
        fetchTicketDetails(selectedTicketId, true);
        fetchTickets(true);
      }
    } catch (err) {
      showToast(err.response?.data?.message || 'Failed to take over chat', 'error');
    }
  };

  // Handle Status Change
  const handleStatusChange = async (newStatus) => {
    if (!selectedTicketId) return;
    try {
      const res = await api.updateSupportTicketStatus(selectedTicketId, { status: newStatus });
      if (res?.success) {
        showToast(`Ticket status updated to ${newStatus}`, 'success');
        fetchTicketDetails(selectedTicketId, true);
        fetchTickets(true);
      }
    } catch (err) {
      showToast(err.response?.data?.message || 'Failed to update status', 'error');
    }
  };

  // Counts for tabs
  const escalatedCount = tickets.filter(t => t.status === 'ESCALATED').length;
  const agentActiveCount = tickets.filter(t => t.status === 'AGENT_ACTIVE').length;
  const botCount = tickets.filter(t => t.status === 'BOT_ACTIVE').length;

  return (
    <div className="h-[calc(100vh-80px)] flex flex-col p-4 md:p-6 gap-4 bg-slate-50 dark:bg-slate-950">
      {/* Top Bar / Header */}
      <div className="flex flex-wrap items-center justify-between gap-3 bg-white dark:bg-slate-900 p-4 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-xl bg-indigo-50 dark:bg-indigo-950/60 flex items-center justify-center text-indigo-600 dark:text-indigo-400">
            <Headphones className="w-5 h-5" />
          </div>
          <div>
            <h1 className="text-xl font-bold text-slate-900 dark:text-white flex items-center gap-2">
              Support Desk & AI Chatbot
              {escalatedCount > 0 && (
                <span className="px-2 py-0.5 text-xs font-semibold bg-amber-500 text-white rounded-full animate-pulse">
                  {escalatedCount} Escalated
                </span>
              )}
            </h1>
            <p className="text-xs text-slate-500 dark:text-slate-400">
              Real-time customer & worker queries handled by AI with seamless human takeover
            </p>
          </div>
        </div>

        {/* Quick Filter Buttons */}
        <div className="flex items-center gap-2">
          <button
            onClick={() => { setRefreshing(true); fetchTickets(); }}
            className="flex items-center gap-1.5 px-3 py-2 text-xs font-medium text-slate-600 dark:text-slate-300 bg-slate-100 dark:bg-slate-800 hover:bg-slate-200 dark:hover:bg-slate-700 rounded-lg transition"
            title="Refresh list"
          >
            <RefreshCw className={`w-3.5 h-3.5 ${refreshing ? 'animate-spin' : ''}`} />
            Refresh
          </button>
        </div>
      </div>

      {/* Main Split Layout */}
      <div className="flex-1 grid grid-cols-1 lg:grid-cols-12 gap-4 min-h-0">
        {/* LEFT COLUMN: Ticket List (5 Cols on large screens) */}
        <div className="lg:col-span-4 xl:col-span-4 flex flex-col bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm overflow-hidden">
          {/* Search and Tabs */}
          <div className="p-3 border-b border-slate-200 dark:border-slate-800 space-y-2.5">
            {/* Search */}
            <div className="relative">
              <Search className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
              <input
                type="text"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                onKeyDown={(e) => e.key === 'Enter' && fetchTickets()}
                placeholder="Search ticket #, name, query..."
                className="w-full pl-9 pr-3 py-2 text-xs bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-lg focus:outline-none focus:border-indigo-500 dark:text-white"
              />
            </div>

            {/* Status Filter Chips */}
            <div className="flex items-center gap-1 overflow-x-auto pb-1 text-xs no-scrollbar">
              {[
                { key: 'ALL', label: 'All' },
                { key: 'ESCALATED', label: '⚠️ Escalated', count: escalatedCount },
                { key: 'AGENT_ACTIVE', label: '💬 In Chat', count: agentActiveCount },
                { key: 'BOT_ACTIVE', label: '🤖 AI Bot', count: botCount },
                { key: 'RESOLVED', label: '✅ Resolved' },
              ].map((tab) => (
                <button
                  key={tab.key}
                  onClick={() => setStatusTab(tab.key)}
                  className={`px-2.5 py-1.5 rounded-lg whitespace-nowrap font-medium transition flex items-center gap-1 ${
                    statusTab === tab.key
                      ? 'bg-indigo-600 text-white shadow-sm'
                      : 'bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-400 hover:bg-slate-200'
                  }`}
                >
                  <span>{tab.label}</span>
                  {tab.count !== undefined && tab.count > 0 && (
                    <span className={`text-[10px] px-1.5 py-0.2 rounded-full font-bold ${
                      statusTab === tab.key ? 'bg-white text-indigo-700' : 'bg-slate-300 dark:bg-slate-700 text-slate-800 dark:text-slate-200'
                    }`}>
                      {tab.count}
                    </span>
                  )}
                </button>
              ))}
            </div>

            {/* Role Filter Chips */}
            <div className="flex items-center gap-2 pt-1 border-t border-slate-100 dark:border-slate-800 text-xs">
              <span className="text-slate-400 font-medium">Role:</span>
              {['ALL', 'customer', 'worker'].map((role) => (
                <button
                  key={role}
                  onClick={() => setRoleFilter(role)}
                  className={`px-2 py-0.5 rounded text-[11px] font-medium uppercase transition ${
                    roleFilter === role
                      ? 'bg-slate-800 text-white dark:bg-slate-200 dark:text-slate-900'
                      : 'text-slate-500 hover:text-slate-800 dark:hover:text-slate-200'
                  }`}
                >
                  {role === 'ALL' ? 'All Roles' : role}
                </button>
              ))}
            </div>
          </div>

          {/* Ticket List Scrollable */}
          <div className="flex-1 overflow-y-auto divide-y divide-slate-100 dark:divide-slate-800">
            {loading ? (
              <div className="p-8 text-center text-slate-400 text-xs flex flex-col items-center gap-2">
                <RefreshCw className="w-5 h-5 animate-spin text-indigo-500" />
                Loading conversations...
              </div>
            ) : tickets.length === 0 ? (
              <div className="p-8 text-center text-slate-400 text-xs">
                No tickets matching criteria.
              </div>
            ) : (
              tickets.map((t) => {
                const isSelected = t._id === selectedTicketId;
                const isEscalated = t.status === 'ESCALATED';
                const lastMsg = t.messages?.[t.messages.length - 1];
                const senderRole = t.createdBy?.role || t.userRole || 'customer';

                return (
                  <div
                    key={t._id}
                    onClick={() => setSelectedTicketId(t._id)}
                    className={`p-3 cursor-pointer transition flex flex-col gap-1.5 ${
                      isSelected
                        ? 'bg-indigo-50/70 dark:bg-indigo-950/30 border-l-4 border-indigo-600'
                        : 'hover:bg-slate-50 dark:hover:bg-slate-800/50'
                    }`}
                  >
                    <div className="flex items-center justify-between gap-2">
                      <div className="flex items-center gap-2 min-w-0">
                        <div className={`w-7 h-7 rounded-full flex items-center justify-center text-xs font-bold ${
                          senderRole === 'worker'
                            ? 'bg-amber-100 text-amber-800 dark:bg-amber-950 dark:text-amber-300'
                            : 'bg-blue-100 text-blue-800 dark:bg-blue-950 dark:text-blue-300'
                        }`}>
                          {senderRole === 'worker' ? 'W' : 'C'}
                        </div>
                        <span className="font-semibold text-xs text-slate-900 dark:text-white truncate">
                          {t.createdBy?.name || 'User'}
                        </span>
                        <span className={`text-[10px] px-1.5 py-0.2 rounded font-medium ${
                          senderRole === 'worker'
                            ? 'bg-amber-100 text-amber-700 dark:bg-amber-900/40 dark:text-amber-400'
                            : 'bg-blue-100 text-blue-700 dark:bg-blue-900/40 dark:text-blue-400'
                        }`}>
                          {senderRole}
                        </span>
                      </div>

                      <Badge status={t.status} />
                    </div>

                    {/* Preview of last message */}
                    <p className="text-[11.5px] text-slate-600 dark:text-slate-400 line-clamp-2">
                      {lastMsg?.body || t.description || 'No messages yet'}
                    </p>

                    <div className="flex items-center justify-between text-[10px] text-slate-400 pt-0.5">
                      <span>{t.ticketNumber}</span>
                      <span className="flex items-center gap-1">
                        {t.handledBy === 'BOT' ? (
                          <span className="flex items-center gap-1 text-purple-600 dark:text-purple-400">
                            <Bot className="w-3 h-3" /> Bot
                          </span>
                        ) : (
                          <span className="flex items-center gap-1 text-emerald-600 dark:text-emerald-400">
                            <Headphones className="w-3 h-3" /> Agent
                          </span>
                        )}
                        <span>•</span>
                        {new Date(t.lastMessageAt || t.updatedAt).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                      </span>
                    </div>
                  </div>
                );
              })
            )}
          </div>
        </div>

        {/* RIGHT COLUMN: Interactive Conversation View (8 Cols on large screens) */}
        <div className="lg:col-span-8 xl:col-span-8 flex flex-col bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm overflow-hidden">
          {!selectedTicket ? (
            <div className="flex-1 flex flex-col items-center justify-center p-8 text-center text-slate-400">
              <MessageSquare className="w-12 h-12 mb-3 text-slate-300 dark:text-slate-700" />
              <h3 className="text-base font-semibold text-slate-700 dark:text-slate-300">
                Select a conversation
              </h3>
              <p className="text-xs text-slate-500 max-w-sm mt-1">
                Choose any active ticket from the left column to view the chat history, take over from AI, or reply directly.
              </p>
            </div>
          ) : (
            <>
              {/* Ticket Top Control Bar */}
              <div className="p-3.5 border-b border-slate-200 dark:border-slate-800 bg-slate-50/50 dark:bg-slate-900/50 flex flex-wrap items-center justify-between gap-3">
                <div className="flex items-center gap-3">
                  <div className="w-9 h-9 rounded-full bg-indigo-100 dark:bg-indigo-950 text-indigo-700 dark:text-indigo-300 flex items-center justify-center font-bold text-sm">
                    {selectedTicket.createdBy?.name?.[0] || 'U'}
                  </div>
                  <div>
                    <div className="flex items-center gap-2">
                      <h2 className="text-sm font-bold text-slate-900 dark:text-white">
                        {selectedTicket.createdBy?.name || 'User'}
                      </h2>
                      <span className="text-xs text-slate-400 font-mono">
                        {selectedTicket.ticketNumber}
                      </span>
                      <Badge status={selectedTicket.status} />
                    </div>
                    <div className="flex items-center gap-3 text-xs text-slate-500 mt-0.5">
                      {selectedTicket.createdBy?.phone && (
                        <span className="flex items-center gap-1">
                          <Phone className="w-3 h-3 text-slate-400" />
                          {selectedTicket.createdBy.phone}
                        </span>
                      )}
                      {selectedTicket.createdBy?.email && (
                        <span className="flex items-center gap-1">
                          <Mail className="w-3 h-3 text-slate-400" />
                          {selectedTicket.createdBy.email}
                        </span>
                      )}
                    </div>
                  </div>
                </div>

                {/* Actions & Takeover */}
                <div className="flex items-center gap-2">
                  {/* Takeover Button if currently bot or escalated */}
                  {(selectedTicket.handledBy === 'BOT' || selectedTicket.status === 'ESCALATED') && (
                    <button
                      onClick={handleTakeover}
                      className="flex items-center gap-1.5 px-3 py-1.5 text-xs font-semibold bg-emerald-600 hover:bg-emerald-700 text-white rounded-lg shadow-sm transition"
                    >
                      <Headphones className="w-3.5 h-3.5" />
                      Take Over Chat
                    </button>
                  )}

                  {/* Status Dropdown */}
                  <select
                    value={selectedTicket.status}
                    onChange={(e) => handleStatusChange(e.target.value)}
                    className="text-xs bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-lg px-2.5 py-1.5 text-slate-700 dark:text-slate-200 focus:outline-none focus:border-indigo-500"
                  >
                    <option value="BOT_ACTIVE">🤖 AI Bot Active</option>
                    <option value="ESCALATED">⚠️ Escalated</option>
                    <option value="AGENT_ACTIVE">💬 Agent Active</option>
                    <option value="WAITING_FOR_USER">⏳ Waiting for User</option>
                    <option value="RESOLVED">✅ Resolved</option>
                    <option value="CLOSED">🔒 Closed</option>
                  </select>
                </div>
              </div>

              {/* Bot / Escalation Info Banner */}
              {selectedTicket.status === 'ESCALATED' && (
                <div className="px-4 py-2 bg-amber-50 dark:bg-amber-950/40 border-b border-amber-200 dark:border-amber-900 text-amber-800 dark:text-amber-300 text-xs flex items-center justify-between">
                  <div className="flex items-center gap-2 font-medium">
                    <AlertCircle className="w-4 h-4 text-amber-600" />
                    <span>User requested human support or AI could not resolve the issue. Click &quot;Take Over Chat&quot; to assist.</span>
                  </div>
                  <button
                    onClick={handleTakeover}
                    className="px-2.5 py-1 text-[11px] font-semibold bg-amber-600 text-white rounded hover:bg-amber-700 transition"
                  >
                    Take Over
                  </button>
                </div>
              )}

              {/* Chat Message Stream */}
              <div className="flex-1 overflow-y-auto p-4 space-y-3 bg-slate-50/40 dark:bg-slate-950/30">
                {ticketDetailLoading ? (
                  <div className="p-8 text-center text-slate-400 text-xs flex flex-col items-center gap-2">
                    <RefreshCw className="w-5 h-5 animate-spin text-indigo-500" />
                    Loading conversation...
                  </div>
                ) : (
                  selectedTicket.messages?.map((msg, index) => {
                    const isUser = msg.role === 'customer' || msg.role === 'worker';
                    const isAi = msg.role === 'ai';
                    const isAdmin = msg.role === 'admin';
                    const isSystem = msg.role === 'system';

                    if (isSystem) {
                      return (
                        <div key={index} className="flex justify-center my-2">
                          <span className="text-[11px] bg-slate-200 dark:bg-slate-800 text-slate-600 dark:text-slate-400 px-3 py-1 rounded-full font-medium shadow-sm">
                            {msg.body}
                          </span>
                        </div>
                      );
                    }

                    return (
                      <div
                        key={index}
                        className={`flex flex-col ${isAdmin ? 'items-end' : 'items-start'}`}
                      >
                        {/* Sender Label */}
                        <div className="flex items-center gap-1 text-[10px] text-slate-400 mb-1 px-1">
                          {isAi && (
                            <span className="flex items-center gap-1 text-purple-600 dark:text-purple-400 font-semibold">
                              <Sparkles className="w-3 h-3" /> Fixly AI
                            </span>
                          )}
                          {isAdmin && (
                            <span className="flex items-center gap-1 text-indigo-600 dark:text-indigo-400 font-semibold">
                              <Headphones className="w-3 h-3" /> You (Support Desk)
                            </span>
                          )}
                          {isUser && (
                            <span className="font-medium text-slate-600 dark:text-slate-400">
                              {msg.senderName || selectedTicket.createdBy?.name || 'User'} ({msg.role})
                            </span>
                          )}
                          <span>•</span>
                          <span>
                            {new Date(msg.createdAt || Date.now()).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                          </span>
                        </div>

                        {/* Message Bubble */}
                        <div
                          className={`max-w-[80%] md:max-w-[70%] p-3 rounded-2xl text-xs leading-relaxed shadow-sm ${
                            isAdmin
                              ? 'bg-indigo-600 text-white rounded-br-none'
                              : isAi
                              ? 'bg-purple-50 dark:bg-purple-950/40 text-slate-800 dark:text-slate-200 border border-purple-200 dark:border-purple-800 rounded-bl-none'
                              : 'bg-white dark:bg-slate-800 text-slate-900 dark:text-white border border-slate-200 dark:border-slate-700 rounded-bl-none'
                          }`}
                        >
                          <p className="whitespace-pre-wrap">{msg.body}</p>

                          {/* Quick replies preview if AI provided them */}
                          {msg.quickReplies && msg.quickReplies.length > 0 && (
                            <div className="mt-2 pt-2 border-t border-purple-200 dark:border-purple-800/60 flex flex-wrap gap-1">
                              <span className="text-[10px] text-purple-600 dark:text-purple-400 font-medium block w-full">
                                AI Suggested options given to user:
                              </span>
                              {msg.quickReplies.map((qr, i) => (
                                <span
                                  key={i}
                                  className="text-[10px] px-2 py-0.5 rounded-full bg-white dark:bg-slate-900 text-purple-700 dark:text-purple-300 border border-purple-200 dark:border-purple-800"
                                >
                                  {qr}
                                </span>
                              ))}
                            </div>
                          )}
                        </div>
                      </div>
                    );
                  })
                )}
                <div ref={messagesEndRef} />
              </div>

              {/* Admin Canned Quick Response Chips */}
              <div className="p-2 border-t border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900">
                <div className="flex items-center gap-1.5 overflow-x-auto pb-1 text-[11px] no-scrollbar">
                  <span className="text-slate-400 font-medium text-[10px] whitespace-nowrap pl-1">
                    Canned Replies:
                  </span>
                  {CANNED_RESPONSES.map((snip, idx) => (
                    <button
                      key={idx}
                      onClick={() => handleSendMessage(snip)}
                      className="px-2.5 py-1 rounded-full bg-slate-100 hover:bg-slate-200 dark:bg-slate-800 dark:hover:bg-slate-700 text-slate-700 dark:text-slate-300 whitespace-nowrap border border-slate-200 dark:border-slate-700 transition flex items-center gap-1"
                    >
                      <Zap className="w-2.5 h-2.5 text-amber-500" />
                      <span>{snip.length > 35 ? snip.slice(0, 35) + '...' : snip}</span>
                    </button>
                  ))}
                </div>
              </div>

              {/* Message Input Box */}
              <div className="p-3 border-t border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900">
                {selectedTicket.handledBy === 'BOT' && selectedTicket.status !== 'ESCALATED' && (
                  <div className="text-[11px] text-purple-700 dark:text-purple-300 bg-purple-50 dark:bg-purple-950/30 p-2 rounded-lg mb-2 flex items-center justify-between">
                    <span className="flex items-center gap-1.5">
                      <Bot className="w-3.5 h-3.5" />
                      AI Assistant is currently active. Sending a reply will automatically assign the chat to you.
                    </span>
                  </div>
                )}

                <div className="flex items-center gap-2">
                  <input
                    type="text"
                    value={messageText}
                    onChange={(e) => setMessageText(e.target.value)}
                    onKeyDown={(e) => {
                      if (e.key === 'Enter' && !e.shiftKey) {
                        e.preventDefault();
                        handleSendMessage();
                      }
                    }}
                    placeholder="Type your support reply (Enter to send)..."
                    disabled={sending || selectedTicket.status === 'CLOSED'}
                    className="flex-1 px-3.5 py-2.5 text-xs bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl focus:outline-none focus:border-indigo-500 dark:text-white disabled:opacity-50"
                  />
                  <button
                    onClick={() => handleSendMessage()}
                    disabled={sending || !messageText.trim() || selectedTicket.status === 'CLOSED'}
                    className="px-4 py-2.5 bg-indigo-600 hover:bg-indigo-700 disabled:opacity-50 text-white rounded-xl font-medium text-xs flex items-center gap-1.5 shadow-sm transition"
                  >
                    <Send className="w-3.5 h-3.5" />
                    <span>Send</span>
                  </button>
                </div>
              </div>
            </>
          )}
        </div>
      </div>
    </div>
  );
}
