import React, { useState } from 'react';
import { useApp } from '../../context/AppContext';
import {
  FileSpreadsheet,
  Download,
  Printer,
  Calendar,
  Filter,
  CheckCircle2,
  FileText
} from 'lucide-react';

export default function ReportsPage() {
  const { bookings, workers, customers, services, payments } = useApp();
  const [selectedRange, setSelectedRange] = useState('This Month');
  const [selectedCategory, setSelectedCategory] = useState('All');

  const reportTypes = [
    {
      id: 'bookings',
      title: 'Booking & Dispatch Operations Statement',
      desc: 'Complete log of completed, assigned, in-progress, and emergency service requests.',
      records: bookings.length,
      format: 'CSV / Excel',
      dataGenerator: () =>
        ['ID,Customer,Service,Worker,Amount,Status,Date'].concat(
          bookings.map((b) => `${b.id},${b.customer},${b.service},${b.worker},${b.amount},${b.status},${b.date}`)
        ).join('\n'),
    },
    {
      id: 'revenue',
      title: 'Gross Revenue & Welfare Fund Audit',
      desc: 'Itemized transaction splits: 95% direct worker payout vs 5% social security pool.',
      records: payments.length,
      format: 'CSV / PDF',
      dataGenerator: () =>
        ['TxnID,Customer,Worker,Gross,WelfareSplit,WorkerNet,Status'].concat(
          payments.map((p) => `${p.id},${p.customer},${p.worker},${p.amount},${p.welfareCut},${p.workerPayout},${p.status}`)
        ).join('\n'),
    },
    {
      id: 'workers',
      title: 'Worker Performance & Verification Ledger',
      desc: 'Member roster with skill certifications, ratings, completed tasks, and insurance enrollment.',
      records: workers.length,
      format: 'CSV / Excel',
      dataGenerator: () =>
        ['WorkerID,Name,Service,City,Rating,Jobs,Status'].concat(
          workers.map((w) => `${w.id},${w.name},${w.service},${w.city},${w.rating},${w.completedJobs},${w.verification}`)
        ).join('\n'),
    },
    {
      id: 'customers',
      title: 'Customer Lifetime Booking & Patronage Audit',
      desc: 'Active customer accounts, frequency of service requests, and satisfaction scores.',
      records: customers.length,
      format: 'CSV / Excel',
      dataGenerator: () =>
        ['CustomerID,Name,Phone,Bookings,Spent,Status'].concat(
          customers.map((c) => `${c.id},${c.name},${c.phone},${c.totalBookings},${c.totalSpent},${c.status}`)
        ).join('\n'),
    },
  ];

  const handleExport = (report) => {
    const csvContent = 'data:text/csv;charset=utf-8,' + report.dataGenerator();
    const encodedUri = encodeURI(csvContent);
    const link = document.createElement('a');
    link.setAttribute('href', encodedUri);
    link.setAttribute('download', `${report.id}_report_${selectedRange.replace(' ', '_')}.csv`);
    document.body.appendChild(link);
    link.click();
  };

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
            Compliance & Official Operational Reports
          </h2>
          <p style={{ fontSize: '13px', color: '#64748b' }}>
            Generate, audit, and export official cooperative reports with instant CSV download and printable formats
          </p>
        </div>

        {/* Time filters */}
        <div style={{ display: 'flex', gap: '6px' }}>
          {['Today', 'This Week', 'This Month', 'This Year'].map((r) => (
            <button
              key={r}
              onClick={() => setSelectedRange(r)}
              style={{
                padding: '7px 14px',
                borderRadius: '8px',
                fontSize: '12.5px',
                fontWeight: '600',
                backgroundColor: selectedRange === r ? '#eaf7ee' : '#ffffff',
                color: selectedRange === r ? '#15803d' : '#475569',
                border: `1px solid ${selectedRange === r ? '#86efac' : 'var(--border-light)'}`,
              }}
            >
              {r}
            </button>
          ))}
        </div>
      </div>

      {/* Reports Grid */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: '20px' }}>
        {reportTypes.map((rep) => (
          <div
            key={rep.id}
            style={{
              backgroundColor: '#ffffff',
              borderRadius: '16px',
              border: '1px solid var(--border-light)',
              padding: '24px',
              boxShadow: 'var(--shadow-card)',
              display: 'flex',
              flexDirection: 'column',
              justifyContent: 'space-between',
            }}
          >
            <div>
              <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                <div
                  style={{
                    width: '44px',
                    height: '44px',
                    borderRadius: '12px',
                    backgroundColor: '#eaf7ee',
                    color: '#15803d',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    flexShrink: 0,
                  }}
                >
                  <FileSpreadsheet size={22} />
                </div>
                <div>
                  <h3 style={{ fontSize: '16px', fontWeight: '700', color: '#111827' }}>
                    {rep.title}
                  </h3>
                  <div style={{ fontSize: '12px', color: '#64748b' }}>
                    Timeframe: <strong>{selectedRange}</strong> • {rep.records} Records Analyzed
                  </div>
                </div>
              </div>

              <p style={{ fontSize: '13px', color: '#475569', marginTop: '14px', lineHeight: '1.4' }}>
                {rep.desc}
              </p>

              <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginTop: '14px', fontSize: '12px', color: '#15803d', fontWeight: '600' }}>
                <CheckCircle2 size={15} />
                <span>Audited for Cooperative Bylaws & Regulatory Compliance</span>
              </div>
            </div>

            {/* Actions */}
            <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '10px', marginTop: '20px', borderTop: '1px solid #f1f5f9', paddingTop: '16px' }}>
              <button
                onClick={() => window.print()}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: '6px',
                  padding: '8px 14px',
                  borderRadius: '8px',
                  border: '1px solid #cbd5e1',
                  backgroundColor: '#ffffff',
                  fontSize: '12.5px',
                  fontWeight: '600',
                  color: '#334155',
                }}
              >
                <Printer size={14} />
                <span>Print</span>
              </button>

              <button
                onClick={() => handleExport(rep)}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: '6px',
                  padding: '8px 18px',
                  borderRadius: '8px',
                  backgroundColor: 'var(--primary-brand)',
                  color: '#ffffff',
                  fontSize: '12.5px',
                  fontWeight: '600',
                  boxShadow: 'var(--shadow-pill)',
                }}
              >
                <Download size={14} />
                <span>Export CSV Report</span>
              </button>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
