import React, { useState } from 'react';
import { useApp } from '../../context/AppContext';
import {
  Bell,
  Plus,
  Trash2,
  CheckCircle,
  AlertTriangle,
  CreditCard,
  CalendarCheck,
  Radio,
  Send
} from 'lucide-react';
import SendNotificationModal from '../../components/modals/SendNotificationModal';

export default function NotificationsPage() {
  const {
    notifications,
    markAllNotificationsRead,
    deleteNotification,
  } = useApp();

  const [filter, setFilter] = useState('All');
  const [isSendModalOpen, setIsSendModalOpen] = useState(false);

  const filtered = notifications.filter((n) => {
    if (filter === 'All') return true;
    if (filter === 'Unread') return n.unread;
    return n.category === filter;
  });

  return (
    <div style={{ padding: '0 32px 32px 32px', animation: 'fadeIn 0.2s ease', maxWidth: '950px' }}>
      {/* Header */}
      <div
        style={{
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          marginBottom: '20px',
          flexWrap: 'wrap',
          gap: '12px',
        }}
      >
        <div>
          <h2 style={{ fontSize: '20px', fontWeight: '700', color: '#111827' }}>
            System Notifications & Broadcast Dispatcher
          </h2>
          <p style={{ fontSize: '13px', color: '#64748b' }}>
            Real-time push notifications, surge announcements, emergency SOS flashes, and payout alerts
          </p>
        </div>

        <div style={{ display: 'flex', gap: '10px' }}>
          <button
            onClick={markAllNotificationsRead}
            style={{
              padding: '8px 14px',
              borderRadius: '8px',
              backgroundColor: '#ffffff',
              border: '1px solid var(--border-light)',
              color: '#334155',
              fontSize: '13px',
              fontWeight: '600',
            }}
          >
            Mark All Read
          </button>

          <button
            onClick={() => setIsSendModalOpen(true)}
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '6px',
              padding: '9px 16px',
              backgroundColor: 'var(--primary-brand)',
              color: '#ffffff',
              borderRadius: '8px',
              fontSize: '13px',
              fontWeight: '600',
              boxShadow: 'var(--shadow-pill)',
            }}
          >
            <Send size={15} />
            <span>Broadcast Notification</span>
          </button>
        </div>
      </div>

      {/* Category Filter Pills */}
      <div style={{ display: 'flex', gap: '8px', marginBottom: '18px', flexWrap: 'wrap' }}>
        {['All', 'Unread', 'Emergency', 'Payments', 'System'].map((cat) => (
          <button
            key={cat}
            onClick={() => setFilter(cat)}
            style={{
              padding: '6px 14px',
              borderRadius: '8px',
              fontSize: '12.5px',
              fontWeight: '600',
              backgroundColor: filter === cat ? '#eaf7ee' : '#ffffff',
              color: filter === cat ? '#15803d' : '#64748b',
              border: `1px solid ${filter === cat ? '#86efac' : 'var(--border-light)'}`,
            }}
          >
            {cat}
          </button>
        ))}
      </div>

      {/* Notifications List */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
        {filtered.map((n) => (
          <div
            key={n.id}
            style={{
              backgroundColor: n.unread ? '#f6fbf8' : '#ffffff',
              borderRadius: '14px',
              border: `1.5px solid ${n.unread ? '#bbf7d0' : 'var(--border-light)'}`,
              padding: '18px 20px',
              boxShadow: 'var(--shadow-card)',
              display: 'flex',
              alignItems: 'flex-start',
              justifyContent: 'space-between',
              gap: '16px',
            }}
          >
            <div style={{ display: 'flex', gap: '14px' }}>
              <div
                style={{
                  width: '38px',
                  height: '38px',
                  borderRadius: '10px',
                  backgroundColor:
                    n.category === 'Emergency' ? '#fee2e2' : n.category === 'Payments' ? '#eaf8ef' : '#eff6ff',
                  color: n.category === 'Emergency' ? '#dc2626' : n.category === 'Payments' ? '#15803d' : '#2563eb',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  flexShrink: 0,
                }}
              >
                {n.category === 'Emergency' && <AlertTriangle size={20} />}
                {n.category === 'Payments' && <CreditCard size={20} />}
                {n.category === 'System' && <Bell size={20} />}
              </div>

              <div>
                <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                  <h4 style={{ fontSize: '14.5px', fontWeight: '700', color: '#111827' }}>
                    {n.title}
                  </h4>
                  {n.unread && (
                    <span style={{ fontSize: '10.5px', backgroundColor: '#15803d', color: '#ffffff', padding: '1px 6px', borderRadius: '4px', fontWeight: '700' }}>
                      NEW
                    </span>
                  )}
                </div>

                <p style={{ fontSize: '13px', color: '#475569', marginTop: '4px', lineHeight: '1.4' }}>
                  {n.message}
                </p>

                <div style={{ display: 'flex', gap: '14px', marginTop: '8px', fontSize: '11.5px', color: '#64748b' }}>
                  <span>Audience: <strong>{n.targetAudience || 'All Users'}</strong></span>
                  <span>•</span>
                  <span>Priority: <strong>{n.priority || 'Normal'}</strong></span>
                  <span>•</span>
                  <span>{n.time} ({n.date})</span>
                </div>
              </div>
            </div>

            <button
              onClick={() => deleteNotification(n.id)}
              style={{
                padding: '6px',
                borderRadius: '6px',
                color: '#94a3b8',
              }}
              title="Delete Notification"
            >
              <Trash2 size={16} />
            </button>
          </div>
        ))}
      </div>

      <SendNotificationModal isOpen={isSendModalOpen} onClose={() => setIsSendModalOpen(false)} />
    </div>
  );
}
