import React from 'react';
import {
  X,
  User,
  Phone,
  MapPin,
  Calendar,
  Clock,
  ShieldCheck,
  CheckCircle,
  CreditCard,
  Download,
  AlertCircle
} from 'lucide-react';

export default function BookingDetailsModal({ booking, isOpen, onClose }) {
  if (!isOpen || !booking) return null;

  return (
    <div
      style={{
        position: 'fixed',
        inset: 0,
        backgroundColor: 'rgba(15, 23, 42, 0.6)',
        backdropFilter: 'blur(4px)',
        zIndex: 70,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        padding: '20px',
        animation: 'fadeIn 0.2s ease',
      }}
    >
      <div
        style={{
          backgroundColor: '#ffffff',
          borderRadius: '20px',
          width: '100%',
          maxWidth: '620px',
          boxShadow: '0 25px 50px -12px rgba(0, 0, 0, 0.25)',
          overflow: 'hidden',
          display: 'flex',
          flexDirection: 'column',
          maxHeight: '85vh',
        }}
      >
        {/* Modal Header */}
        <div
          style={{
            padding: '20px 24px',
            borderBottom: '1px solid var(--border-light)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
            backgroundColor: '#f8faf9',
          }}
        >
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
              <span style={{ fontSize: '18px', fontWeight: '800', color: 'var(--text-link)' }}>
                {booking.id}
              </span>
              <span
                style={{
                  padding: '3px 8px',
                  borderRadius: '999px',
                  fontSize: '11px',
                  fontWeight: '700',
                  backgroundColor: booking.status === 'Confirmed' ? '#eaf8ef' : '#fef8e7',
                  color: booking.status === 'Confirmed' ? '#15803d' : '#d97706',
                }}
              >
                {booking.status}
              </span>
            </div>
            <div style={{ fontSize: '12px', color: '#64748b', marginTop: '2px' }}>
              Created on {booking.date || '26 May, 2025'} • {booking.time || '11:30 AM'}
            </div>
          </div>

          <button
            onClick={onClose}
            style={{
              padding: '8px',
              borderRadius: '50%',
              backgroundColor: '#ffffff',
              color: '#64748b',
              border: '1px solid #e2e8f0',
            }}
          >
            <X size={18} />
          </button>
        </div>

        {/* Modal Body */}
        <div style={{ padding: '24px', overflowY: 'auto', display: 'flex', flexDirection: 'column', gap: '18px' }}>
          {/* Service Banner */}
          <div
            style={{
              backgroundColor: '#f0fdf4',
              borderRadius: '12px',
              border: '1px solid #bbf7d0',
              padding: '14px 16px',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'space-between',
            }}
          >
            <div>
              <div style={{ fontSize: '12px', color: '#15803d', fontWeight: '600' }}>
                Service Category
              </div>
              <div style={{ fontSize: '15px', fontWeight: '700', color: '#14532d' }}>
                {booking.service} — {booking.serviceType || 'Standard On-Demand Service'}
              </div>
            </div>
            <div style={{ textAlign: 'right' }}>
              <div style={{ fontSize: '12px', color: '#64748b' }}>Bill Amount</div>
              <div style={{ fontSize: '18px', fontWeight: '800', color: '#0f172a' }}>
                {booking.amount || '₹850'}
              </div>
            </div>
          </div>

          {/* Customer & Worker Grid */}
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '14px' }}>
            {/* Customer Box */}
            <div
              style={{
                backgroundColor: '#ffffff',
                borderRadius: '12px',
                border: '1px solid #e6ede8',
                padding: '14px',
              }}
            >
              <div style={{ fontSize: '11.5px', fontWeight: '700', color: '#64748b', textTransform: 'uppercase', marginBottom: '8px' }}>
                Customer Details
              </div>
              <div style={{ fontSize: '14px', fontWeight: '700', color: '#1e293b' }}>
                {booking.customer}
              </div>
              <div style={{ fontSize: '12px', color: '#475569', marginTop: '4px', display: 'flex', alignItems: 'center', gap: '4px' }}>
                <Phone size={12} />
                <span>{booking.customerPhone || '+91 98765 43210'}</span>
              </div>
              <div style={{ fontSize: '12px', color: '#64748b', marginTop: '6px', lineHeight: '1.3', display: 'flex', alignItems: 'flex-start', gap: '4px' }}>
                <MapPin size={12} style={{ flexShrink: 0, marginTop: '2px' }} />
                <span>{booking.customerAddress || 'Sector 18, Noida, Uttar Pradesh'}</span>
              </div>
            </div>

            {/* Assigned Worker Box */}
            <div
              style={{
                backgroundColor: '#ffffff',
                borderRadius: '12px',
                border: '1px solid #e6ede8',
                padding: '14px',
              }}
            >
              <div style={{ fontSize: '11.5px', fontWeight: '700', color: '#64748b', textTransform: 'uppercase', marginBottom: '8px' }}>
                Assigned Worker
              </div>
              <div style={{ fontSize: '14px', fontWeight: '700', color: '#1e293b' }}>
                {booking.worker}
              </div>
              <div style={{ fontSize: '12px', color: '#475569', marginTop: '4px', display: 'flex', alignItems: 'center', gap: '4px' }}>
                <Phone size={12} />
                <span>{booking.workerPhone || '+91 91234 56780'}</span>
              </div>
              <div style={{ fontSize: '12px', color: '#15803d', fontWeight: '600', marginTop: '6px', display: 'flex', alignItems: 'center', gap: '4px' }}>
                <ShieldCheck size={13} />
                <span>Cooperative Welfare Insured</span>
              </div>
            </div>
          </div>

          {/* Payment & Security Info */}
          <div
            style={{
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'space-between',
              padding: '12px 16px',
              backgroundColor: '#f8fafc',
              borderRadius: '10px',
              border: '1px solid #e2e8f0',
              fontSize: '12.5px',
            }}
          >
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
              <CreditCard size={16} color="#64748b" />
              <span>Payment: <strong>{booking.paymentStatus || 'Paid (UPI / Cooperative Gateway)'}</strong></span>
            </div>
            <span style={{ color: '#15803d', fontWeight: '600' }}>✓ Escrow Verified</span>
          </div>
        </div>

        {/* Footer Actions */}
        <div
          style={{
            padding: '16px 24px',
            borderTop: '1px solid var(--border-light)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
            backgroundColor: '#ffffff',
          }}
        >
          <button
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '6px',
              padding: '8px 14px',
              borderRadius: '8px',
              border: '1px solid #cbd5e1',
              color: '#334155',
              fontSize: '12.5px',
              fontWeight: '600',
            }}
          >
            <Download size={14} />
            <span>Download Invoice</span>
          </button>

          <div style={{ display: 'flex', gap: '10px' }}>
            <button
              onClick={onClose}
              style={{
                padding: '8px 16px',
                borderRadius: '8px',
                border: '1px solid #e2e8f0',
                fontSize: '12.5px',
                fontWeight: '600',
                color: '#64748b',
              }}
            >
              Close
            </button>
            <button
              onClick={() => {
                alert(`Booking ${booking.id} status updated successfully.`);
                onClose();
              }}
              style={{
                padding: '8px 18px',
                borderRadius: '8px',
                backgroundColor: 'var(--primary-brand)',
                color: '#ffffff',
                fontSize: '12.5px',
                fontWeight: '600',
              }}
            >
              Update Order Status
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
