import React, { useState, useEffect } from 'react';
import {
  Search,
  X,
  User,
  CalendarCheck,
  ArrowRight,
} from 'lucide-react';
import { useApp } from '../context/AppContext';

export default function QuickSearchModal({ isOpen, onClose, onSelectBooking, onSelectWorker, onNavigateTab }) {
  const { recentBookings = [], workers = [], fetchWorkers, fetchBookings } = useApp();
  const [query, setQuery] = useState('');

  useEffect(() => {
    if (!isOpen) return;
    fetchWorkers({ page: 1, limit: 50, isVerified: 'true' });
    fetchBookings({ page: 1, limit: 50 });
  }, [isOpen, fetchWorkers, fetchBookings]);

  useEffect(() => {
    const handleKeyDown = (e) => {
      if ((e.metaKey || e.ctrlKey) && e.key === 'k') {
        e.preventDefault();
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, []);

  if (!isOpen) return null;

  const q = query.toLowerCase().trim();

  const filteredBookings = (recentBookings || []).filter((b) => {
    if (!q) return true;
    const id = String(b.bookingId || b._id || '');
    const customer = b.customer?.name || b.customer || '';
    const service = b.service?.title || b.service || '';
    return (
      id.toLowerCase().includes(q) ||
      String(customer).toLowerCase().includes(q) ||
      String(service).toLowerCase().includes(q)
    );
  }).slice(0, 8);

  const filteredWorkers = (workers || []).filter((w) => {
    if (!q) return true;
    return (
      (w.name || '').toLowerCase().includes(q) ||
      (w.category || w.service || '').toLowerCase().includes(q)
    );
  }).slice(0, 8);

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
        <div
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: '12px',
            padding: '16px 20px',
            borderBottom: '1px solid #f1f5f9',
          }}
        >
          <Search size={18} color="#94a3b8" />
          <input
            autoFocus
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder="Search bookings or verified workers…"
            style={{ flex: 1, border: 'none', outline: 'none', fontSize: 15 }}
          />
          <button type="button" onClick={onClose} style={{ border: 'none', background: 'transparent', cursor: 'pointer' }}>
            <X size={18} color="#64748b" />
          </button>
        </div>

        <div style={{ maxHeight: '50vh', overflowY: 'auto', padding: '8px 0' }}>
          <div style={{ padding: '8px 20px', fontSize: 11, fontWeight: 700, color: '#94a3b8', textTransform: 'uppercase' }}>
            Bookings
          </div>
          {filteredBookings.length === 0 ? (
            <div style={{ padding: '8px 20px', fontSize: 13, color: '#94a3b8' }}>No bookings match</div>
          ) : (
            filteredBookings.map((b) => {
              const id = b.bookingId || b._id;
              const customer = b.customer?.name || b.customer || 'Customer';
              const service = b.service?.title || b.service || 'Service';
              return (
                <button
                  key={id}
                  type="button"
                  onClick={() => {
                    onSelectBooking?.(b);
                    onClose();
                  }}
                  style={{
                    width: '100%',
                    textAlign: 'left',
                    display: 'flex',
                    alignItems: 'center',
                    gap: 10,
                    padding: '10px 20px',
                    border: 'none',
                    background: 'transparent',
                    cursor: 'pointer',
                  }}
                >
                  <CalendarCheck size={16} color="#15803d" />
                  <div style={{ flex: 1 }}>
                    <div style={{ fontSize: 13, fontWeight: 600 }}>{id}</div>
                    <div style={{ fontSize: 12, color: '#64748b' }}>{customer} · {service}</div>
                  </div>
                  <ArrowRight size={14} color="#cbd5e1" />
                </button>
              );
            })
          )}

          <div style={{ padding: '12px 20px 8px', fontSize: 11, fontWeight: 700, color: '#94a3b8', textTransform: 'uppercase' }}>
            Workers
          </div>
          {filteredWorkers.length === 0 ? (
            <div style={{ padding: '8px 20px', fontSize: 13, color: '#94a3b8' }}>No verified workers match</div>
          ) : (
            filteredWorkers.map((w) => (
              <button
                key={w.id}
                type="button"
                onClick={() => {
                  onSelectWorker?.(w);
                  onNavigateTab?.('workers');
                  onClose();
                }}
                style={{
                  width: '100%',
                  textAlign: 'left',
                  display: 'flex',
                  alignItems: 'center',
                  gap: 10,
                  padding: '10px 20px',
                  border: 'none',
                  background: 'transparent',
                  cursor: 'pointer',
                }}
              >
                <User size={16} color="#15803d" />
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: 13, fontWeight: 600 }}>{w.name}</div>
                  <div style={{ fontSize: 12, color: '#64748b' }}>{w.category || w.service || '—'}</div>
                </div>
                <ArrowRight size={14} color="#cbd5e1" />
              </button>
            ))
          )}
        </div>
      </div>
    </div>
  );
}
