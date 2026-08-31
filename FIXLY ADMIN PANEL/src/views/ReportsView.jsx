import React from 'react';
import {
  FileSpreadsheet,
  Download,
  Calendar,
  Filter,
  CheckCircle,
  FileText
} from 'lucide-react';

export default function ReportsView() {
  const reports = [
    {
      title: 'Daily Operations & Booking Reconciliation',
      frequency: 'Daily (26 May, 2025)',
      size: '2.4 MB',
      type: 'CSV / Excel',
    },
    {
      title: 'Cooperative Welfare Fund & Tax Audit',
      frequency: 'Monthly (May 2025)',
      size: '8.1 MB',
      type: 'PDF',
    },
    {
      title: 'Worker Satisfaction & Rating Distribution',
      frequency: 'Weekly',
      size: '1.8 MB',
      type: 'PDF',
    },
    {
      title: 'Escrow Settlements & UPI Payout Breakdown',
      frequency: 'Daily',
      size: '4.2 MB',
      type: 'CSV',
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
            Compliance & Analytical Reports
          </h2>
          <p style={{ fontSize: '13px', color: '#64748b' }}>
            Generate and export official cooperative reports, financial audits, and SLA sheets
          </p>
        </div>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: '18px' }}>
        {reports.map((r, i) => (
          <div
            key={i}
            style={{
              backgroundColor: '#ffffff',
              padding: '22px',
              borderRadius: '16px',
              border: '1px solid var(--border-light)',
              boxShadow: 'var(--shadow-card)',
              display: 'flex',
              flexDirection: 'column',
              justifyContent: 'space-between',
            }}
          >
            <div style={{ display: 'flex', gap: '14px' }}>
              <div
                style={{
                  width: '42px',
                  height: '42px',
                  borderRadius: '10px',
                  backgroundColor: '#eaf8ef',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  color: '#15803d',
                  flexShrink: 0,
                }}
              >
                <FileSpreadsheet size={22} />
              </div>
              <div>
                <h3 style={{ fontSize: '15px', fontWeight: '700', color: '#111827' }}>
                  {r.title}
                </h3>
                <div style={{ fontSize: '12px', color: '#64748b', marginTop: '3px' }}>
                  {r.frequency} • {r.size} • Format: <strong>{r.type}</strong>
                </div>
              </div>
            </div>

            <div style={{ display: 'flex', justifyContent: 'flex-end', marginTop: '16px' }}>
              <button
                onClick={() => alert(`Downloading ${r.title}`)}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: '6px',
                  padding: '8px 14px',
                  backgroundColor: 'var(--primary-brand)',
                  color: '#ffffff',
                  borderRadius: '8px',
                  fontSize: '12.5px',
                  fontWeight: '600',
                }}
              >
                <Download size={14} />
                <span>Download Report</span>
              </button>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
