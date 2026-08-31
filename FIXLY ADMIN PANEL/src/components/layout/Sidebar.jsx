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

export const navigationItems = [
  { path: '/dashboard', key: 'dashboard', icon: LayoutDashboard },
  { path: '/bookings', key: 'bookings', icon: CalendarCheck },
  { path: '/workers', key: 'workers', icon: Users },
  { path: '/customers', key: 'customers', icon: UserCheck },
  { path: '/services', key: 'services', icon: Layers },
  { path: '/payments', key: 'payments', icon: CreditCard },
  { path: '/insurance', key: 'insurance', icon: ShieldCheck },
  { path: '/reviews', key: 'reviews', icon: Star },
  { path: '/reports', key: 'reports', icon: FileSpreadsheet },
  { path: '/analytics', key: 'analytics', icon: TrendingUp },
  { path: '/ai-insights', key: 'aiInsights', icon: BrainCircuit },
  { path: '/notifications', key: 'notifications', icon: Bell },
  { path: '/settings', key: 'settings', icon: Settings },
];

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
          padding: '22px 14px 18px 18px',
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
              marginBottom: '24px',
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
                  Cooperative
                </div>
                <div
                  style={{
                    fontSize: '11.5px',
                    color: '#55695e',
                    fontWeight: '500',
                  }}
                >
                  Gig/Services Platform
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

          {/* Navigation Links using NavLink */}
          <nav style={{ display: 'flex', flexDirection: 'column', gap: '3px' }}>
            {navigationItems.map((item) => {
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
                    padding: '9.5px 14px',
                    borderRadius: '11px',
                    fontSize: '13.5px',
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
                        size={18}
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
          </nav>
        </div>

        {/* Bottom Logo Badge */}
        <div
          style={{
            paddingLeft: '6px',
            paddingTop: '14px',
            borderTop: '1px solid var(--border-subtle)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
          }}
        >
          <div
            style={{
              width: '32px',
              height: '32px',
              borderRadius: '50%',
              border: '2px solid #1e7e45',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              fontWeight: '800',
              fontSize: '14.5px',
              color: '#1e7e45',
              backgroundColor: '#f4fbf6',
            }}
          >
            9
          </div>
      </aside>
    </>
  );
}
