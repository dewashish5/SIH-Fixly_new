import React, { useState, useEffect } from 'react';
import {
  Search,
  X,
  User,
  Wrench,
  CalendarCheck,
  ArrowRight,
  ShieldAlert
} from 'lucide-react';
import { recentBookingsData, liveWorkers, topServicesData } from '../data/mockData';

export default function QuickSearchModal({ isOpen, onClose, onSelectBooking, onSelectWorker, onNavigateTab }) {
  const [query, setQuery] = useState('');

  useEffect(() => {
    const handleKeyDown = (e) => {
      if ((e.metaKey || e.ctrlKey) && e.key === 'k') {
        e.preventDefault();
        // Toggle or handled in parent
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, []);

  if (!isOpen) return null;

  const filteredBookings = recentBookingsData.filter((b) =>
    b.id.toLowerCase().includes(query.toLowerCase()) ||
    b.customer.toLowerCase().includes(query.toLowerCase()) ||
    b.service.toLowerCase().includes(query.toLowerCase())
  );

  const filteredWorkers = liveWorkers.filter((w) =>
    w.name.toLowerCase().includes(query.toLowerCase()) ||
    w.service.toLowerCase().includes(query.toLowerCase())
  );

  return (
    <div
      style={{
        position: 'fixed',
        inset: 0,
        backgroundColor: 'rgba(15, 23, 42, 0.6)',
        backdropFilter: 'blur(4px)',
        zIndex: 80,
        display: 'flex',
        alignItems: 'flex-start',
        justifyContent: 'center',
        paddingTop: '10vh',
        paddingLeft: '20px',
        paddingRight: '20px',
        animation: 'fadeIn 0.15s ease',
      }}
      onClick={onClose}
    >
      <div
        style={{
          width: '100%',
          maxWidth: '580px',
          backgroundColor: '#ffffff',
          borderRadius: '16px',
          boxShadow: '0 20px 40px rgba(0,0,0,0.25)',
          overflow: 'hidden',
          display: 'flex',
          flexDirection: 'column',
        }}
        onClick={(e) => e.stopPropagation()}
      >
        {/* Search input header */}
        <div
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: '12px',
            padding: '16px 20px',
            borderBottom: '1px solid #f1f5f9',
          }}
        >
          <Search size={18} color="#1e7e45" />
          <input
            autoFocus
            type="text"
            placeholder="Type booking ID, worker name, customer, or service..."
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            style={{
              border: 'none',
              outline: 'none',
              width: '100%',
              fontSize: '15px',
              color: '#0f172a',
              backgroundColor: 'transparent',
            }}
          />
          <button
            onClick={onClose}
            style={{
              padding: '4px',
              borderRadius: '6px',
              color: '#94a3b8',
              backgroundColor: '#f1f5f9',
            }}
          >
            <X size={16} />
          </button>
        </div>

        {/* Results */}
        <div style={{ maxHeight: '380px', overflowY: 'auto', padding: '12px 16px' }}>
          {/* Quick Nav Links */}
          <div style={{ marginBottom: '14px' }}>
            <div style={{ fontSize: '11px', fontWeight: '700', color: '#94a3b8', textTransform: 'uppercase', marginBottom: '6px' }}>
              Quick Navigation
            </div>
            <div style={{ display: 'flex', gap: '8px', flexWrap: 'wrap' }}>
              {['Bookings', 'Workers', 'Services', 'Payments', 'Analytics'].map((tab) => (
                <button
                  key={tab}
                  onClick={() => {
                    onNavigateTab(tab.toLowerCase());
                    onClose();
                  }}
                  style={{
                    fontSize: '12px',
                    padding: '5px 10px',
                    backgroundColor: '#f1f5f9',
                    borderRadius: '6px',
                    color: '#334155',
                    fontWeight: '500',
                  }}
                >
                  Go to {tab} →
                </button>
              ))}
            </div>
          </div>

          {/* Bookings Match */}
          {filteredBookings.length > 0 && (
            <div style={{ marginBottom: '14px' }}>
              <div style={{ fontSize: '11px', fontWeight: '700', color: '#94a3b8', textTransform: 'uppercase', marginBottom: '6px' }}>
                Bookings
              </div>
              {filteredBookings.map((b) => (
                <div
                  key={b.id}
                  onClick={() => {
                    onSelectBooking(b);
                    onClose();
                  }}
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'space-between',
                    padding: '8px 10px',
                    borderRadius: '8px',
                    cursor: 'pointer',
                    transition: 'background 0.15s ease',
                  }}
                  onMouseEnter={(e) => (e.currentTarget.style.backgroundColor = '#f8fafc')}
                  onMouseLeave={(e) => (e.currentTarget.style.backgroundColor = 'transparent')}
                >
                  <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                    <CalendarCheck size={16} color="#1e7e45" />
                    <div>
                      <div style={{ fontSize: '13px', fontWeight: '600', color: '#1e293b' }}>
                        {b.id} • {b.customer}
                      </div>
                      <div style={{ fontSize: '11.5px', color: '#64748b' }}>
                        {b.service} ({b.worker})
                      </div>
                    </div>
                  </div>
                  <span style={{ fontSize: '11px', color: '#15803d', fontWeight: '600', backgroundColor: '#eaf8ef', padding: '2px 6px', borderRadius: '4px' }}>
                    {b.status}
                  </span>
                </div>
              ))}
            </div>
          )}

          {/* Workers Match */}
          {filteredWorkers.length > 0 && (
            <div>
              <div style={{ fontSize: '11px', fontWeight: '700', color: '#94a3b8', textTransform: 'uppercase', marginBottom: '6px' }}>
                Active Workers
              </div>
              {filteredWorkers.map((w) => (
                <div
                  key={w.id}
                  onClick={() => {
                    if (onSelectWorker) onSelectWorker(w);
                    onClose();
                  }}
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'space-between',
                    padding: '8px 10px',
                    borderRadius: '8px',
                    cursor: 'pointer',
                    transition: 'background 0.15s ease',
                  }}
                  onMouseEnter={(e) => (e.currentTarget.style.backgroundColor = '#f8fafc')}
                  onMouseLeave={(e) => (e.currentTarget.style.backgroundColor = 'transparent')}
                >
                  <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                    <User size={16} color="#0284c7" />
                    <div>
                      <div style={{ fontSize: '13px', fontWeight: '600', color: '#1e293b' }}>
                        {w.name}
                      </div>
                      <div style={{ fontSize: '11.5px', color: '#64748b' }}>
                        {w.service} • ⭐ {w.rating}
                      </div>
                    </div>
                  </div>
                  <span style={{ fontSize: '11px', color: '#475569', fontWeight: '500' }}>
                    {w.status}
                  </span>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
