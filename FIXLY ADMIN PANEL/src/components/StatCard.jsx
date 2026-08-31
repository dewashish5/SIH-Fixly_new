import React from 'react';
import {
  User,
  Users,
  IndianRupee,
  IdCard,
  ArrowUpRight,
  TrendingUp
} from 'lucide-react';

export default function StatCard({ item }) {
  const getIcon = (type) => {
    switch (type) {
      case 'user':
        return <User size={22} color="#1e7e45" strokeWidth={2.2} />;
      case 'rupee':
        return <IndianRupee size={22} color="#1e7e45" strokeWidth={2.4} />;
      case 'worker':
        return <IdCard size={22} color="#1e7e45" strokeWidth={2.2} />;
      case 'customers':
        return <Users size={22} color="#1e7e45" strokeWidth={2.2} />;
      default:
        return <TrendingUp size={22} color="#1e7e45" />;
    }
  };

  return (
    <div
      style={{
        backgroundColor: 'var(--bg-card)',
        borderRadius: 'var(--radius-lg)',
        border: '1px solid var(--border-light)',
        padding: '20px 22px',
        boxShadow: 'var(--shadow-card)',
        display: 'flex',
        flexDirection: 'column',
        justifyContent: 'space-between',
        minHeight: '120px',
        transition: 'transform 0.2s ease, box-shadow 0.2s ease, border-color 0.2s ease',
        cursor: 'default',
      }}
      onMouseEnter={(e) => {
        e.currentTarget.style.transform = 'translateY(-3px)';
        e.currentTarget.style.boxShadow = 'var(--shadow-hover)';
        e.currentTarget.style.borderColor = '#bbf7d0';
      }}
      onMouseLeave={(e) => {
        e.currentTarget.style.transform = 'translateY(0)';
        e.currentTarget.style.boxShadow = 'var(--shadow-card)';
        e.currentTarget.style.borderColor = 'var(--border-light)';
      }}
    >
      {/* Top row: Icon + Number & Label */}
      <div style={{ display: 'flex', alignItems: 'center', gap: '14px' }}>
        <div
          style={{
            width: '46px',
            height: '46px',
            borderRadius: '12px',
            backgroundColor: '#eaf7ee',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            flexShrink: 0,
            boxShadow: 'inset 0 1px 2px rgba(30, 126, 69, 0.1)',
          }}
        >
          {getIcon(item.iconType)}
        </div>

        <div>
          <div
            style={{
              fontSize: '22px',
              fontWeight: '800',
              color: '#111827',
              lineHeight: '1.15',
              letterSpacing: '-0.4px',
            }}
          >
            {item.value}
          </div>
          <div
            style={{
              fontSize: '12.5px',
              color: 'var(--text-secondary)',
              fontWeight: '500',
              marginTop: '3px',
            }}
          >
            {item.title}
          </div>
        </div>
      </div>

      {/* Bottom row: Trend badge */}
      <div
        style={{
          display: 'flex',
          alignItems: 'center',
          gap: '4px',
          marginTop: '14px',
          paddingLeft: '60px', // align neatly under text
        }}
      >
        <span
          style={{
            display: 'inline-flex',
            alignItems: 'center',
            gap: '2px',
            fontSize: '12px',
            fontWeight: '700',
            color: '#15803d',
          }}
        >
          <ArrowUpRight size={14} strokeWidth={2.8} />
          {item.trend}
        </span>
      </div>
    </div>
  );
}
