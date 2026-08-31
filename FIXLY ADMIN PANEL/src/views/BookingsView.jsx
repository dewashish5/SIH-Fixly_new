import React, { useState } from 'react';
import { recentBookingsData } from '../data/mockData';
import {
  Search,
  Filter,
  Plus,
  Download,
  Calendar,
  CheckCircle,
  Clock,
  ChevronRight,
  Eye
} from 'lucide-react';

export default function BookingsView({ onSelectBooking }) {
  const [filter, setFilter] = useState('All');
  const [search, setSearch] = useState('');

  const filtered = recentBookingsData.filter((b) => {
    const matchFilter = filter === 'All' || b.status === filter;
    const matchSearch =
      b.id.toLowerCase().includes(search.toLowerCase()) ||
      b.customer.toLowerCase().includes(search.toLowerCase()) ||
      b.worker.toLowerCase().includes(search.toLowerCase()) ||
      b.service.toLowerCase().includes(search.toLowerCase());
    return matchFilter && matchSearch;
  });

  return (
    <div style={{ padding: '0 32px 32px 32px', animation: 'fadeIn 0.2s ease' }}>
      {/* Header Bar */}
      <div
        style={{
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          marginBottom: '20px',
          flexWrap: 'wrap',
          gap: '12px',
        }}
      >
        <div>
          <h2 style={{ fontSize: '20px', fontWeight: '700', color: '#111827' }}>
            Bookings Management
          </h2>
          <p style={{ fontSize: '13px', color: '#64748b' }}>
            Manage all on-demand gig tasks, worker assignments, and real-time statuses
          </p>
        </div>

        <div style={{ display: 'flex', gap: '10px' }}>
          <button
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '6px',
              padding: '9px 14px',
              backgroundColor: '#ffffff',
              border: '1px solid var(--border-light)',
              borderRadius: '8px',
              fontSize: '13px',
              fontWeight: '600',
              color: '#334155',
            }}
          >
            <Download size={15} />
            <span>Export CSV</span>
          </button>
          <button
            onClick={() => alert('Opening Create Booking Dialog')}
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
            <span>New Booking</span>
          </button>
        </div>
      </div>

      {/* Filter and Search Bar */}
      <div
        style={{
          backgroundColor: '#ffffff',
          padding: '14px 18px',
          borderRadius: '12px',
          border: '1px solid var(--border-light)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          marginBottom: '16px',
          gap: '12px',
          flexWrap: 'wrap',
        }}
      >
        {/* Search */}
        <div
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: '8px',
            backgroundColor: '#f8fafc',
            border: '1px solid #e2e8f0',
            borderRadius: '8px',
            padding: '7px 12px',
            width: '320px',
          }}
        >
          <Search size={15} color="#94a3b8" />
          <input
            type="text"
            placeholder="Search booking ID, customer, worker..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            style={{ border: 'none', outline: 'none', backgroundColor: 'transparent', width: '100%', fontSize: '13px' }}
          />
        </div>

        {/* Status Filters */}
        <div style={{ display: 'flex', gap: '6px' }}>
          {['All', 'Confirmed', 'Pending'].map((st) => (
            <button
              key={st}
              onClick={() => setFilter(st)}
              style={{
                padding: '6px 14px',
                borderRadius: '8px',
                fontSize: '12.5px',
                fontWeight: '600',
                backgroundColor: filter === st ? '#eaf7ee' : 'transparent',
                color: filter === st ? '#15803d' : '#64748b',
                border: `1px solid ${filter === st ? '#86efac' : 'transparent'}`,
              }}
            >
              {st}
            </button>
          ))}
        </div>
      </div>

      {/* Bookings Table */}
      <div
        style={{
          backgroundColor: '#ffffff',
          borderRadius: '14px',
          border: '1px solid var(--border-light)',
          overflow: 'hidden',
          boxShadow: 'var(--shadow-card)',
        }}
      >
        <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left' }}>
          <thead>
            <tr style={{ backgroundColor: '#f8faf9', borderBottom: '1px solid #e6ede8', color: '#55695e', fontSize: '12px', fontWeight: '700' }}>
              <th style={{ padding: '14px 18px' }}>Booking ID</th>
              <th style={{ padding: '14px 18px' }}>Customer</th>
              <th style={{ padding: '14px 18px' }}>Service Details</th>
              <th style={{ padding: '14px 18px' }}>Assigned Worker</th>
              <th style={{ padding: '14px 18px' }}>Amount</th>
              <th style={{ padding: '14px 18px' }}>Status</th>
              <th style={{ padding: '14px 18px', textAlign: 'right' }}>Action</th>
            </tr>
          </thead>
          <tbody>
            {filtered.map((b) => (
              <tr
                key={b.id}
                style={{ borderBottom: '1px solid #f1f5f3', fontSize: '13px' }}
              >
                <td style={{ padding: '14px 18px' }}>
                  <span
                    onClick={() => onSelectBooking(b)}
                    style={{ color: 'var(--text-link)', fontWeight: '700', cursor: 'pointer' }}
                  >
                    {b.id}
                  </span>
                  <div style={{ fontSize: '11px', color: '#94a3b8' }}>{b.date} • {b.time}</div>
                </td>
                <td style={{ padding: '14px 18px', fontWeight: '600', color: '#1e293b' }}>
                  {b.customer}
                  <div style={{ fontSize: '11.5px', color: '#64748b', fontWeight: '400' }}>{b.customerPhone}</div>
                </td>
                <td style={{ padding: '14px 18px' }}>
                  <div style={{ fontWeight: '600', color: '#1e293b' }}>{b.service}</div>
                  <div style={{ fontSize: '11.5px', color: '#64748b' }}>{b.serviceType}</div>
                </td>
                <td style={{ padding: '14px 18px' }}>
                  <div style={{ fontWeight: '600', color: '#1e293b' }}>{b.worker}</div>
                  <div style={{ fontSize: '11.5px', color: '#15803d', fontWeight: '500' }}>⭐ {b.workerRating}</div>
                </td>
                <td style={{ padding: '14px 18px', fontWeight: '700', color: '#0f172a' }}>
                  {b.amount}
                </td>
                <td style={{ padding: '14px 18px' }}>
                  <span
                    style={{
                      padding: '4px 10px',
                      borderRadius: '999px',
                      fontSize: '11.5px',
                      fontWeight: '600',
                      backgroundColor: b.status === 'Confirmed' ? '#eaf8ef' : '#fef8e7',
                      color: b.status === 'Confirmed' ? '#15803d' : '#d97706',
                    }}
                  >
                    {b.status}
                  </span>
                </td>
                <td style={{ padding: '14px 18px', textAlign: 'right' }}>
                  <button
                    onClick={() => onSelectBooking(b)}
                    style={{
                      padding: '6px 12px',
                      backgroundColor: '#f1f8f3',
                      color: '#15803d',
                      borderRadius: '6px',
                      fontSize: '12px',
                      fontWeight: '600',
                    }}
                  >
                    View Details
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
