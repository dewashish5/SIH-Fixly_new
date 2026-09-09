import React from 'react';

export default function Badge({ status }) {
  const getBadgeStyle = () => {
    switch (status) {
      case 'Confirmed':
      case 'Verified':
      case 'Active':
      case 'Approved':
      case 'Published':
      case 'Available':
        return {
          bg: '#eaf8ef',
          text: '#15803d',
          dot: '#22c55e',
        };
      case 'Pending':
      case 'Under Review':
      case 'Under Assessment':
      case 'Busy':
        return {
          bg: '#fef8e7',
          text: '#d97706',
          dot: '#f59e0b',
        };
      case 'In Progress':
      case 'Assigned':
      case 'On Duty':
        return {
          bg: '#eff6ff',
          text: '#2563eb',
          dot: '#3b82f6',
        };
      case 'Emergency':
        return {
          bg: '#fef2f2',
          text: '#dc2626',
          dot: '#ef4444',
          pulse: true,
        };
      case 'Completed':
      case 'Settled':
        return {
          bg: '#f0fdf4',
          text: '#166534',
          dot: '#16a34a',
        };
      case 'Cancelled':
      case 'Rejected':
      case 'Suspended':
      case 'Blocked':
      case 'Refunded':
        return {
          bg: '#fef2f2',
          text: '#b91c1c',
          dot: '#ef4444',
        };
      case 'VIP':
        return {
          bg: '#faf5ff',
          text: '#7e22ce',
          dot: '#a855f7',
        };
      case 'BOT_ACTIVE':
      case 'Bot Active':
      case 'AI Bot':
        return {
          bg: '#f3e8ff',
          text: '#6b21a8',
          dot: '#a855f7',
        };
      case 'ESCALATED':
      case 'Escalated':
      case 'Needs Attention':
        return {
          bg: '#fff7ed',
          text: '#c2410c',
          dot: '#f97316',
          pulse: true,
        };
      case 'AGENT_ACTIVE':
      case 'Agent Active':
      case 'In Chat':
        return {
          bg: '#ecfdf5',
          text: '#047857',
          dot: '#10b981',
        };
      case 'RESOLVED':
      case 'Resolved':
        return {
          bg: '#f1f5f9',
          text: '#334155',
          dot: '#64748b',
        };
      default:
        return {
          bg: '#f1f5f9',
          text: '#475569',
          dot: '#94a3b8',
        };
    }
  };

  const style = getBadgeStyle();

  return (
    <span
      style={{
        display: 'inline-flex',
        alignItems: 'center',
        gap: '5px',
        padding: '3.5px 10px',
        borderRadius: '999px',
        fontSize: '11.5px',
        fontWeight: '600',
        backgroundColor: style.bg,
        color: style.text,
        whiteSpace: 'nowrap',
      }}
    >
      <span
        style={{
          width: '6px',
          height: '6px',
          borderRadius: '50%',
          backgroundColor: style.dot,
          display: 'inline-block',
        }}
        className={style.pulse ? 'pulse-marker' : ''}
      />
      <span>{status}</span>
    </span>
  );
}
