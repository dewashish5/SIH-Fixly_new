import React from 'react';
import { NavLink } from 'react-router-dom';
import {
  LayoutDashboard,
  CalendarCheck,
  Users,
  UserCheck,
  Layers,
  CreditCard,
  ShieldCheck,
  Star,
  FileSpreadsheet,
  TrendingUp,
  BrainCircuit,
  Bell,
  Settings,
  X
} from 'lucide-react';
import { useLanguage } from '../../context/LanguageContext';

export const navigationSections = [
  {
    title: 'Overview',
    sectionKey: 'overviewSection',
    items: [
      { path: '/dashboard', key: 'dashboard', icon: LayoutDashboard },
      { path: '/analytics', key: 'analytics', icon: TrendingUp },
      { path: '/ai-insights', key: 'aiInsights', icon: BrainCircuit },
      { path: '/reports', key: 'reports', icon: FileSpreadsheet },
    ]
  },
  {
    title: 'Services & Operations',
    sectionKey: 'servicesSection',
    items: [
      { path: '/bookings', key: 'bookings', icon: CalendarCheck },
      { path: '/services', key: 'services', icon: Layers },
    ]
  },
  {
    title: 'Manage Users',
    sectionKey: 'usersSection',
    items: [
      { path: '/workers', key: 'workers', icon: Users },
      { path: '/customers', key: 'customers', icon: UserCheck },
    ]
  },
  {
    title: 'Finance & Safety',
    sectionKey: 'financeSection',
    items: [
      { path: '/payments', key: 'payments', icon: CreditCard },
      { path: '/insurance', key: 'insurance', icon: ShieldCheck },
      { path: '/reviews', key: 'reviews', icon: Star },
    ]
  },
  {
    title: 'System & Settings',
    sectionKey: 'settingsSection',
    items: [
      { path: '/notifications', key: 'notifications', icon: Bell },
      { path: '/settings', key: 'settings', icon: Settings },
    ]
  }
];

export const navigationItems = navigationSections.flatMap((s) => s.items);

export default function Sidebar({ isOpen, setIsOpen }) {
  const { t } = useLanguage();

  return (
    <>
      {/* Mobile Backdrop */}
      {isOpen && (
        <div
          onClick={() => setIsOpen(false)}
          style={{
            position: 'fixed',
            inset: 0,
            backgroundColor: 'rgba(0,0,0,0.45)',
            zIndex: 40,
            backdropFilter: 'blur(2px)',
          }}
        />
      )}

      <aside
        style={{
          width: '260px',
          height: '100vh',
          position: 'sticky',
          top: 0,
          backgroundColor: 'var(--bg-sidebar)',
          borderRight: '1px solid var(--border-subtle)',
          display: 'flex',
          flexDirection: 'column',
          justifyContent: 'space-between',
          padding: '20px 14px 18px 16px',
          zIndex: 45,
          transition: 'transform 0.3s ease',
          flexShrink: 0,
          overflowY: 'auto',
        }}
      >
        {/* Top Header & Logo */}
        <div>
          <div
            style={{
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'space-between',
              marginBottom: '20px',
              paddingLeft: '4px',
            }}
          >
            <NavLink
              to="/dashboard"
              style={{ display: 'flex', alignItems: 'center', gap: '12px' }}
            >
              <div
                style={{
                  width: '38px',
                  height: '38px',
                  borderRadius: '10px',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  backgroundColor: '#eaf7ee',
                  flexShrink: 0,
                }}
              >
                <img
                  src="/logo.svg"
                  alt="Cooperative Logo"
                  style={{ width: '28px', height: '28px', objectFit: 'contain' }}
                />
              </div>
              <div style={{ lineHeight: '1.2' }}>
                <div
                  style={{
                    fontWeight: '700',
                    fontSize: '14.5px',
                    color: '#12251a',
                    letterSpacing: '-0.2px',
                  }}
                >
                  Fixly Cooperative
                </div>
                <div
                  style={{
                    fontSize: '11.5px',
                    color: '#55695e',
                    fontWeight: '500',
                  }}
                >
                  Admin Control Panel
                </div>
              </div>
            </NavLink>

            {/* Mobile Close Button */}
            {isOpen && (
              <button
                onClick={() => setIsOpen(false)}
                style={{
                  padding: '6px',
                  borderRadius: '8px',
                  color: '#64748b',
                }}
              >
                <X size={20} />
              </button>
            )}
          </div>

          {/* Navigation Sections with Category Titles */}
          <nav style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
            {navigationSections.map((section, sIdx) => (
              <div key={section.sectionKey || sIdx}>
                {/* Section Header Title */}
                <div
                  style={{
                    fontSize: '11px',
                    fontWeight: '700',
                    color: '#7a8e81',
                    textTransform: 'uppercase',
                    letterSpacing: '0.8px',
                    padding: '4px 12px 6px 12px',
                    userSelect: 'none',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'space-between',
                  }}
                >
                  <span>{t(section.sectionKey) || section.title}</span>
                </div>

                {/* Section Navigation Items */}
                <div style={{ display: 'flex', flexDirection: 'column', gap: '3px' }}>
                  {section.items.map((item) => {
                    const Icon = item.icon;

                    return (
                      <NavLink
                        key={item.key}
                        to={item.path}
                        onClick={() => {
                          if (window.innerWidth < 1024) setIsOpen(false);
                        }}
                        className={({ isActive }) =>
                          `nav-link ${isActive ? 'active-link' : ''}`
                        }
                        style={({ isActive }) => ({
                          display: 'flex',
                          alignItems: 'center',
                          gap: '12px',
                          padding: '8.5px 12px',
                          borderRadius: '10px',
                          fontSize: '13px',
                          fontWeight: isActive ? '600' : '500',
                          color: isActive ? '#ffffff' : '#4d5e53',
                          backgroundColor: isActive ? 'var(--primary-brand)' : 'transparent',
                          boxShadow: isActive ? '0 4px 12px rgba(30, 126, 69, 0.28)' : 'none',
                          transition: 'all 0.15s ease',
                          textAlign: 'left',
                          width: '100%',
                          textDecoration: 'none',
                        })}
                      >
                        {({ isActive }) => (
                          <>
                            <Icon
                              size={17}
                              strokeWidth={isActive ? 2.3 : 1.9}
                              style={{
                                color: isActive ? '#ffffff' : '#62766a',
                                flexShrink: 0,
                              }}
                            />
                            <span style={{ whiteSpace: 'nowrap' }}>{t(item.key)}</span>
                          </>
                        )}
                      </NavLink>
                    );
                  })}
                </div>
              </div>
            ))}
          </nav>
        </div>

        {/* Bottom Status Badge */}
        <div
          style={{
            paddingLeft: '6px',
            paddingTop: '12px',
            borderTop: '1px solid var(--border-subtle)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
            fontSize: '11px',
            color: '#7a8e81',
          }}
        >
          <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
            <span
              style={{
                width: '7px',
                height: '7px',
                borderRadius: '50%',
                backgroundColor: '#22c55e',
                boxShadow: '0 0 6px #22c55e',
              }}
            />
            <span style={{ fontWeight: '600' }}>Fixly Live</span>
          </div>
          <span style={{ fontSize: '10px', color: '#94a3b8' }}>v2.4.0</span>
        </div>
      </aside>
    </>
  );
}
