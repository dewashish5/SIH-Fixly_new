import React, { useState, useEffect } from 'react';
import { useApp } from '../../context/AppContext';
import { api } from '../../services/api';
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
  RefreshCw,
  FileText,
  ExternalLink,
  Trash2,
  Globe,
  Upload,
  CheckCircle2,
  Download,
  Link2,
  Check
} from 'lucide-react';
import Badge from '../../components/common/Badge';
import Modal from '../../components/common/Modal';
import { welfarePrograms } from '../../data/insurance';

export default function InsurancePage() {
  const { insurancePolicies = [], welfareClaims = [], workers = [], dashboardStats } = useApp();

  const policiesList = Array.isArray(insurancePolicies) ? insurancePolicies : [];
  const claimsList = Array.isArray(welfareClaims) ? welfareClaims : [];

  const [activeTab, setActiveTab] = useState('policies'); // 'policies', 'claims', 'welfare', 'resources'
  const [selectedPolicyForView, setSelectedPolicyForView] = useState(null);
  const [selectedClaimForView, setSelectedClaimForView] = useState(null);

  // Welfare Resources (PDFs & Dynamic Links)
  const [welfareResources, setWelfareResources] = useState([]);
  const [loadingResources, setLoadingResources] = useState(false);
  const [showResourceModal, setShowResourceModal] = useState(false);
  const [newResource, setNewResource] = useState({
    title: '',
    type: 'pdf',
    category: 'eshram',
    url: '',
    description: '',
    isActive: true
  });
  const [selectedFile, setSelectedFile] = useState(null);
  const [isUploading, setIsUploading] = useState(false);
  const [previewPdfUrl, setPreviewPdfUrl] = useState(null);
  const [previewPdfTitle, setPreviewPdfTitle] = useState('');

  const fetchResources = async () => {
    try {
      setLoadingResources(true);
      const res = await api.getWelfareResources();
      if (res && res.data) {
        setWelfareResources(res.data);
      } else if (Array.isArray(res)) {
        setWelfareResources(res);
      }
    } catch (err) {
      console.error('Failed to fetch welfare resources:', err);
    } finally {
      setLoadingResources(false);
    }
  };

  useEffect(() => {
    fetchResources();
  }, []);

  useEffect(() => {
    if (activeTab === 'resources') {
      fetchResources();
    }
  }, [activeTab]);

  const handleAddResource = async (e) => {
    e.preventDefault();
    if (!newResource.title.trim()) {
      alert('Please enter a title for the resource');
      return;
    }

    if (newResource.type === 'pdf' && !selectedFile && !newResource.url) {
      alert('Please select a PDF file to upload');
      return;
    }

    if ((newResource.type === 'link' || newResource.type === 'guide') && !newResource.url.trim()) {
      alert('Please enter a valid website URL');
      return;
    }

    try {
      setIsUploading(true);
      let resourceData = { ...newResource };

      if (newResource.type === 'pdf' && selectedFile) {
        const uploadRes = await api.uploadWelfareResourcePdf(selectedFile);
        const uploadedUrl = uploadRes.url || uploadRes.fileUrl;
        if (!uploadedUrl) throw new Error('Upload did not return a valid URL');
        resourceData.url = uploadedUrl;
        resourceData.pdfUrl = uploadedUrl;
        resourceData.fileName = selectedFile.name;
        resourceData.fileSize = `${Math.round(selectedFile.size / 1024)} KB`;
      }

      await api.createWelfareResource(resourceData);
      setShowResourceModal(false);
      setNewResource({ title: '', type: 'pdf', category: 'eshram', url: '', description: '', isActive: true });
      setSelectedFile(null);
      await fetchResources();
    } catch (err) {
      console.error('Failed to create welfare resource:', err);
      const msg = err?.response?.data?.message || err?.message || 'Failed to save resource. Please verify the file and try again.';
      alert(msg);
    } finally {
      setIsUploading(false);
    }
  };

  const handleDeleteResource = async (id) => {
    if (!window.confirm('Are you sure you want to remove this resource? It will be removed from worker mobile apps immediately.')) {
      return;
    }
    try {
      await api.deleteWelfareResource(id);
      await fetchResources();
    } catch (err) {
      console.error('Failed to delete resource:', err);
      alert('Failed to delete resource');
    }
  };

  const handleToggleActive = async (resItem) => {
    try {
      const currentActive = resItem.isActive !== false;
      await api.updateWelfareResource(resItem._id, { isActive: !currentActive });
      await fetchResources();
    } catch (err) {
      console.error('Failed to toggle resource status:', err);
    }
  };


  const insuredCount = workers.filter((w) => w.isVerified || w.verification === 'Verified').length;
  const totalCount = workers.length;
  const enrollPct = totalCount > 0 ? Math.round((insuredCount / totalCount) * 100) : 0;
  const welfarePool = dashboardStats?.totalRevenue ? Math.round(dashboardStats.totalRevenue * 0.05) : 0;

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
            {insuredCount} / {totalCount}
          </div>
          <div style={{ fontSize: '11px', color: '#15803d', fontWeight: '600' }}>{enrollPct}% Policy Enrollment</div>
        </div>

        <div style={{ backgroundColor: '#ffffff', padding: '16px', borderRadius: '14px', border: '1px solid var(--border-light)' }}>
          <div style={{ fontSize: '12px', color: '#64748b' }}>Standard Accidental Cover</div>
          <div style={{ fontSize: '20px', fontWeight: '800', color: '#111827', marginTop: '3px' }}>
            ₹5,00,000 / Member
          </div>
          <div style={{ fontSize: '11px', color: '#64748b' }}>Zero Deductible</div>
        </div>

        <div style={{ backgroundColor: '#ffffff', padding: '16px', borderRadius: '14px', border: '1px solid var(--border-light)' }}>
          <div style={{ fontSize: '12px', color: '#64748b' }}>Settled Welfare Claims</div>
          <div style={{ fontSize: '20px', fontWeight: '800', color: '#0284c7', marginTop: '3px' }}>
            {claimsList.length} Claims
          </div>
          <div style={{ fontSize: '11px', color: '#64748b' }}>Fast 48h Disbursal SLA</div>
        </div>

        <div style={{ backgroundColor: '#ffffff', padding: '16px', borderRadius: '14px', border: '1px solid var(--border-light)' }}>
          <div style={{ fontSize: '12px', color: '#64748b' }}>Active Welfare Pool Reserve</div>
          <div style={{ fontSize: '20px', fontWeight: '800', color: '#0f172a', marginTop: '3px' }}>
            ₹{welfarePool.toLocaleString('en-IN')}
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
          { key: 'resources', label: `e-Shram & Welfare Documents (${welfareResources.length})` },
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


      {/* Tab 4: Welfare Resources (PDFs & Dynamic Links) */}
      {activeTab === 'resources' && (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '22px' }}>
          {/* Header Action Bar */}
          <div
            style={{
              display: 'flex',
              justifyContent: 'space-between',
              alignItems: 'center',
              flexWrap: 'wrap',
              gap: '12px',
              backgroundColor: '#ffffff',
              padding: '18px 22px',
              borderRadius: '16px',
              border: '1px solid var(--border-light)',
              boxShadow: 'var(--shadow-card)',
            }}
          >
            <div>
              <h3 style={{ fontSize: '17px', fontWeight: '700', color: '#111827' }}>
                Worker Welfare Schemes, e-Shram PDFs & Live Webview Portals
              </h3>
              <p style={{ fontSize: '12.5px', color: '#64748b', marginTop: '3px' }}>
                Upload official scheme PDFs and configure dynamic portal URLs that sync directly to the worker mobile app.
              </p>
            </div>
            <div style={{ display: 'flex', gap: '10px' }}>
              <button
                onClick={() => {
                  setNewResource({ title: '', type: 'link', category: 'eshram', url: '', description: '', isActive: true });
                  setSelectedFile(null);
                  setShowResourceModal(true);
                }}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: '6px',
                  padding: '9px 16px',
                  backgroundColor: '#f1f5f9',
                  color: '#334155',
                  borderRadius: '8px',
                  fontSize: '13px',
                  fontWeight: '600',
                  border: '1px solid #cbd5e1',
                  cursor: 'pointer',
                }}
              >
                <Globe size={15} color="#2563eb" />
                <span>+ Add Webview Portal Link</span>
              </button>

              <button
                onClick={() => {
                  setNewResource({ title: '', type: 'pdf', category: 'eshram', url: '', description: '', isActive: true });
                  setSelectedFile(null);
                  setShowResourceModal(true);
                }}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: '6px',
                  padding: '9px 18px',
                  backgroundColor: 'var(--primary-brand)',
                  color: '#ffffff',
                  borderRadius: '8px',
                  fontSize: '13px',
                  fontWeight: '600',
                  border: 'none',
                  cursor: 'pointer',
                  boxShadow: 'var(--shadow-pill)',
                }}
              >
                <Upload size={15} />
                <span>+ Upload Scheme PDF</span>
              </button>
            </div>
          </div>

          {/* Section 1: Dynamic In-App Webview Portals */}
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '12px' }}>
              <Globe size={18} color="#2563eb" />
              <h4 style={{ fontSize: '15px', fontWeight: '700', color: '#1e293b' }}>
                Dynamic In-App Webview Portals ({welfareResources.filter(r => r.type === 'link' || r.type === 'guide').length})
              </h4>
              <span style={{ fontSize: '11px', backgroundColor: '#eff6ff', color: '#1d4ed8', padding: '2px 8px', borderRadius: '12px', fontWeight: '600' }}>
                Live In Mobile App
              </span>
            </div>

            {welfareResources.filter(r => r.type === 'link' || r.type === 'guide').length === 0 ? (
              <div
                style={{
                  backgroundColor: '#ffffff',
                  borderRadius: '14px',
                  border: '1px dashed #cbd5e1',
                  padding: '24px',
                  textAlign: 'center',
                  color: '#64748b',
                  fontSize: '13px',
                }}
              >
                No live webview portals configured yet. Click "+ Add Webview Portal Link" to set up official e-Shram or PMJAY portals.
              </div>
            ) : (
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(320px, 1fr))', gap: '14px' }}>
                {welfareResources
                  .filter(r => r.type === 'link' || r.type === 'guide')
                  .map((resItem) => (
                    <div
                      key={resItem._id}
                      style={{
                        backgroundColor: '#ffffff',
                        borderRadius: '14px',
                        border: '1px solid var(--border-light)',
                        padding: '16px',
                        boxShadow: 'var(--shadow-card)',
                        display: 'flex',
                        flexDirection: 'column',
                        justifyContent: 'space-between',
                      }}
                    >
                      <div>
                        <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', gap: '8px' }}>
                          <div style={{ fontWeight: '700', fontSize: '14px', color: '#1e293b' }}>
                            {resItem.title}
                          </div>
                          <Badge status={resItem.isActive !== false ? 'Active' : 'Inactive'} />
                        </div>

                        {resItem.description && (
                          <div style={{ fontSize: '12px', color: '#64748b', marginTop: '6px' }}>
                            {resItem.description}
                          </div>
                        )}

                        <div style={{ display: 'flex', alignItems: 'center', gap: '6px', marginTop: '10px' }}>
                          <span style={{ fontSize: '11px', textTransform: 'uppercase', padding: '2px 6px', borderRadius: '4px', backgroundColor: '#f1f5f9', color: '#475569', fontWeight: '700' }}>
                            {resItem.category}
                          </span>
                          <span style={{ fontSize: '11px', color: '#0284c7', backgroundColor: '#e0f2fe', padding: '2px 6px', borderRadius: '4px', fontWeight: '600' }}>
                            In-App WebView
                          </span>
                        </div>

                        <div
                          style={{
                            fontSize: '12px',
                            color: '#2563eb',
                            marginTop: '10px',
                            wordBreak: 'break-all',
                            backgroundColor: '#f8fafc',
                            padding: '6px 10px',
                            borderRadius: '6px',
                            border: '1px solid #e2e8f0',
                          }}
                        >
                          <a href={resItem.url} target="_blank" rel="noreferrer" style={{ color: '#2563eb', textDecoration: 'none' }}>
                            {resItem.url}
                          </a>
                        </div>
                      </div>

                      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginTop: '14px', paddingTop: '10px', borderTop: '1px solid #f1f5f9' }}>
                        <a
                          href={resItem.url}
                          target="_blank"
                          rel="noreferrer"
                          style={{
                            display: 'inline-flex',
                            alignItems: 'center',
                            gap: '4px',
                            fontSize: '12px',
                            color: '#15803d',
                            fontWeight: '600',
                            textDecoration: 'none',
                          }}
                        >
                          <ExternalLink size={14} /> Test Link
                        </a>

                        <div style={{ display: 'flex', gap: '6px' }}>
                          <button
                            onClick={() => handleToggleActive(resItem)}
                            style={{
                              padding: '4px 8px',
                              borderRadius: '6px',
                              border: '1px solid #cbd5e1',
                              backgroundColor: '#ffffff',
                              fontSize: '11.5px',
                              cursor: 'pointer',
                              color: resItem.isActive !== false ? '#dc2626' : '#15803d',
                              fontWeight: '600',
                            }}
                          >
                            {resItem.isActive !== false ? 'Deactivate' : 'Activate'}
                          </button>
                          <button
                            onClick={() => handleDeleteResource(resItem._id)}
                            style={{
                              padding: '4px 8px',
                              borderRadius: '6px',
                              border: 'none',
                              backgroundColor: '#fee2e2',
                              color: '#dc2626',
                              fontSize: '11.5px',
                              cursor: 'pointer',
                              fontWeight: '600',
                            }}
                          >
                            <Trash2 size={13} />
                          </button>
                        </div>
                      </div>
                    </div>
                  ))}
              </div>
            )}
          </div>

          {/* Section 2: Uploaded Welfare Scheme PDFs */}
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '12px' }}>
              <FileText size={18} color="#dc2626" />
              <h4 style={{ fontSize: '15px', fontWeight: '700', color: '#1e293b' }}>
                Worker Welfare Scheme Guides & e-Shram PDFs ({welfareResources.filter(r => r.type === 'pdf').length})
              </h4>
              <span style={{ fontSize: '11px', backgroundColor: '#fef2f2', color: '#b91c1c', padding: '2px 8px', borderRadius: '12px', fontWeight: '600' }}>
                PDF Documents
              </span>
            </div>

            <div style={{ backgroundColor: '#ffffff', borderRadius: '14px', border: '1px solid var(--border-light)', overflow: 'hidden', boxShadow: 'var(--shadow-card)' }}>
              <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left' }}>
                <thead>
                  <tr style={{ backgroundColor: '#f8faf9', borderBottom: '1px solid #e6ede8', color: '#55695e', fontSize: '12px', fontWeight: '700' }}>
                    <th style={{ padding: '14px 18px' }}>Document / Scheme Title</th>
                    <th style={{ padding: '14px 18px' }}>Category</th>
                    <th style={{ padding: '14px 18px' }}>Uploaded File</th>
                    <th style={{ padding: '14px 18px' }}>Status</th>
                    <th style={{ padding: '14px 18px', textAlign: 'right' }}>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {welfareResources.filter(r => r.type === 'pdf').length === 0 ? (
                    <tr>
                      <td colSpan="5" style={{ padding: '36px', textAlign: 'center', color: '#64748b', fontSize: '13px' }}>
                        No scheme PDFs uploaded yet. Click "+ Upload Scheme PDF" to add e-Shram guidelines or claim forms.
                      </td>
                    </tr>
                  ) : (
                    welfareResources
                      .filter(r => r.type === 'pdf')
                      .map((resItem) => {
                        const fileUrl = resItem.pdfUrl || resItem.url;
                        return (
                          <tr key={resItem._id} style={{ borderBottom: '1px solid #f1f5f3', fontSize: '13px' }}>
                            <td style={{ padding: '14px 18px' }}>
                              <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                                <div
                                  style={{
                                    width: '36px',
                                    height: '36px',
                                    borderRadius: '8px',
                                    backgroundColor: '#fee2e2',
                                    display: 'flex',
                                    alignItems: 'center',
                                    justifyContent: 'center',
                                    color: '#dc2626',
                                    flexShrink: 0,
                                  }}
                                >
                                  <FileText size={18} />
                                </div>
                                <div>
                                  <div style={{ fontWeight: '700', color: '#1e293b' }}>{resItem.title}</div>
                                  {resItem.description && (
                                    <div style={{ fontSize: '11px', color: '#64748b' }}>{resItem.description}</div>
                                  )}
                                  <div style={{ fontSize: '11px', color: '#94a3b8' }}>
                                    {resItem.createdAt ? new Date(resItem.createdAt).toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' }) : 'Recent'}
                                  </div>
                                </div>
                              </div>
                            </td>

                            <td style={{ padding: '14px 18px' }}>
                              <span
                                style={{
                                  fontSize: '11.5px',
                                  padding: '3px 8px',
                                  borderRadius: '6px',
                                  backgroundColor: '#f1f8f3',
                                  color: '#15803d',
                                  fontWeight: '600',
                                  textTransform: 'uppercase',
                                }}
                              >
                                {resItem.category}
                              </span>
                            </td>

                            <td style={{ padding: '14px 18px' }}>
                              <div style={{ fontSize: '12px', color: '#475569', display: 'flex', alignItems: 'center', gap: '4px' }}>
                                <span>{resItem.fileName || 'Scheme-Guide.pdf'}</span>
                                {resItem.fileSize && (
                                  <span style={{ fontSize: '11px', color: '#94a3b8' }}>({resItem.fileSize})</span>
                                )}
                              </div>
                            </td>

                            <td style={{ padding: '14px 18px' }}>
                              <Badge status={resItem.isActive !== false ? 'Active' : 'Inactive'} />
                            </td>

                            <td style={{ padding: '14px 18px', textAlign: 'right' }}>
                              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'flex-end', gap: '6px' }}>
                                {fileUrl && (
                                  <button
                                    onClick={() => {
                                      setPreviewPdfUrl(fileUrl);
                                      setPreviewPdfTitle(resItem.title);
                                    }}
                                    style={{
                                      display: 'inline-flex',
                                      alignItems: 'center',
                                      gap: '4px',
                                      padding: '6px 12px',
                                      backgroundColor: '#eaf7ee',
                                      color: '#15803d',
                                      borderRadius: '6px',
                                      fontSize: '12px',
                                      fontWeight: '600',
                                      border: 'none',
                                      cursor: 'pointer',
                                    }}
                                  >
                                    <Eye size={13} /> Preview
                                  </button>
                                )}

                                {fileUrl && (
                                  <a
                                    href={fileUrl}
                                    target="_blank"
                                    rel="noreferrer"
                                    download
                                    style={{
                                      display: 'inline-flex',
                                      alignItems: 'center',
                                      gap: '4px',
                                      padding: '6px 10px',
                                      backgroundColor: '#f1f5f9',
                                      color: '#475569',
                                      borderRadius: '6px',
                                      fontSize: '12px',
                                      fontWeight: '600',
                                      textDecoration: 'none',
                                    }}
                                  >
                                    <Download size={13} /> Open
                                  </a>
                                )}

                                <button
                                  onClick={() => handleToggleActive(resItem)}
                                  title={resItem.isActive !== false ? 'Deactivate' : 'Activate'}
                                  style={{
                                    padding: '6px 10px',
                                    borderRadius: '6px',
                                    border: '1px solid #cbd5e1',
                                    backgroundColor: '#ffffff',
                                    fontSize: '11.5px',
                                    cursor: 'pointer',
                                    color: resItem.isActive !== false ? '#dc2626' : '#15803d',
                                    fontWeight: '600',
                                  }}
                                >
                                  {resItem.isActive !== false ? 'Hide' : 'Show'}
                                </button>

                                <button
                                  onClick={() => handleDeleteResource(resItem._id)}
                                  title="Delete Document"
                                  style={{
                                    padding: '6px 10px',
                                    borderRadius: '6px',
                                    border: 'none',
                                    backgroundColor: '#fee2e2',
                                    color: '#dc2626',
                                    cursor: 'pointer',
                                  }}
                                >
                                  <Trash2 size={13} />
                                </button>
                              </div>
                            </td>
                          </tr>
                        );
                      })
                  )}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      )}

      {/* Add Resource Modal (PDF Upload or Portal Link) */}
      {showResourceModal && (
        <Modal
          isOpen={showResourceModal}
          onClose={() => !isUploading && setShowResourceModal(false)}
          title={newResource.type === 'pdf' ? 'Upload Welfare Scheme PDF' : 'Configure Dynamic Webview Portal'}
          subtitle={
            newResource.type === 'pdf'
              ? 'Upload official e-Shram or insurance documents for gig workers'
              : 'Set live official portal URL to be opened in mobile app WebView'
          }
          maxWidth="540px"
        >
          <form onSubmit={handleAddResource} style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
            <div>
              <label style={{ fontSize: '12.5px', fontWeight: '600', color: '#334155', display: 'block', marginBottom: '4px' }}>
                Resource Type *
              </label>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '8px' }}>
                <button
                  type="button"
                  onClick={() => setNewResource({ ...newResource, type: 'pdf' })}
                  style={{
                    padding: '9px 12px',
                    borderRadius: '8px',
                    border: newResource.type === 'pdf' ? '2px solid var(--primary-brand)' : '1px solid #cbd5e1',
                    backgroundColor: newResource.type === 'pdf' ? '#eaf8ef' : '#ffffff',
                    color: newResource.type === 'pdf' ? '#15803d' : '#475569',
                    fontSize: '13px',
                    fontWeight: '700',
                    cursor: 'pointer',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    gap: '6px',
                  }}
                >
                  <FileText size={15} /> PDF Document
                </button>
                <button
                  type="button"
                  onClick={() => setNewResource({ ...newResource, type: 'link' })}
                  style={{
                    padding: '9px 12px',
                    borderRadius: '8px',
                    border: newResource.type === 'link' ? '2px solid #2563eb' : '1px solid #cbd5e1',
                    backgroundColor: newResource.type === 'link' ? '#eff6ff' : '#ffffff',
                    color: newResource.type === 'link' ? '#1d4ed8' : '#475569',
                    fontSize: '13px',
                    fontWeight: '700',
                    cursor: 'pointer',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    gap: '6px',
                  }}
                >
                  <Globe size={15} /> In-App Webview URL
                </button>
              </div>
            </div>

            <div>
              <label style={{ fontSize: '12.5px', fontWeight: '600', color: '#334155', display: 'block', marginBottom: '4px' }}>
                Title *
              </label>
              <input
                type="text"
                required
                placeholder={newResource.type === 'pdf' ? 'e.g. e-Shram Registration Step-by-Step Guide' : 'e.g. e-Shram National Portal'}
                value={newResource.title}
                onChange={(e) => setNewResource({ ...newResource, title: e.target.value })}
                style={{ width: '100%', padding: '8px 12px', border: '1px solid #cbd5e1', borderRadius: '8px', fontSize: '13px' }}
              />
            </div>

            <div>
              <label style={{ fontSize: '12.5px', fontWeight: '600', color: '#334155', display: 'block', marginBottom: '4px' }}>
                Scheme / Welfare Category *
              </label>
              <select
                value={newResource.category}
                onChange={(e) => setNewResource({ ...newResource, category: e.target.value })}
                style={{ width: '100%', padding: '8px 12px', border: '1px solid #cbd5e1', borderRadius: '8px', fontSize: '13px', backgroundColor: '#ffffff' }}
              >
                <option value="eshram">e-Shram Registration & Activation</option>
                <option value="insurance">Accidental & Health Insurance (PM-JAY)</option>
                <option value="government_scheme">Central/State Government Welfare Scheme</option>
                <option value="health_camp">Health Camp & Medical Benefits</option>
                <option value="training">Skills Training & Certification</option>
                <option value="pension">Worker Pension Scheme</option>
              </select>
            </div>

            {newResource.type === 'pdf' ? (
              <div>
                <label style={{ fontSize: '12.5px', fontWeight: '600', color: '#334155', display: 'block', marginBottom: '4px' }}>
                  Upload PDF File *
                </label>
                <div
                  style={{
                    border: '2px dashed #cbd5e1',
                    borderRadius: '10px',
                    padding: '18px',
                    textAlign: 'center',
                    backgroundColor: '#f8fafc',
                    position: 'relative',
                    cursor: 'pointer',
                  }}
                >
                  {selectedFile ? (
                    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '8px' }}>
                      <FileText size={22} color="#dc2626" />
                      <div style={{ textAlign: 'left' }}>
                        <div style={{ fontSize: '13px', fontWeight: '700', color: '#1e293b' }}>{selectedFile.name}</div>
                        <div style={{ fontSize: '11px', color: '#64748b' }}>{Math.round(selectedFile.size / 1024)} KB • Ready to Upload</div>
                      </div>
                    </div>
                  ) : (
                    <div>
                      <Upload size={24} color="#64748b" style={{ marginBottom: '4px' }} />
                      <div style={{ fontSize: '13px', fontWeight: '600', color: '#334155' }}>
                        Click to select PDF document from Desktop
                      </div>
                      <div style={{ fontSize: '11px', color: '#94a3b8', marginTop: '2px' }}>
                        Supports .pdf files up to 15MB
                      </div>
                    </div>
                  )}
                  <input
                    type="file"
                    accept=".pdf,application/pdf"
                    required={!newResource.url}
                    onChange={(e) => setSelectedFile(e.target.files[0])}
                    style={{
                      position: 'absolute',
                      top: 0,
                      left: 0,
                      width: '100%',
                      height: '100%',
                      opacity: 0,
                      cursor: 'pointer',
                    }}
                  />
                </div>
              </div>
            ) : (
              <div>
                <label style={{ fontSize: '12.5px', fontWeight: '600', color: '#334155', display: 'block', marginBottom: '4px' }}>
                  Target Webview URL *
                </label>
                <input
                  type="url"
                  required
                  placeholder="https://eshram.gov.in"
                  value={newResource.url}
                  onChange={(e) => setNewResource({ ...newResource, url: e.target.value })}
                  style={{ width: '100%', padding: '8px 12px', border: '1px solid #cbd5e1', borderRadius: '8px', fontSize: '13px' }}
                />
                <span style={{ fontSize: '11px', color: '#64748b', marginTop: '3px', display: 'block' }}>
                  This URL will open seamlessly in the mobile app when the worker taps this card.
                </span>
              </div>
            )}

            <div>
              <label style={{ fontSize: '12.5px', fontWeight: '600', color: '#334155', display: 'block', marginBottom: '4px' }}>
                Description / Notes (Optional)
              </label>
              <textarea
                rows="2"
                placeholder="Short instructions for workers..."
                value={newResource.description}
                onChange={(e) => setNewResource({ ...newResource, description: e.target.value })}
                style={{ width: '100%', padding: '8px 12px', border: '1px solid #cbd5e1', borderRadius: '8px', fontSize: '13px', fontFamily: 'inherit' }}
              />
            </div>

            <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
              <input
                type="checkbox"
                id="activeStatus"
                checked={newResource.isActive !== false}
                onChange={(e) => setNewResource({ ...newResource, isActive: e.target.checked })}
                style={{ width: '16px', height: '16px', accentColor: '#1e7e45' }}
              />
              <label htmlFor="activeStatus" style={{ fontSize: '13px', fontWeight: '600', color: '#334155', cursor: 'pointer' }}>
                Publish immediately to worker mobile apps
              </label>
            </div>

            <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '10px', marginTop: '8px' }}>
              <button
                type="button"
                disabled={isUploading}
                onClick={() => setShowResourceModal(false)}
                style={{ padding: '8px 16px', borderRadius: '8px', border: '1px solid #cbd5e1', background: '#fff', cursor: 'pointer', fontSize: '13px' }}
              >
                Cancel
              </button>
              <button
                type="submit"
                disabled={isUploading}
                style={{
                  padding: '8px 20px',
                  borderRadius: '8px',
                  border: 'none',
                  background: 'var(--primary-brand)',
                  color: '#fff',
                  cursor: isUploading ? 'not-allowed' : 'pointer',
                  fontWeight: '600',
                  fontSize: '13px',
                }}
              >
                {isUploading ? 'Uploading...' : 'Save & Publish'}
              </button>
            </div>
          </form>
        </Modal>
      )}

      {/* Built-in PDF Preview Modal */}
      {previewPdfUrl && (
        <Modal
          isOpen={Boolean(previewPdfUrl)}
          onClose={() => setPreviewPdfUrl(null)}
          title={`PDF Preview: ${previewPdfTitle}`}
          subtitle="Document Viewer (Embedded View)"
          maxWidth="820px"
          footer={
            <div style={{ display: 'flex', justifyContent: 'space-between', width: '100%', alignItems: 'center' }}>
              <a
                href={previewPdfUrl}
                target="_blank"
                rel="noreferrer"
                style={{
                  display: 'inline-flex',
                  alignItems: 'center',
                  gap: '6px',
                  fontSize: '13px',
                  color: '#2563eb',
                  fontWeight: '600',
                  textDecoration: 'none',
                }}
              >
                <ExternalLink size={14} /> Open in External Browser Window
              </a>
              <button
                onClick={() => setPreviewPdfUrl(null)}
                style={{
                  padding: '8px 18px',
                  backgroundColor: 'var(--primary-brand)',
                  color: '#ffffff',
                  borderRadius: '8px',
                  fontWeight: '600',
                  fontSize: '13px',
                  border: 'none',
                  cursor: 'pointer',
                }}
              >
                Close Preview
              </button>
            </div>
          }
        >
          <div style={{ width: '100%', height: '560px', borderRadius: '8px', overflow: 'hidden', border: '1px solid #cbd5e1' }}>
            <iframe
              src={previewPdfUrl}
              title={previewPdfTitle}
              style={{ width: '100%', height: '100%', border: 'none' }}
            />
          </div>
        </Modal>
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
