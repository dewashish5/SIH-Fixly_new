import React from 'react';
import { useApp } from '../context/AppContext';
import {
  Wrench,
  Zap,
  Sparkles,
  Hammer,
  FolderOpen
} from 'lucide-react';

export default function TopServicesCard({ onSelectService }) {
  const { services, topServices: apiTopServices } = useApp();

  const getCategoryMeta = (catName) => {
    const name = (catName || '').toLowerCase();
    if (name.includes('plumb')) return { name: 'Plumbing', icon: 'wrench', color: '#2563eb', bg: '#eff6ff' };
    if (name.includes('electr')) return { name: 'Electrical', icon: 'zap', color: '#d97706', bg: '#fef3c7' };
    if (name.includes('clean')) return { name: 'Cleaning', icon: 'sparkles', color: '#16a34a', bg: '#f0fdf4' };
    if (name.includes('carpent')) return { name: 'Carpentry', icon: 'hammer', color: '#ea580c', bg: '#fff7ed' };
    return { name: catName || 'Others', icon: 'folder', color: '#0d9488', bg: '#f0fdf4' };
  };

  const renderCategoryIcon = (iconName, color) => {
    switch (iconName) {
      case 'wrench':
        return <Wrench size={16} color={color} strokeWidth={2.2} />;
      case 'zap':
        return <Zap size={16} color={color} strokeWidth={2.2} />;
      case 'sparkles':
        return <Sparkles size={16} color={color} strokeWidth={2.2} />;
      case 'hammer':
        return <Hammer size={16} color={color} strokeWidth={2.2} />;
      case 'folder':
      default:
        return <FolderOpen size={16} color={color} strokeWidth={2.2} />;
    }
  };

  // Build dynamic list from DB services grouped by Category
  const buildDynamicCategories = () => {
    if (!services || services.length === 0) return [];

    const categoryCounts = {};
    services.forEach((s) => {
      const cat = s.category || 'Others';
      categoryCounts[cat] = (categoryCounts[cat] || 0) + 1;
    });

    const total = services.length;
    const items = Object.keys(categoryCounts).map((cat) => {
      const meta = getCategoryMeta(cat);
      const pct = Math.round((categoryCounts[cat] / total) * 100);
      return {
        id: cat,
        name: meta.name,
        percentage: pct,
        color: meta.color,
        bg: meta.bg,
        icon: meta.icon
      };
    });

    return items.sort((a, b) => b.percentage - a.percentage).slice(0, 5);
  };

  const rawList = (apiTopServices && apiTopServices.length > 0)
    ? apiTopServices 
    : buildDynamicCategories();

  const displayList = rawList.map((item) => {
    const meta = getCategoryMeta(item.name || item._id || item.category);
    return {
      id: item.id || item._id || meta.name,
      name: item.name || meta.name,
      percentage: Number(item.percentage) || 20,
      icon: item.icon || meta.icon,
      color: item.color || meta.color,
      bg: item.bg || meta.bg
    };
  });

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
        {displayList.length === 0 ? (
          <div style={{ padding: '20px', textAlign: 'center', color: '#64748b', fontSize: '13px' }}>
            No active services found in database.
          </div>
        ) : (
          displayList.map((service) => (
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
              {/* Icon + Category Name (Original Layout matching Screenshot 1) */}
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
                    backgroundColor: service.bg || '#f0fdf4',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    flexShrink: 0,
                  }}
                >
                  {renderCategoryIcon(service.icon, service.color)}
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
                    width: `${service.percentage * 3.2}%`,
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
          ))
        )}
      </div>
    </div>
  );
}
