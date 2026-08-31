import React, { useState } from 'react';
import {
  Bell,
  ChevronDown,
  Calendar,
  Search,
  Menu,
  Check,
  User,
  Shield,
  LogOut,
  SlidersHorizontal
} from 'lucide-react';

export default function Header({
  onOpenMobileMenu,
  onOpenSearch,
  onOpenNotifications,
  unreadCount = 3,
}) {
  const [selectedDateRange, setSelectedDateRange] = useState('May 26, 2025');
  const [isDateOpen, setIsDateOpen] = useState(false);
  const [isProfileOpen, setIsProfileOpen] = useState(false);

  const dateOptions = [
    'Today (May 26, 2025)',
    'Yesterday (May 25, 2025)',
    'Last 7 Days (20 - 26 May)',
    'This Month (May 2025)',
    'Custom Range...',
  ];

  return (
    <header
      style={{
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
        padding: '24px 32px 16px 32px',
        gap: '20px',
        flexWrap: 'wrap',
      }}
    >
      {/* Left: Greeting & Subtitle */}
      <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
        {/* Mobile menu trigger */}
        <button
          onClick={onOpenMobileMenu}
          className="mobile-only"
          style={{
            display: 'none',
            padding: '8px',
            borderRadius: '10px',
            backgroundColor: '#ffffff',
            border: '1px solid var(--border-light)',
            color: '#334155',
          }}
        >
          <Menu size={20} />
        </button>

        <div>
          <h1
            style={{
              fontSize: '24px',
              fontWeight: '700',
              color: 'var(--primary-brand)',
              display: 'flex',
              alignItems: 'center',
              gap: '8px',
              letterSpacing: '-0.4px',
            }}
          >
            Welcome back, Admin! <span style={{ fontSize: '22px' }}>👋</span>
          </h1>
          <p
            style={{
              fontSize: '13px',
              color: 'var(--text-secondary)',
              fontWeight: '500',
              marginTop: '2px',
            }}
          >
            Together we build stronger communities.
          </p>
        </div>
      </div>

      {/* Right Controls: Date Selector, Notifications, Admin Profile */}
      <div
        style={{
          display: 'flex',
          alignItems: 'center',
          gap: '12px',
          position: 'relative',
        }}
      >
        {/* Search Trigger Button */}
        <button
          onClick={onOpenSearch}
          title="Quick Search (Ctrl + K)"
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: '8px',
            padding: '8px 14px',
            backgroundColor: '#ffffff',
            border: '1px solid var(--border-light)',
            borderRadius: 'var(--radius-pill)',
            color: '#64748b',
            fontSize: '13px',
            fontWeight: '500',
            boxShadow: 'var(--shadow-card)',
            transition: 'all 0.15s ease',
          }}
          onMouseEnter={(e) => (e.currentTarget.style.borderColor = '#bbf7d0')}
          onMouseLeave={(e) => (e.currentTarget.style.borderColor = 'var(--border-light)')}
        >
          <Search size={15} color="#1e7e45" />
          <span className="search-text">Search...</span>
          <kbd
            style={{
              fontSize: '10px',
              padding: '2px 5px',
              backgroundColor: '#f1f5f9',
              borderRadius: '4px',
              color: '#94a3b8',
              border: '1px solid #e2e8f0',
            }}
          >
            ⌘K
          </kbd>
        </button>

        {/* Date Selector Dropdown */}
        <div style={{ position: 'relative' }}>
          <button
            onClick={() => setIsDateOpen(!isDateOpen)}
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '8px',
              padding: '8px 16px',
              backgroundColor: '#ffffff',
              border: '1px solid var(--border-light)',
              borderRadius: 'var(--radius-pill)',
              color: '#2d3f34',
              fontSize: '13px',
              fontWeight: '600',
              boxShadow: 'var(--shadow-card)',
              transition: 'all 0.15s ease',
            }}
            onMouseEnter={(e) => (e.currentTarget.style.borderColor = '#bbf7d0')}
            onMouseLeave={(e) => (e.currentTarget.style.borderColor = 'var(--border-light)')}
          >
            <Calendar size={14} color="#1e7e45" />
            <span>{selectedDateRange}</span>
            <ChevronDown size={14} color="#64748b" />
          </button>

          {isDateOpen && (
            <div
              style={{
                position: 'absolute',
                top: 'calc(100% + 8px)',
                right: 0,
                backgroundColor: '#ffffff',
                borderRadius: '12px',
                border: '1px solid var(--border-light)',
                boxShadow: '0 10px 25px -5px rgba(0, 0, 0, 0.1), 0 8px 10px -6px rgba(0, 0, 0, 0.05)',
                width: '210px',
                padding: '6px',
                zIndex: 50,
                animation: 'fadeIn 0.2s ease',
              }}
            >
              {dateOptions.map((opt) => (
                <button
                  key={opt}
                  onClick={() => {
                    setSelectedDateRange(opt.split(' (')[0].replace('Today', 'May 26, 2025'));
                    setIsDateOpen(false);
                  }}
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'space-between',
                    width: '100%',
                    padding: '8px 12px',
                    borderRadius: '8px',
                    fontSize: '12px',
                    color: '#334155',
                    textAlign: 'left',
                    fontWeight: '500',
                    transition: 'background 0.15s ease',
                  }}
                  onMouseEnter={(e) => (e.currentTarget.style.backgroundColor = '#f1f7f3')}
                  onMouseLeave={(e) => (e.currentTarget.style.backgroundColor = 'transparent')}
                >
                  <span>{opt}</span>
                  {selectedDateRange.includes('May 26') && opt.includes('May 26') && (
                    <Check size={13} color="#1e7e45" />
                  )}
                </button>
              ))}
            </div>
          )}
        </div>

        {/* Notification Bell */}
        <button
          onClick={onOpenNotifications}
          title="Notifications"
          style={{
            position: 'relative',
            width: '38px',
            height: '38px',
            borderRadius: '50%',
            backgroundColor: '#ffffff',
            border: '1px solid var(--border-light)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            color: '#475569',
            boxShadow: 'var(--shadow-card)',
            transition: 'all 0.15s ease',
          }}
          onMouseEnter={(e) => (e.currentTarget.style.borderColor = '#86efac')}
          onMouseLeave={(e) => (e.currentTarget.style.borderColor = 'var(--border-light)')}
        >
          <Bell size={17} />
          {unreadCount > 0 && (
            <span
              style={{
                position: 'absolute',
                top: '6px',
                right: '7px',
                width: '8px',
                height: '8px',
                borderRadius: '50%',
                backgroundColor: 'var(--primary-brand)',
                boxShadow: '0 0 0 2px #ffffff',
              }}
            />
          )}
        </button>

        {/* Admin Profile */}
        <div style={{ position: 'relative' }}>
          <button
            onClick={() => setIsProfileOpen(!isProfileOpen)}
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '10px',
              padding: '4px 10px 4px 4px',
              backgroundColor: '#ffffff',
              border: '1px solid var(--border-light)',
              borderRadius: 'var(--radius-pill)',
              boxShadow: 'var(--shadow-card)',
              transition: 'all 0.15s ease',
            }}
            onMouseEnter={(e) => (e.currentTarget.style.borderColor = '#86efac')}
            onMouseLeave={(e) => (e.currentTarget.style.borderColor = 'var(--border-light)')}
          >
            <img
              src="https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=80&auto=format&fit=crop&q=80"
              alt="Admin Profile"
              style={{
                width: '30px',
                height: '30px',
                borderRadius: '50%',
                objectFit: 'cover',
                border: '1.5px solid #22c55e',
              }}
            />
            <span
              style={{
                fontSize: '13px',
                fontWeight: '600',
                color: '#1f2937',
              }}
            >
              Admin
            </span>
            <ChevronDown size={13} color="#64748b" />
          </button>

          {isProfileOpen && (
            <div
              style={{
                position: 'absolute',
                top: 'calc(100% + 8px)',
                right: 0,
                backgroundColor: '#ffffff',
                borderRadius: '12px',
                border: '1px solid var(--border-light)',
                boxShadow: '0 10px 25px -5px rgba(0, 0, 0, 0.1), 0 8px 10px -6px rgba(0, 0, 0, 0.05)',
                width: '200px',
                padding: '6px',
                zIndex: 50,
                animation: 'fadeIn 0.2s ease',
              }}
            >
              <div
                style={{
                  padding: '8px 12px',
                  borderBottom: '1px solid #f1f5f9',
                  marginBottom: '4px',
                }}
              >
                <div style={{ fontSize: '13px', fontWeight: '700', color: '#0f172a' }}>
                  Super Administrator
                </div>
                <div style={{ fontSize: '11px', color: '#64748b' }}>
                  admin@cooperative.org
                </div>
              </div>

              <button
                onClick={() => setIsProfileOpen(false)}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: '10px',
                  width: '100%',
                  padding: '8px 12px',
                  borderRadius: '8px',
                  fontSize: '13px',
                  color: '#334155',
                  textAlign: 'left',
                }}
                onMouseEnter={(e) => (e.currentTarget.style.backgroundColor = '#f8fafc')}
                onMouseLeave={(e) => (e.currentTarget.style.backgroundColor = 'transparent')}
              >
                <User size={15} color="#64748b" />
                <span>My Profile</span>
              </button>

              <button
                onClick={() => setIsProfileOpen(false)}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: '10px',
                  width: '100%',
                  padding: '8px 12px',
                  borderRadius: '8px',
                  fontSize: '13px',
                  color: '#334155',
                  textAlign: 'left',
                }}
                onMouseEnter={(e) => (e.currentTarget.style.backgroundColor = '#f8fafc')}
                onMouseLeave={(e) => (e.currentTarget.style.backgroundColor = 'transparent')}
              >
                <Shield size={15} color="#64748b" />
                <span>Security & Roles</span>
              </button>

              <button
                onClick={() => setIsProfileOpen(false)}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: '10px',
                  width: '100%',
                  padding: '8px 12px',
                  borderRadius: '8px',
                  fontSize: '13px',
                  color: '#334155',
                  textAlign: 'left',
                }}
                onMouseEnter={(e) => (e.currentTarget.style.backgroundColor = '#f8fafc')}
                onMouseLeave={(e) => (e.currentTarget.style.backgroundColor = 'transparent')}
              >
                <SlidersHorizontal size={15} color="#64748b" />
                <span>Platform Preferences</span>
              </button>

              <div style={{ height: '1px', backgroundColor: '#f1f5f9', margin: '4px 0' }} />

              <button
                onClick={() => setIsProfileOpen(false)}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: '10px',
                  width: '100%',
                  padding: '8px 12px',
                  borderRadius: '8px',
                  fontSize: '13px',
                  color: '#dc2626',
                  textAlign: 'left',
                }}
                onMouseEnter={(e) => (e.currentTarget.style.backgroundColor = '#fef2f2')}
                onMouseLeave={(e) => (e.currentTarget.style.backgroundColor = 'transparent')}
              >
                <LogOut size={15} />
                <span>Sign Out</span>
              </button>
            </div>
          )}
        </div>
      </div>
    </header>
  );
}
