import React from 'react';
import { topServicesData } from '../data/mockData';
import {
  Wrench,
  Zap,
  Sparkles,
  Hammer,
  FolderOpen,
  Plus,
  TrendingUp,
  Clock,
  Shield
} from 'lucide-react';

export default function ServicesView() {
  const getIcon = (iconName, color) => {
    switch (iconName) {
      case 'wrench':
        return <Wrench size={20} color={color} />;
      case 'zap':
        return <Zap size={20} color={color} />;
      case 'sparkles':
        return <Sparkles size={20} color={color} />;
      case 'hammer':
        return <Hammer size={20} color={color} />;
      default:
        return <FolderOpen size={20} color={color} />;
    }
  };

  return (
    <div style={{ padding: '0 32px 32px 32px', animation: 'fadeIn 0.2s ease' }}>
      <div
        style={{
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          marginBottom: '20px',
        }}
      >
        <div>
          <h2 style={{ fontSize: '20px', fontWeight: '700', color: '#111827' }}>
            Service Catalog & Rate Cards
          </h2>
          <p style={{ fontSize: '13px', color: '#64748b' }}>
            Standardized cooperative gig services, transparent pricing, and commission thresholds
          </p>
        </div>

        <button
          onClick={() => alert('Opening Add Service Dialog')}
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
          <Plus size={16} />
          <span>Add New Trade/Service</span>
        </button>
      </div>

      <div
        style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fill, minmax(320px, 1fr))',
          gap: '20px',
        }}
      >
        {topServicesData.map((s) => (
          <div
            key={s.id}
            style={{
              backgroundColor: '#ffffff',
              borderRadius: '16px',
              border: '1px solid var(--border-light)',
              padding: '22px',
              boxShadow: 'var(--shadow-card)',
            }}
          >
            <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
              <div
                style={{
                  width: '44px',
                  height: '44px',
                  borderRadius: '12px',
                  backgroundColor: s.bg,
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                }}
              >
                {getIcon(s.icon, s.color)}
              </div>
              <div>
                <h3 style={{ fontSize: '16px', fontWeight: '700', color: '#111827' }}>
                  {s.name}
                </h3>
                <div style={{ fontSize: '12px', color: '#64748b' }}>
                  {s.count} completed • ★ {s.avgRating}
                </div>
              </div>
            </div>

            <div
              style={{
                display: 'grid',
                gridTemplateColumns: '1fr 1fr',
                gap: '10px',
                marginTop: '18px',
                backgroundColor: '#f8faf9',
                padding: '12px',
                borderRadius: '10px',
                fontSize: '12px',
              }}
            >
              <div>
                <div style={{ color: '#64748b' }}>Cooperative Fee</div>
                <div style={{ fontWeight: '700', color: '#15803d' }}>5% (Welfare pool)</div>
              </div>
              <div>
                <div style={{ color: '#64748b' }}>Worker Payout</div>
                <div style={{ fontWeight: '700', color: '#0f172a' }}>95% Direct</div>
              </div>
            </div>

            <div style={{ marginTop: '16px', display: 'flex', gap: '8px' }}>
              <button
                style={{
                  flex: 1,
                  padding: '8px',
                  borderRadius: '8px',
                  backgroundColor: '#f1f5f9',
                  color: '#334155',
                  fontSize: '12px',
                  fontWeight: '600',
                }}
              >
                Edit Rate Card
              </button>
              <button
                style={{
                  padding: '8px 14px',
                  borderRadius: '8px',
                  backgroundColor: '#eaf7ee',
                  color: '#15803d',
                  fontSize: '12px',
                  fontWeight: '600',
                }}
              >
                Manage Workers
              </button>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
