import React from 'react';
import { topServicesData } from '../data/mockData';
import {
  Wrench,
  Zap,
  Sparkles,
  Hammer,
  FolderOpen,
  ArrowRight
} from 'lucide-react';

export default function TopServicesCard({ onSelectService }) {
  const getServiceIcon = (iconName, color) => {
    switch (iconName) {
      case 'wrench':
        return <Wrench size={16} color={color} strokeWidth={2.4} />;
      case 'zap':
        return <Zap size={16} color={color} strokeWidth={2.4} />;
      case 'sparkles':
        return <Sparkles size={16} color={color} strokeWidth={2.4} />;
      case 'hammer':
        return <Hammer size={16} color={color} strokeWidth={2.4} />;
      case 'grid':
      default:
        return <FolderOpen size={16} color={color} strokeWidth={2.4} />;
    }
  };

  return (
    <div
      style={{
        backgroundColor: 'var(--bg-card)',
        borderRadius: 'var(--radius-lg)',
        border: '1px solid var(--border-light)',
        padding: '22px 24px',
        boxShadow: 'var(--shadow-card)',
        display: 'flex',
        flexDirection: 'column',
        height: '100%',
        justifyContent: 'space-between',
      }}
    >
      {/* Header */}
      <div
        style={{
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          marginBottom: '16px',
        }}
      >
        <h2
          style={{
            fontSize: '16px',
            fontWeight: '700',
            color: '#12251a',
          }}
        >
          Top Services
        </h2>
        <span
          style={{
            fontSize: '11px',
            fontWeight: '600',
            color: '#15803d',
            backgroundColor: '#eaf7ee',
            padding: '3px 8px',
            borderRadius: '6px',
          }}
        >
          By Volume
        </span>
      </div>

      {/* Services List */}
      <div
        style={{
          display: 'flex',
          flexDirection: 'column',
          gap: '14px',
          justifyContent: 'space-around',
          flex: 1,
        }}
      >
        {topServicesData.map((service) => (
          <div
            key={service.id}
            onClick={() => onSelectService && onSelectService(service)}
            style={{
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'space-between',
              gap: '12px',
              padding: '4px 6px',
              borderRadius: '8px',
              cursor: 'pointer',
              transition: 'background 0.15s ease',
            }}
            onMouseEnter={(e) => (e.currentTarget.style.backgroundColor = '#f8faf9')}
            onMouseLeave={(e) => (e.currentTarget.style.backgroundColor = 'transparent')}
          >
            {/* Icon + Service Name */}
            <div
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: '10px',
                width: '105px',
                flexShrink: 0,
              }}
            >
              <div
                style={{
                  width: '28px',
                  height: '28px',
                  borderRadius: '7px',
                  backgroundColor: service.bg,
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  flexShrink: 0,
                }}
              >
                {getServiceIcon(service.icon, service.color)}
              </div>
              <span
                style={{
                  fontSize: '13px',
                  fontWeight: '600',
                  color: '#28392f',
                }}
              >
                {service.name}
              </span>
            </div>

            {/* Progress Bar Container */}
            <div
              style={{
                flex: 1,
                height: '7px',
                backgroundColor: '#e6ede8',
                borderRadius: '999px',
                overflow: 'hidden',
                position: 'relative',
              }}
            >
              <div
                style={{
                  width: `${service.percentage * 3.2}%`, // scaled relative visually as in screenshot
                  maxWidth: '100%',
                  height: '100%',
                  backgroundColor: '#22864c',
                  borderRadius: '999px',
                  transition: 'width 0.6s cubic-bezier(0.16, 1, 0.3, 1)',
                }}
              />
            </div>

            {/* Percentage Text */}
            <div
              style={{
                width: '38px',
                textAlign: 'right',
                fontSize: '12.5px',
                fontWeight: '600',
                color: '#495a50',
                flexShrink: 0,
              }}
            >
              {service.percentage}%
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
