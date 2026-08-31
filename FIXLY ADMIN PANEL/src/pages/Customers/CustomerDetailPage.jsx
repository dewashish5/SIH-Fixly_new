import React from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useApp } from '../../context/AppContext';
import {
  ArrowLeft,
  User,
  Phone,
  Mail,
  MapPin,
  CalendarCheck,
  CreditCard,
  Star,
  ShieldCheck,
  Ban,
  CheckCircle
} from 'lucide-react';
import Badge from '../../components/common/Badge';

export default function CustomerDetailPage() {
  const { id } = useParams();
  const navigate = useNavigate();
  const { customers, bookings, toggleCustomerBlock } = useApp();

  const customer = customers.find((c) => c.id === id) || customers[0];
  const customerBookings = bookings.filter((b) => b.customer === customer.name);

  return (
    <div style={{ padding: '0 32px 32px 32px', animation: 'fadeIn 0.2s ease', maxWidth: '1050px' }}>
      <button
        onClick={() => navigate('/customers')}
        style={{
          display: 'flex',
          alignItems: 'center',
          gap: '6px',
          padding: '6px 12px',
          borderRadius: '8px',
          backgroundColor: '#ffffff',
          border: '1px solid var(--border-light)',
          color: '#475569',
          fontSize: '13px',
          fontWeight: '600',
          marginBottom: '18px',
        }}
      >
        <ArrowLeft size={15} />
        <span>Back to Customers Directory</span>
      </button>

      {/* Profile Header */}
      <div
        style={{
          backgroundColor: '#ffffff',
          borderRadius: '16px',
          border: '1px solid var(--border-light)',
          padding: '24px 28px',
          boxShadow: 'var(--shadow-card)',
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'flex-start',
          flexWrap: 'wrap',
          gap: '16px',
          marginBottom: '20px',
        }}
      >
        <div style={{ display: 'flex', gap: '16px', alignItems: 'center' }}>
          <div
            style={{
              width: '64px',
              height: '64px',
              borderRadius: '50%',
              backgroundColor: '#eaf7ee',
              color: '#1e7e45',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              fontSize: '24px',
              fontWeight: '800',
            }}
          >
            {customer.name.slice(0, 2).toUpperCase()}
          </div>

          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
              <h2 style={{ fontSize: '22px', fontWeight: '800', color: '#111827' }}>
                {customer.name}
              </h2>
              <Badge status={customer.status} />
            </div>
            <div style={{ fontSize: '13px', color: '#64748b', marginTop: '2px' }}>
              Customer ID: {customer.id} • Member since {customer.memberSince}
            </div>
            <div style={{ display: 'flex', gap: '14px', marginTop: '6px', fontSize: '12.5px', color: '#475569' }}>
              <span>📞 {customer.phone}</span>
              <span>✉️ {customer.email}</span>
              <span>📍 {customer.address}</span>
            </div>
          </div>
        </div>

        <button
          onClick={() => toggleCustomerBlock(customer.id)}
          style={{
            padding: '8px 16px',
            borderRadius: '8px',
            backgroundColor: customer.status === 'Blocked' ? '#eaf8ef' : '#fef2f2',
            color: customer.status === 'Blocked' ? '#15803d' : '#dc2626',
            border: `1px solid ${customer.status === 'Blocked' ? '#bbf7d0' : '#fecaca'}`,
            fontSize: '13px',
            fontWeight: '600',
          }}
        >
          {customer.status === 'Blocked' ? 'Unblock Customer Account' : 'Block Customer'}
        </button>
      </div>

      {/* Customer Spending Metrics */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: '16px', marginBottom: '20px' }}>
        <div style={{ backgroundColor: '#ffffff', padding: '16px', borderRadius: '12px', border: '1px solid var(--border-light)' }}>
          <div style={{ fontSize: '12px', color: '#64748b' }}>Total Bookings</div>
          <div style={{ fontSize: '20px', fontWeight: '800', color: '#111827', marginTop: '2px' }}>
            {customer.totalBookings} tasks
          </div>
        </div>

        <div style={{ backgroundColor: '#ffffff', padding: '16px', borderRadius: '12px', border: '1px solid var(--border-light)' }}>
          <div style={{ fontSize: '12px', color: '#64748b' }}>Lifetime Spend</div>
          <div style={{ fontSize: '20px', fontWeight: '800', color: '#15803d', marginTop: '2px' }}>
            {customer.totalSpent}
          </div>
        </div>

        <div style={{ backgroundColor: '#ffffff', padding: '16px', borderRadius: '12px', border: '1px solid var(--border-light)' }}>
          <div style={{ fontSize: '12px', color: '#64748b' }}>Average Feedback Rating</div>
          <div style={{ fontSize: '20px', fontWeight: '800', color: '#ca8a04', marginTop: '2px' }}>
            ★ {customer.rating} / 5.0
          </div>
        </div>
      </div>

      {/* Booking History Table */}
      <div style={{ backgroundColor: '#ffffff', borderRadius: '16px', border: '1px solid var(--border-light)', overflow: 'hidden' }}>
        <div style={{ padding: '16px 20px', borderBottom: '1px solid #f1f5f3', fontWeight: '700', fontSize: '15px' }}>
          Booking History for {customer.name} ({customerBookings.length})
        </div>
        <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left' }}>
          <thead>
            <tr style={{ backgroundColor: '#f8faf9', borderBottom: '1px solid #e6ede8', color: '#55695e', fontSize: '12px', fontWeight: '700' }}>
              <th style={{ padding: '12px 18px' }}>Booking ID</th>
              <th style={{ padding: '12px 18px' }}>Service</th>
              <th style={{ padding: '12px 18px' }}>Assigned Worker</th>
              <th style={{ padding: '12px 18px' }}>Amount</th>
              <th style={{ padding: '12px 18px' }}>Status</th>
            </tr>
          </thead>
          <tbody>
            {customerBookings.map((b) => (
              <tr key={b.id} style={{ borderBottom: '1px solid #f1f5f3', fontSize: '13px' }}>
                <td style={{ padding: '12px 18px', color: 'var(--text-link)', fontWeight: '700' }}>{b.id}</td>
                <td style={{ padding: '12px 18px' }}>{b.service}</td>
                <td style={{ padding: '12px 18px' }}>{b.worker}</td>
                <td style={{ padding: '12px 18px', fontWeight: '700' }}>{b.amount}</td>
                <td style={{ padding: '12px 18px' }}><Badge status={b.status} /></td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
