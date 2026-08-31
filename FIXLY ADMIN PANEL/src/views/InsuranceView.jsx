import React from 'react';
import {
  ShieldCheck,
  HeartPulse,
  Umbrella,
  AlertCircle,
  CheckCircle2,
  FileText,
  Plus
} from 'lucide-react';

export default function InsuranceView() {
  const claims = [
    {
      id: 'CLM-2025-441',
      worker: 'Suresh Das (Carpentry)',
      incident: 'Minor Hand Injury during door installation',
      amount: '₹25,000',
      status: 'Approved & Disbursed',
      date: '24 May, 2025',
    },
    {
      id: 'CLM-2025-440',
      worker: 'Ravi Verma (Appliance)',
      incident: 'Accidental Tool Damage / Replacement',
      amount: '₹12,500',
      status: 'Under Assessment',
      date: '25 May, 2025',
    },
    {
      id: 'CLM-2025-439',
      worker: 'Sunita Devi (Cleaning)',
      incident: 'Family Emergency Healthcare Support',
      amount: '₹15,000',
      status: 'Approved & Disbursed',
      date: '20 May, 2025',
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
            Worker Insurance & Welfare Pool
          </h2>
          <p style={{ fontSize: '13px', color: '#64748b' }}>
            Comprehensive social security: Accident cover, health insurance, and emergency family safety net
          </p>
        </div>

        <button
          onClick={() => alert('Opening New Claim File Dialog')}
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
          <span>File Emergency Claim</span>
        </button>
      </div>

      {/* Welfare Pool Overview */}
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
          <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
            <div style={{ width: '36px', height: '36px', borderRadius: '8px', backgroundColor: '#eaf8ef', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <ShieldCheck size={20} color="#15803d" />
            </div>
            <div>
              <div style={{ fontSize: '12px', color: '#64748b' }}>Active Insured Workers</div>
              <div style={{ fontSize: '20px', fontWeight: '800', color: '#111827' }}>12,458 / 12,458 (100%)</div>
            </div>
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
          <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
            <div style={{ width: '36px', height: '36px', borderRadius: '8px', backgroundColor: '#eff6ff', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <HeartPulse size={20} color="#2563eb" />
            </div>
            <div>
              <div style={{ fontSize: '12px', color: '#64748b' }}>Accidental Cover Limit</div>
              <div style={{ fontSize: '20px', fontWeight: '800', color: '#111827' }}>₹5,00,000 / Worker</div>
            </div>
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
          <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
            <div style={{ width: '36px', height: '36px', borderRadius: '8px', backgroundColor: '#fef3c7', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <Umbrella size={20} color="#d97706" />
            </div>
            <div>
              <div style={{ fontSize: '12px', color: '#64748b' }}>Settled Claims (YTD)</div>
              <div style={{ fontSize: '20px', fontWeight: '800', color: '#111827' }}>₹18,40,000 (100% SLA)</div>
            </div>
          </div>
        </div>
      </div>

      {/* Claims Table */}
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
          Recent Welfare & Accident Claims
        </div>
        <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left' }}>
          <thead>
            <tr style={{ backgroundColor: '#f8faf9', borderBottom: '1px solid #e6ede8', color: '#55695e', fontSize: '12px', fontWeight: '700' }}>
              <th style={{ padding: '14px 18px' }}>Claim ID</th>
              <th style={{ padding: '14px 18px' }}>Worker</th>
              <th style={{ padding: '14px 18px' }}>Incident Description</th>
              <th style={{ padding: '14px 18px' }}>Disbursed Amount</th>
              <th style={{ padding: '14px 18px' }}>Status</th>
              <th style={{ padding: '14px 18px', textAlign: 'right' }}>Action</th>
            </tr>
          </thead>
          <tbody>
            {claims.map((c) => (
              <tr key={c.id} style={{ borderBottom: '1px solid #f1f5f3', fontSize: '13px' }}>
                <td style={{ padding: '14px 18px', fontWeight: '700', color: '#2563eb' }}>{c.id}</td>
                <td style={{ padding: '14px 18px', fontWeight: '600', color: '#1e293b' }}>{c.worker}</td>
                <td style={{ padding: '14px 18px', color: '#475569' }}>{c.incident}</td>
                <td style={{ padding: '14px 18px', fontWeight: '700', color: '#15803d' }}>{c.amount}</td>
                <td style={{ padding: '14px 18px' }}>
                  <span
                    style={{
                      padding: '4px 10px',
                      borderRadius: '999px',
                      fontSize: '11.5px',
                      fontWeight: '600',
                      backgroundColor: c.status.includes('Approved') ? '#eaf8ef' : '#fef8e7',
                      color: c.status.includes('Approved') ? '#15803d' : '#d97706',
                    }}
                  >
                    {c.status}
                  </span>
                </td>
                <td style={{ padding: '14px 18px', textAlign: 'right' }}>
                  <button
                    style={{
                      padding: '6px 12px',
                      backgroundColor: '#f1f8f3',
                      color: '#15803d',
                      borderRadius: '6px',
                      fontSize: '12px',
                      fontWeight: '600',
                    }}
                  >
                    Audit Report
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
