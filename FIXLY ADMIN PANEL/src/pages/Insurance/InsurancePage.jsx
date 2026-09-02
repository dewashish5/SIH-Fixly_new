import React, { useState } from 'react';
import { useApp } from '../../context/AppContext';
import {
  ShieldCheck,
  HeartPulse,
  Umbrella,
  Award,
  Plus,
  Search,
  FileCheck,
  AlertCircle,
  Eye,
  RefreshCw
} from 'lucide-react';
import Badge from '../../components/common/Badge';
import Modal from '../../components/common/Modal';
import { welfarePrograms } from '../../data/insurance';

export default function InsurancePage() {
  const { insurancePolicies = [], welfareClaims = [] } = useApp();

  const policiesList = Array.isArray(insurancePolicies) ? insurancePolicies : [];
  const claimsList = Array.isArray(welfareClaims) ? welfareClaims : [];

  const [activeTab, setActiveTab] = useState('policies'); // 'policies', 'claims', 'welfare'
  const [selectedPolicyForView, setSelectedPolicyForView] = useState(null);
  const [selectedClaimForView, setSelectedClaimForView] = useState(null);

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
            Worker Insurance & Social Welfare Trust
          </h2>
          <p style={{ fontSize: '13px', color: '#64748b' }}>
            Comprehensive accidental coverage, emergency medical reimbursements, upskilling, and social safety nets
          </p>
        </div>
      </div>

      {/* 4 Summary Cards */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '14px', marginBottom: '22px' }}>
        <div style={{ backgroundColor: '#ffffff', padding: '16px', borderRadius: '14px', border: '1px solid var(--border-light)' }}>
          <div style={{ fontSize: '12px', color: '#64748b' }}>Insured Workers</div>
          <div style={{ fontSize: '20px', fontWeight: '800', color: '#15803d', marginTop: '3px' }}>
            0 / 0
          </div>
          <div style={{ fontSize: '11px', color: '#15803d', fontWeight: '600' }}>0% Policy Enrollment</div>
        </div>

        <div style={{ backgroundColor: '#ffffff', padding: '16px', borderRadius: '14px', border: '1px solid var(--border-light)' }}>
          <div style={{ fontSize: '12px', color: '#64748b' }}>Standard Accidental Cover</div>
          <div style={{ fontSize: '20px', fontWeight: '800', color: '#111827', marginTop: '3px' }}>
            ₹5,00,000 / Worker
          </div>
          <div style={{ fontSize: '11px', color: '#64748b' }}>Zero Deductible</div>
        </div>

        <div style={{ backgroundColor: '#ffffff', padding: '16px', borderRadius: '14px', border: '1px solid var(--border-light)' }}>
          <div style={{ fontSize: '12px', color: '#64748b' }}>Settled Welfare Claims</div>
          <div style={{ fontSize: '20px', fontWeight: '800', color: '#0284c7', marginTop: '3px' }}>
            ₹0 (YTD)
          </div>
          <div style={{ fontSize: '11px', color: '#64748b' }}>Avg 48h Disbursal SLA</div>
        </div>

        <div style={{ backgroundColor: '#ffffff', padding: '16px', borderRadius: '14px', border: '1px solid var(--border-light)' }}>
          <div style={{ fontSize: '12px', color: '#64748b' }}>Active Welfare Pool Reserve</div>
          <div style={{ fontSize: '20px', fontWeight: '800', color: '#0f172a', marginTop: '3px' }}>
            ₹0
          </div>
          <div style={{ fontSize: '11px', color: '#64748b' }}>5% Continuous Allocation</div>
        </div>
      </div>

      {/* Tabs */}
      <div style={{ display: 'flex', gap: '8px', borderBottom: '1px solid var(--border-light)', marginBottom: '18px' }}>
        {[
          { key: 'policies', label: `Active Policies (${policiesList.length})` },
          { key: 'claims', label: `Emergency Claims (${claimsList.length})` },
          { key: 'welfare', label: 'Welfare Programs & Health Camps' },
        ].map((t) => (
          <button
            key={t.key}
            onClick={() => setActiveTab(t.key)}
            style={{
              padding: '10px 16px',
              fontSize: '13px',
              fontWeight: activeTab === t.key ? '700' : '500',
              color: activeTab === t.key ? 'var(--primary-brand)' : '#64748b',
              borderBottom: activeTab === t.key ? '2.5px solid var(--primary-brand)' : 'none',
              marginBottom: '-1px',
            }}
          >
            {t.label}
          </button>
        ))}
      </div>

      {/* Tab 1: Policies Table */}
      {activeTab === 'policies' && (
        <div style={{ backgroundColor: '#ffffff', borderRadius: '14px', border: '1px solid var(--border-light)', overflow: 'hidden' }}>
          <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left' }}>
            <thead>
              <tr style={{ backgroundColor: '#f8faf9', borderBottom: '1px solid #e6ede8', color: '#55695e', fontSize: '12px', fontWeight: '700' }}>
                <th style={{ padding: '14px 18px' }}>Worker & Trade</th>
                <th style={{ padding: '14px 18px' }}>Insurance Provider</th>
                <th style={{ padding: '14px 18px' }}>Policy Number</th>
                <th style={{ padding: '14px 18px' }}>Coverage Details</th>
                <th style={{ padding: '14px 18px' }}>Expiry Date</th>
                <th style={{ padding: '14px 18px' }}>Status</th>
                <th style={{ padding: '14px 18px', textAlign: 'right' }}>Actions</th>
              </tr>
            </thead>
            <tbody>
              {policiesList.length === 0 ? (
                <tr>
                  <td colSpan="7" style={{ padding: '30px', textAlign: 'center', color: '#64748b', fontSize: '13px' }}>
                    No active policies found.
                  </td>
                </tr>
              ) : (
                policiesList.map((pol) => (
                  <tr key={pol.id} style={{ borderBottom: '1px solid #f1f5f3', fontSize: '13px' }}>
                    <td style={{ padding: '14px 18px' }}>
                      <div style={{ fontWeight: '700', color: '#1e293b' }}>{pol.worker}</div>
                      <div style={{ fontSize: '11px', color: '#64748b' }}>{pol.service} • ID: {pol.workerId}</div>
                    </td>
                    <td style={{ padding: '14px 18px', color: '#334155' }}>
                      {pol.insuranceProvider}
                    </td>
                    <td style={{ padding: '14px 18px', fontWeight: '700', color: '#0284c7' }}>
                      {pol.policyNumber}
                    </td>
                    <td style={{ padding: '14px 18px', fontWeight: '600', color: '#15803d' }}>
                      {pol.coverage}
                    </td>
                    <td style={{ padding: '14px 18px', color: '#64748b' }}>
                      {pol.expiry}
                    </td>
                    <td style={{ padding: '14px 18px' }}>
                      <Badge status={pol.status} />
                    </td>
                    <td style={{ padding: '14px 18px', textAlign: 'right' }}>
                      <button
                        onClick={() => setSelectedPolicyForView(pol)}
                        style={{
                          padding: '6px 12px',
                          backgroundColor: '#f1f8f3',
                          color: '#15803d',
                          borderRadius: '6px',
                          fontSize: '12px',
                          fontWeight: '600',
                        }}
                      >
                        View Policy
                      </button>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      )}

      {/* Tab 2: Claims Table */}
      {activeTab === 'claims' && (
        <div style={{ backgroundColor: '#ffffff', borderRadius: '14px', border: '1px solid var(--border-light)', overflow: 'hidden' }}>
          <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left' }}>
            <thead>
              <tr style={{ backgroundColor: '#f8faf9', borderBottom: '1px solid #e6ede8', color: '#55695e', fontSize: '12px', fontWeight: '700' }}>
                <th style={{ padding: '14px 18px' }}>Claim ID</th>
                <th style={{ padding: '14px 18px' }}>Worker</th>
                <th style={{ padding: '14px 18px' }}>Incident Description</th>
                <th style={{ padding: '14px 18px' }}>Claim Amount</th>
                <th style={{ padding: '14px 18px' }}>Filed Date</th>
                <th style={{ padding: '14px 18px' }}>Status</th>
                <th style={{ padding: '14px 18px', textAlign: 'right' }}>Actions</th>
              </tr>
            </thead>
            <tbody>
              {claimsList.length === 0 ? (
                <tr>
                  <td colSpan="7" style={{ padding: '30px', textAlign: 'center', color: '#64748b', fontSize: '13px' }}>
                    No claims have been filed yet.
                  </td>
                </tr>
              ) : (
                claimsList.map((c) => (
                  <tr key={c.id} style={{ borderBottom: '1px solid #f1f5f3', fontSize: '13px' }}>
                    <td style={{ padding: '14px 18px', fontWeight: '700', color: '#2563eb' }}>{c.id}</td>
                    <td style={{ padding: '14px 18px', fontWeight: '600', color: '#1e293b' }}>{c.worker}</td>
                    <td style={{ padding: '14px 18px', color: '#475569', maxWidth: '280px' }}>{c.incident}</td>
                    <td style={{ padding: '14px 18px', fontWeight: '700', color: '#15803d' }}>{c.amount}</td>
                    <td style={{ padding: '14px 18px', color: '#64748b' }}>{c.filedDate}</td>
                    <td style={{ padding: '14px 18px' }}><Badge status={c.status.includes('Approved') ? 'Approved' : 'Pending'} /></td>
                    <td style={{ padding: '14px 18px', textAlign: 'right' }}>
                      <button
                        onClick={() => setSelectedClaimForView(c)}
                        style={{
                          padding: '6px 12px',
                          backgroundColor: '#f1f8f3',
                          color: '#15803d',
                          borderRadius: '6px',
                          fontSize: '12px',
                          fontWeight: '600',
                        }}
                      >
                        Audit Proof
                      </button>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      )}

      {/* Tab 3: Welfare Programs */}
      {activeTab === 'welfare' && (
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(320px, 1fr))', gap: '18px' }}>
          {welfarePrograms.map((prog, i) => (
            <div key={i} style={{ backgroundColor: '#ffffff', padding: '22px', borderRadius: '16px', border: '1px solid var(--border-light)', boxShadow: 'var(--shadow-card)' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                <div style={{ width: '38px', height: '38px', borderRadius: '10px', backgroundColor: '#eaf8ef', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#15803d' }}>
                  <HeartPulse size={20} />
                </div>
                <div>
                  <h3 style={{ fontSize: '15px', fontWeight: '700', color: '#111827' }}>{prog.title}</h3>
                  <Badge status="Active" />
                </div>
              </div>

              <p style={{ fontSize: '12.5px', color: '#475569', marginTop: '12px', lineHeight: '1.4' }}>
                {prog.description}
              </p>

              <div style={{ backgroundColor: '#f8faf9', padding: '10px 14px', borderRadius: '8px', marginTop: '14px', fontSize: '12px' }}>
                <div>Enrolled: <strong>{prog.enrolledCount}</strong></div>
                <div style={{ color: '#15803d', fontWeight: '600', marginTop: '2px' }}>Schedule: {prog.nextCampDate}</div>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Policy Details Modal */}
      {selectedPolicyForView && (
        <Modal
          isOpen={!!selectedPolicyForView}
          onClose={() => setSelectedPolicyForView(null)}
          title={`Insurance Policy: ${selectedPolicyForView.policyNumber}`}
          subtitle={`Insured Worker: ${selectedPolicyForView.worker}`}
          maxWidth="520px"
          footer={
            <button
              onClick={() => setSelectedPolicyForView(null)}
              style={{
                padding: '8px 18px',
                backgroundColor: 'var(--primary-brand)',
                color: '#ffffff',
                borderRadius: '8px',
                fontWeight: '600',
              }}
            >
              Close
            </button>
          }
        >
          <div style={{ display: 'flex', flexDirection: 'column', gap: '12px', fontSize: '13px' }}>
            <div><strong>Provider:</strong> {selectedPolicyForView.insuranceProvider}</div>
            <div><strong>Coverage Scope:</strong> {selectedPolicyForView.coverage}</div>
            <div><strong>Premium Funding:</strong> {selectedPolicyForView.premiumMonthly}</div>
            <div><strong>Validity:</strong> {selectedPolicyForView.startDate} to {selectedPolicyForView.expiry}</div>
            <div><strong>Status:</strong> <span style={{ color: '#15803d', fontWeight: '700' }}>{selectedPolicyForView.status}</span></div>
          </div>
        </Modal>
      )}

      {/* Claim Audit Modal */}
      {selectedClaimForView && (
        <Modal
          isOpen={!!selectedClaimForView}
          onClose={() => setSelectedClaimForView(null)}
          title={`Welfare Claim Audit: ${selectedClaimForView.id}`}
          subtitle={`Worker: ${selectedClaimForView.worker}`}
          maxWidth="520px"
          footer={
            <button
              onClick={() => setSelectedClaimForView(null)}
              style={{
                padding: '8px 18px',
                backgroundColor: 'var(--primary-brand)',
                color: '#ffffff',
                borderRadius: '8px',
                fontWeight: '600',
              }}
            >
              Close
            </button>
          }
        >
          <div style={{ display: 'flex', flexDirection: 'column', gap: '12px', fontSize: '13px' }}>
            <div><strong>Incident:</strong> {selectedClaimForView.incident}</div>
            <div><strong>Disbursed Amount:</strong> <span style={{ color: '#15803d', fontWeight: '800' }}>{selectedClaimForView.amount}</span></div>
            <div><strong>Medical Proof:</strong> {selectedClaimForView.documentProof}</div>
            <div><strong>Filed Date:</strong> {selectedClaimForView.filedDate}</div>
            <div><strong>Status:</strong> <span style={{ color: '#15803d', fontWeight: '700' }}>{selectedClaimForView.status}</span></div>
          </div>
        </Modal>
      )}
    </div>
  );
}
