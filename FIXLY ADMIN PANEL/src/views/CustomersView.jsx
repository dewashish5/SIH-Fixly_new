import React, { useState } from 'react';
import {
  UserCheck,
  Search,
  Star,
  Phone,
  MapPin,
  Calendar,
  IndianRupee,
  ShieldCheck
} from 'lucide-react';

export default function CustomersView({ onSelectBooking }) {
  const [search, setSearch] = useState('');

  const customers = [
    {
      id: 'CUST-8801',
      name: 'Ravi Sharma',
      phone: '+91 98765 43210',
      email: 'ravi.sharma@gmail.com',
      address: 'Flat 402, Green Valley Apartments, Sector 18, Noida',
      totalBookings: 14,
      totalSpent: '₹18,450',
      memberSince: 'Jan 2024',
      rating: 4.9,
      status: 'Active Member',
    },
    {
      id: 'CUST-8802',
      name: 'Sneha Verma',
      phone: '+91 98111 22334',
      email: 'sneha.verma@outlook.com',
      address: 'B-12, Sector 62, Indirapuram, Ghaziabad',
      totalBookings: 8,
      totalSpent: '₹12,200',
      memberSince: 'Mar 2024',
      rating: 5.0,
      status: 'Active Member',
    },
    {
      id: 'CUST-8803',
      name: 'Amit Singh',
      phone: '+91 99887 76655',
      email: 'amit.singh99@gmail.com',
      address: 'House 88, Pocket C, Mayur Vihar Phase 2, New Delhi',
      totalBookings: 22,
      totalSpent: '₹34,800',
      memberSince: 'Nov 2023',
      rating: 4.8,
      status: 'VIP Patron',
    },
    {
      id: 'CUST-8804',
      name: 'Pooja Agarwal',
      phone: '+91 93456 78901',
      email: 'pooja.agarwal@corp.in',
      address: 'Villa 14, Palm Meadows, Gurgaon',
      totalBookings: 19,
      totalSpent: '₹29,600',
      memberSince: 'Feb 2024',
      rating: 4.95,
      status: 'VIP Patron',
    },
  ];

  const filtered = customers.filter(
    (c) =>
      c.name.toLowerCase().includes(search.toLowerCase()) ||
      c.email.toLowerCase().includes(search.toLowerCase()) ||
      c.phone.includes(search)
  );

  return (
    <div style={{ padding: '0 32px 32px 32px', animation: 'fadeIn 0.2s ease' }}>
      {/* Header */}
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
            Customer Directory (9,876)
          </h2>
          <p style={{ fontSize: '13px', color: '#64748b' }}>
            Customer lifetime bookings, addresses, and satisfaction metrics
          </p>
        </div>

        <div style={{ display: 'flex', gap: '10px' }}>
          <div
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '8px',
              backgroundColor: '#ffffff',
              border: '1px solid var(--border-light)',
              borderRadius: '8px',
              padding: '7px 12px',
              width: '280px',
            }}
          >
            <Search size={15} color="#94a3b8" />
            <input
              type="text"
              placeholder="Search customer name, phone..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              style={{
                border: 'none',
                outline: 'none',
                backgroundColor: 'transparent',
                width: '100%',
                fontSize: '13px',
              }}
            />
          </div>
        </div>
      </div>

      {/* Customers Table */}
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
              <th style={{ padding: '14px 18px' }}>Customer</th>
              <th style={{ padding: '14px 18px' }}>Contact & Location</th>
              <th style={{ padding: '14px 18px' }}>Total Bookings</th>
              <th style={{ padding: '14px 18px' }}>Lifetime Spend</th>
              <th style={{ padding: '14px 18px' }}>Status</th>
              <th style={{ padding: '14px 18px', textAlign: 'right' }}>Actions</th>
            </tr>
          </thead>
          <tbody>
            {filtered.map((c) => (
              <tr key={c.id} style={{ borderBottom: '1px solid #f1f5f3', fontSize: '13px' }}>
                <td style={{ padding: '14px 18px' }}>
                  <div style={{ fontWeight: '700', color: '#1e293b' }}>{c.name}</div>
                  <div style={{ fontSize: '11px', color: '#64748b' }}>{c.id} • Member since {c.memberSince}</div>
                </td>
                <td style={{ padding: '14px 18px' }}>
                  <div style={{ color: '#334155' }}>{c.phone}</div>
                  <div style={{ fontSize: '11.5px', color: '#64748b', maxWidth: '280px', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                    {c.address}
                  </div>
                </td>
                <td style={{ padding: '14px 18px', fontWeight: '700', color: '#1e293b' }}>
                  {c.totalBookings} tasks
                </td>
                <td style={{ padding: '14px 18px', fontWeight: '700', color: '#15803d' }}>
                  {c.totalSpent}
                </td>
                <td style={{ padding: '14px 18px' }}>
                  <span
                    style={{
                      padding: '4px 10px',
                      borderRadius: '999px',
                      fontSize: '11.5px',
                      fontWeight: '600',
                      backgroundColor: c.status === 'VIP Patron' ? '#fef3c7' : '#eaf8ef',
                      color: c.status === 'VIP Patron' ? '#b45309' : '#15803d',
                    }}
                  >
                    {c.status}
                  </span>
                </td>
                <td style={{ padding: '14px 18px', textAlign: 'right' }}>
                  <button
                    onClick={() => alert(`Showing booking history for ${c.name}`)}
                    style={{
                      padding: '6px 12px',
                      backgroundColor: '#f1f8f3',
                      color: '#15803d',
                      borderRadius: '6px',
                      fontSize: '12px',
                      fontWeight: '600',
                    }}
                  >
                    Booking History
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
