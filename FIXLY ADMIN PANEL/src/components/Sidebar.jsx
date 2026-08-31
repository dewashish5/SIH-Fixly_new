import React from 'react';
import {
  LayoutDashboard,
  CalendarCheck,
  Users,
  UserCheck,
  Layers,
  CreditCard,
  ShieldCheck,
  FileSpreadsheet,
  TrendingUp,
  Settings,
  X
} from 'lucide-react';

export const navItems = [
  { id: 'dashboard', label: 'Dashboard', icon: LayoutDashboard },
  { id: 'bookings', label: 'Bookings', icon: CalendarCheck },
  { id: 'workers', label: 'Workers', icon: Users },
  { id: 'customers', label: 'Customers', icon: UserCheck },
  { id: 'services', label: 'Services', icon: Layers },
  { id: 'payments', label: 'Payments', icon: CreditCard },
  { id: 'insurance', label: 'Insurance & Welfare', icon: ShieldCheck },
  { id: 'reports', label: 'Reports', icon: FileSpreadsheet },
  { id: 'analytics', label: 'Analytics', icon: TrendingUp },
  { id: 'settings', label: 'Settings', icon: Settings },
];

export default function Sidebar({ activeTab, setActiveTab, isOpen, setIsOpen }) {
  return (
    <>
      {/* Mobile Backdrop */}
      {isOpen && (
        <div
          onClick={() => setIsOpen(false)}
          style={{
            position: 'fixed',
            inset: 0,
            backgroundColor: 'rgba(0,0,0,0.4)',
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
          padding: '24px 16px 20px 20px',
          zIndex: 45,
          transition: 'transform 0.3s ease',
          flexShrink: 0,
        }}
      >
        {/* Top Header & Logo */}
        <div>
          <div
            style={{
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'space-between',
              marginBottom: '32px',
              paddingLeft: '4px',
            }}
          >
            <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
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
                  alt="Cooperative Platform Logo"
                  style={{ width: '28px', height: '28px', objectFit: 'contain' }}
                />
              </div>
              <div style={{ lineHeight: '1.2' }}>
                <div
                  style={{
                    fontWeight: '700',
                    fontSize: '15px',
                    color: '#12251a',
                    letterSpacing: '-0.2px',
                  }}
                >
                  Cooperative
                </div>
                <div
                  style={{
                    fontSize: '12px',
                    color: '#55695e',
                    fontWeight: '500',
                  }}
                >
                  Gig/Services Platform
                </div>
              </div>
            </div>

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

          {/* Navigation Links */}
          <nav style={{ display: 'flex', flexDirection: 'column', gap: '4px' }}>
            {navItems.map((item) => {
              const Icon = item.icon;
              const isActive = activeTab === item.id;

              return (
                <button
                  key={item.id}
                  onClick={() => {
                    setActiveTab(item.id);
                    if (window.innerWidth < 1024) setIsOpen(false);
                  }}
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    gap: '14px',
                    padding: '11px 16px',
                    borderRadius: '12px',
                    fontSize: '14px',
                    fontWeight: isActive ? '600' : '500',
                    color: isActive ? '#ffffff' : '#4d5e53',
                    backgroundColor: isActive ? 'var(--primary-brand)' : 'transparent',
                    boxShadow: isActive ? '0 4px 12px rgba(30, 126, 69, 0.28)' : 'none',
                    transition: 'all 0.18s ease',
                    textAlign: 'left',
                    width: '100%',
                  }}
                  onMouseEnter={(e) => {
                    if (!isActive) {
                      e.currentTarget.style.backgroundColor = '#f1f7f3';
                      e.currentTarget.style.color = '#1b4d2e';
                    }
                  }}
                  onMouseLeave={(e) => {
                    if (!isActive) {
                      e.currentTarget.style.backgroundColor = 'transparent';
                      e.currentTarget.style.color = '#4d5e53';
                    }
                  }}
                >
                  <Icon
                    size={19}
                    strokeWidth={isActive ? 2.3 : 1.9}
                    style={{
                      color: isActive ? '#ffffff' : '#62766a',
                      flexShrink: 0,
                    }}
                  />
                  <span style={{ whiteSpace: 'nowrap' }}>{item.label}</span>
                </button>
              );
            })}
          </nav>
        </div>

        {/* Bottom Logo Badge */}
        <div
          style={{
            paddingLeft: '6px',
            paddingTop: '16px',
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
              fontSize: '15px',
              color: '#1e7e45',
              backgroundColor: '#f4fbf6',
              boxShadow: '0 2px 6px rgba(30, 126, 69, 0.12)',
            }}
          >
            9
          </div>
          <div
            style={{
              fontSize: '11px',
              color: '#83948b',
              fontWeight: '500',
            }}
          >
            v2.4 Enterprise
          </div>
        </div>
      </aside>
    </>
  );
}
