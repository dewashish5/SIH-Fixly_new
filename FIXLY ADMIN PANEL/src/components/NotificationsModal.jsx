import React from 'react';
import {
  X,
  Bell,
  AlertTriangle,
  CheckCircle2,
  DollarSign,
  ShieldCheck,
  Clock
} from 'lucide-react';

export default function NotificationsModal({ isOpen, onClose }) {
  if (!isOpen) return null;

  const notifications = [
    {
      id: 1,
      title: 'High Demand in Noida Sector 62',
      desc: 'Plumbing and Electrical request volume surged +40% in the last 2 hours.',
      time: '10 mins ago',
      type: 'alert',
      unread: true,
    },
    {
      id: 2,
      title: '₹14,80,000 Daily Welfare Payout Processed',
      desc: 'Weekly cooperative revenue share distributed to 1,240 verified worker accounts.',
      time: '45 mins ago',
      type: 'success',
      unread: true,
    },
    {
      id: 3,
      title: 'Worker Insurance Claim Approved (#INS-889)',
      desc: 'Accidental emergency coverage of ₹25,000 disbursed to Suresh Das (Carpentry).',
      time: '2 hours ago',
      type: 'shield',
      unread: true,
    },
    {
      id: 4,
      title: 'New Service Provider Verification Pending',
      desc: '18 new electrical technicians submitted their background verification documents.',
      time: '4 hours ago',
      type: 'info',
      unread: false,
    },
  ];

  return (
    <div
      style={{
        position: 'fixed',
        inset: 0,
        backgroundColor: 'rgba(15, 23, 42, 0.5)',
        backdropFilter: 'blur(3px)',
        zIndex: 70,
        display: 'flex',
        justifyContent: 'flex-end',
        animation: 'fadeIn 0.2s ease',
      }}
      onClick={onClose}
    >
      <div
        style={{
          width: '100%',
          maxWidth: '420px',
          height: '100%',
          backgroundColor: '#ffffff',
          boxShadow: '-10px 0 25px rgba(0,0,0,0.15)',
          display: 'flex',
          flexDirection: 'column',
        }}
        onClick={(e) => e.stopPropagation()}
      >
        {/* Header */}
        <div
          style={{
            padding: '20px 24px',
            borderBottom: '1px solid var(--border-light)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
          }}
        >
          <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
            <Bell size={18} color="var(--primary-brand)" />
            <h3 style={{ fontSize: '16px', fontWeight: '700', color: '#111827' }}>
              Platform Notifications
            </h3>
          </div>
          <button
            onClick={onClose}
            style={{
              padding: '6px',
              borderRadius: '50%',
              backgroundColor: '#f1f5f9',
              color: '#64748b',
            }}
          >
            <X size={16} />
          </button>
        </div>

        {/* List */}
        <div style={{ flex: 1, overflowY: 'auto', padding: '16px', display: 'flex', flexDirection: 'column', gap: '10px' }}>
          {notifications.map((n) => (
            <div
              key={n.id}
              style={{
                padding: '14px',
                borderRadius: '12px',
                backgroundColor: n.unread ? '#f6fbf8' : '#f8fafc',
                border: `1px solid ${n.unread ? '#bbf7d0' : '#e2e8f0'}`,
                display: 'flex',
                gap: '12px',
                transition: 'all 0.15s ease',
              }}
            >
              <div
                style={{
                  width: '32px',
                  height: '32px',
                  borderRadius: '8px',
                  backgroundColor:
                    n.type === 'alert' ? '#fef2f2' : n.type === 'success' ? '#eaf8ef' : '#eff6ff',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  flexShrink: 0,
                }}
              >
                {n.type === 'alert' && <AlertTriangle size={16} color="#dc2626" />}
                {n.type === 'success' && <DollarSign size={16} color="#15803d" />}
                {n.type === 'shield' && <ShieldCheck size={16} color="#2563eb" />}
                {n.type === 'info' && <Clock size={16} color="#0284c7" />}
              </div>

              <div>
                <div style={{ fontSize: '13px', fontWeight: '700', color: '#1e293b' }}>
                  {n.title}
                </div>
                <div style={{ fontSize: '12px', color: '#64748b', marginTop: '2px', lineHeight: '1.35' }}>
                  {n.desc}
                </div>
                <div style={{ fontSize: '11px', color: '#94a3b8', marginTop: '6px' }}>
                  {n.time}
                </div>
              </div>
            </div>
          ))}
        </div>

        {/* Footer */}
        <div
          style={{
            padding: '14px 20px',
            borderTop: '1px solid var(--border-light)',
            textAlign: 'center',
          }}
        >
          <button
            onClick={() => {
              alert('All notifications marked as read');
              onClose();
            }}
            style={{
              fontSize: '12.5px',
              fontWeight: '600',
              color: 'var(--primary-brand)',
            }}
          >
            Mark all as read
          </button>
        </div>
      </div>
    </div>
  );
}
