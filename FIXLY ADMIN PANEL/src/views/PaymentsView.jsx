import React from 'react';
import {
  CreditCard,
  IndianRupee,
  ArrowUpRight,
  ArrowDownLeft,
  Download,
  CheckCircle,
  Clock,
  ShieldCheck
} from 'lucide-react';

export default function PaymentsView() {
  const transactions = [
    {
      id: 'TXN-90214',
      bookingId: 'BK-2025-1021',
      party: 'Ravi Sharma → Mahesh Yadav',
      amount: '₹850.00',
      welfareCut: '₹42.50',
      payout: '₹807.50',
      status: 'Settled (UPI)',
      date: 'Today, 11:35 AM',
    },
    {
      id: 'TXN-90213',
      bookingId: 'BK-2025-1020',
      party: 'Sneha Verma → Arun Kumar',
      amount: '₹1,200.00',
      welfareCut: '₹60.00',
      payout: '₹1,140.00',
      status: 'Escrow Held',
      date: 'Today, 10:18 AM',
    },
    {
      id: 'TXN-90212',
      bookingId: 'BK-2025-1019',
      party: 'Amit Singh → Suresh Das',
      amount: '₹1,650.00',
      welfareCut: '₹82.50',
      payout: '₹1,567.50',
      status: 'Settled (Net Banking)',
      date: 'Today, 09:50 AM',
    },
    {
      id: 'TXN-90211',
      bookingId: 'BK-2025-1018',
      party: 'Pooja Agarwal → Sunita Devi',
      amount: '₹2,499.00',
      welfareCut: '₹124.95',
      payout: '₹2,374.05',
      status: 'Settled (Card)',
      date: 'Yesterday, 04:12 PM',
    },
  ];

  return (
    <div style={{ padding: '0 32px 32px 32px', animation: 'fadeIn 0.2s ease' }}>
      <div
        style={{
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          marginBottom: '20px',
        }}
      >
        <div>
          <h2 style={{ fontSize: '20px', fontWeight: '700', color: '#111827' }}>
            Payments & Cooperative Welfare Treasury
          </h2>
          <p style={{ fontSize: '13px', color: '#64748b' }}>
            Escrow management, instant UPI worker settlements, and welfare pool ledger
          </p>
        </div>

        <button
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: '6px',
            padding: '9px 16px',
            backgroundColor: '#ffffff',
            border: '1px solid var(--border-light)',
            borderRadius: '8px',
            fontSize: '13px',
            fontWeight: '600',
            color: '#334155',
          }}
        >
          <Download size={15} />
          <span>Export Financial Statement</span>
        </button>
      </div>

      {/* Financial Summary Cards */}
      <div
        style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(3, 1fr)',
          gap: '18px',
          marginBottom: '24px',
        }}
      >
        <div
          style={{
            backgroundColor: '#ffffff',
            padding: '20px',
            borderRadius: '16px',
            border: '1px solid var(--border-light)',
          }}
        >
          <div style={{ fontSize: '12.5px', color: '#64748b' }}>Total Processed GTV</div>
          <div style={{ fontSize: '24px', fontWeight: '800', color: '#111827', marginTop: '4px' }}>
            ₹2,45,67,890
          </div>
          <div style={{ fontSize: '12px', color: '#15803d', fontWeight: '600', marginTop: '4px' }}>
            ↑ 15.7% from last month
          </div>
        </div>

        <div
          style={{
            backgroundColor: '#ffffff',
            padding: '20px',
            borderRadius: '16px',
            border: '1px solid var(--border-light)',
          }}
        >
          <div style={{ fontSize: '12.5px', color: '#64748b' }}>Cooperative Welfare Reserve (5%)</div>
          <div style={{ fontSize: '24px', fontWeight: '800', color: '#15803d', marginTop: '4px' }}>
            ₹12,28,394
          </div>
          <div style={{ fontSize: '12px', color: '#64748b', marginTop: '4px' }}>
            Dedicated to worker insurance & pension
          </div>
        </div>

        <div
          style={{
            backgroundColor: '#ffffff',
            padding: '20px',
            borderRadius: '16px',
            border: '1px solid var(--border-light)',
          }}
        >
          <div style={{ fontSize: '12.5px', color: '#64748b' }}>Disbursed to Workers (95%)</div>
          <div style={{ fontSize: '24px', fontWeight: '800', color: '#0f172a', marginTop: '4px' }}>
            ₹2,33,39,496
          </div>
          <div style={{ fontSize: '12px', color: '#15803d', fontWeight: '600', marginTop: '4px' }}>
            Instant direct-to-bank settlement
          </div>
        </div>
      </div>

      {/* Transactions Table */}
      <div
        style={{
          backgroundColor: '#ffffff',
          borderRadius: '14px',
          border: '1px solid var(--border-light)',
          overflow: 'hidden',
          boxShadow: 'var(--shadow-card)',
        }}
      >
        <div style={{ padding: '16px 20px', borderBottom: '1px solid #f1f5f3', fontWeight: '700', fontSize: '15px' }}>
          Recent Transactions & Split Ledger
        </div>
        <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left' }}>
          <thead>
            <tr style={{ backgroundColor: '#f8faf9', borderBottom: '1px solid #e6ede8', color: '#55695e', fontSize: '12px', fontWeight: '700' }}>
              <th style={{ padding: '14px 18px' }}>Transaction ID</th>
              <th style={{ padding: '14px 18px' }}>Parties</th>
              <th style={{ padding: '14px 18px' }}>Total Amount</th>
              <th style={{ padding: '14px 18px' }}>Welfare Split (5%)</th>
              <th style={{ padding: '14px 18px' }}>Worker Net Payout</th>
              <th style={{ padding: '14px 18px' }}>Status</th>
            </tr>
          </thead>
          <tbody>
            {transactions.map((t) => (
              <tr key={t.id} style={{ borderBottom: '1px solid #f1f5f3', fontSize: '13px' }}>
                <td style={{ padding: '14px 18px' }}>
                  <span style={{ fontWeight: '700', color: '#0284c7' }}>{t.id}</span>
                  <div style={{ fontSize: '11px', color: '#94a3b8' }}>{t.date}</div>
                </td>
                <td style={{ padding: '14px 18px', fontWeight: '500', color: '#1e293b' }}>
                  {t.party}
                  <div style={{ fontSize: '11.5px', color: '#64748b' }}>Order: {t.bookingId}</div>
                </td>
                <td style={{ padding: '14px 18px', fontWeight: '700', color: '#0f172a' }}>
                  {t.amount}
                </td>
                <td style={{ padding: '14px 18px', fontWeight: '600', color: '#15803d' }}>
                  {t.welfareCut}
                </td>
                <td style={{ padding: '14px 18px', fontWeight: '700', color: '#1e293b' }}>
                  {t.payout}
                </td>
                <td style={{ padding: '14px 18px' }}>
                  <span
                    style={{
                      padding: '4px 10px',
                      borderRadius: '999px',
                      fontSize: '11.5px',
                      fontWeight: '600',
                      backgroundColor: t.status.includes('Settled') ? '#eaf8ef' : '#fef8e7',
                      color: t.status.includes('Settled') ? '#15803d' : '#d97706',
                    }}
                  >
                    {t.status}
                  </span>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
