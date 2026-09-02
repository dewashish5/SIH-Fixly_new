import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useApp } from '../../context/AppContext';
import { api } from '../../services/api';
import {
  ArrowLeft,
  ShieldCheck,
  Star,
  Phone,
  Mail,
  MapPin,
  Award,
  CreditCard,
  CalendarCheck,
  Clock,
  Download,
  Save,
  CheckCircle2,
  XCircle,
  ToggleLeft,
  ToggleRight,
  Briefcase,
  User,
  DollarSign,
  FileText,
  AlertTriangle,
  Eye,
  Camera,
  Upload,
  Image as ImageIcon
} from 'lucide-react';
import Badge from '../../components/common/Badge';

export default function WorkerDetailPage() {
  const { id } = useParams();
  const navigate = useNavigate();
  const { workers, bookings, updateWorker } = useApp();

  const [loadingWorker, setLoadingWorker] = useState(true);
  const [workerData, setWorkerData] = useState(null);
  const [workerBookings, setWorkerBookings] = useState([]);
  const [saving, setSaving] = useState(false);
  const [activeTab, setActiveTab] = useState('edit'); // 'edit', 'documents', 'financials', 'history'

  // Editable Form State
  const [formState, setFormState] = useState({
    name: '',
    email: '',
    phone: '',
    isVerified: false,
    category: 'Plumbing',
    hourlyRate: 500,
    experienceYears: 3,
    bio: '',
    skills: '',
    walletBalance: 0,
    totalEarnings: 0,
    totalJobs: 0,
    rating: 4.9,
    govermentIdType: 'Aadhaar Card',
    govermentIdNumber: '',
    identityProofPhoto: '',
    identityFrontPhoto: '',
    identityBackPhoto: ''
  });

  useEffect(() => {
    let isMounted = true;
    const loadWorkerDetails = async () => {
      setLoadingWorker(true);
      try {
        const res = await api.getWorkerById(id);
        if (res.success && res.worker && isMounted) {
          const w = res.worker;
          setWorkerData(w);

          // Format backend populated bookings
          const backendBookings = Array.isArray(res.bookings) ? res.bookings : [];
          setWorkerBookings(backendBookings);

          setFormState({
            name: w.name || '',
            email: w.email || '',
            phone: w.phone || '',
            isVerified: Boolean(w.isVerified),
            category: w.workerProfile?.category || w.service || 'Plumbing',
            hourlyRate: w.workerProfile?.hourlyRate ?? 500,
            experienceYears: w.workerProfile?.experienceYears ?? 3,
            bio: w.workerProfile?.bio || '',
            skills: Array.isArray(w.workerProfile?.skills)
              ? w.workerProfile.skills.join(', ')
              : (w.skills ? w.skills.join(', ') : 'Plumbing, Installation'),
            walletBalance: w.workerProfile?.walletBalance ?? 0,
            totalEarnings: w.workerProfile?.totalEarnings ?? 0,
            totalJobs: w.workerProfile?.totalJobs ?? backendBookings.length,
            rating: w.workerProfile?.rating ?? 4.9,
            govermentIdType: w.workerProfile?.govermentIdType || 'Aadhaar Card',
            govermentIdNumber: w.workerProfile?.govermentIdNumber || '9874-5612-8492',
            identityProofPhoto: w.workerProfile?.identityProofPhoto || '',
            identityFrontPhoto: w.workerProfile?.identityFrontPhoto || w.workerProfile?.identityProofPhoto || '',
            identityBackPhoto: w.workerProfile?.identityBackPhoto || ''
          });
        }
      } catch (err) {
        console.error('Error fetching worker details by ID:', err);
        // Fallback to Context State
        const found = workers.find((w) => w.id === id || w.rawId === id || w._id === id);
        if (found && isMounted) {
          setWorkerData(found);
          const matchedBookings = bookings.filter((b) => b && (b.workerId === found._id || b.workerId === found.id || b.worker === found.name));
          setWorkerBookings(matchedBookings);

          setFormState({
            name: found.name || '',
            email: found.email || '',
            phone: found.phone || '',
            isVerified: found.verification === 'Verified' || Boolean(found.isVerified),
            category: found.service || found.category || 'Plumbing',
            hourlyRate: 500,
            experienceYears: 3,
            bio: found.bio || '',
            skills: Array.isArray(found.skills) ? found.skills.join(', ') : 'Plumbing, Leakage Repair',
            walletBalance: 0,
            totalEarnings: 0,
            totalJobs: found.completedTasks || matchedBookings.length,
            rating: found.rating || 4.9,
            govermentIdType: 'Aadhaar Card',
            govermentIdNumber: '9874-5612-8492',
            identityProofPhoto: '',
            identityFrontPhoto: '',
            identityBackPhoto: ''
          });
        }
      } finally {
        if (isMounted) setLoadingWorker(false);
      }
    };

    loadWorkerDetails();
    return () => {
      isMounted = false;
    };
  }, [id, workers, bookings]);

  // Handle Quick ON/OFF Verification Toggle
  const handleToggleVerification = async () => {
    const newStatus = !formState.isVerified;
    setFormState((prev) => ({ ...prev, isVerified: newStatus }));
    try {
      await updateWorker(id, {
        isVerified: newStatus,
        email: formState.email
      });
    } catch (err) {
      setFormState((prev) => ({ ...prev, isVerified: !newStatus }));
    }
  };

  // Handle Profile Save
  const handleSaveProfile = async (e) => {
    e.preventDefault();
    setSaving(true);
    try {
      const res = await updateWorker(id, {
        name: formState.name,
        email: formState.email,
        phone: formState.phone,
        isVerified: formState.isVerified,
        category: formState.category,
        hourlyRate: Number(formState.hourlyRate),
        experienceYears: Number(formState.experienceYears),
        bio: formState.bio,
        skills: formState.skills.split(',').map((s) => s.trim()).filter(Boolean),
        walletBalance: Number(formState.walletBalance),
        totalEarnings: Number(formState.totalEarnings),
        totalJobs: Number(formState.totalJobs),
        rating: Number(formState.rating),
        govermentIdType: formState.govermentIdType,
        govermentIdNumber: formState.govermentIdNumber,
        identityProofPhoto: formState.identityProofPhoto || formState.identityFrontPhoto,
        identityFrontPhoto: formState.identityFrontPhoto,
        identityBackPhoto: formState.identityBackPhoto
      });
      if (res && res.worker) {
        setWorkerData(res.worker);
      }
    } catch (err) {
      console.error('Save worker error:', err);
    } finally {
      setSaving(false);
    }
  };

  const currentWorker = workerData || {};
  const currentCategory = formState.category || 'Plumbing';
  const currentVerified = formState.isVerified;
  const hasDocs = Boolean(formState.identityFrontPhoto || formState.identityProofPhoto);

  return (
    <div style={{ padding: '0 32px 32px 32px', animation: 'fadeIn 0.2s ease', maxWidth: '1100px' }}>
      {/* Back button */}
      <button
        onClick={() => navigate('/workers')}
        style={{
          display: 'flex',
          alignItems: 'center',
          gap: '6px',
          padding: '6px 14px',
          borderRadius: '8px',
          backgroundColor: '#ffffff',
          border: '1px solid var(--border-light)',
          color: '#475569',
          fontSize: '13px',
          fontWeight: '600',
          marginBottom: '18px',
          cursor: 'pointer'
        }}
      >
        <ArrowLeft size={15} />
        <span>Back to Workers Directory</span>
      </button>

      {/* Main Profile Header & ON/OFF Verification Bar */}
      <div
        style={{
          backgroundColor: '#ffffff',
          borderRadius: '16px',
          border: '1px solid var(--border-light)',
          padding: '24px 28px',
          boxShadow: 'var(--shadow-card)',
          marginBottom: '20px',
        }}
      >
        <div
          style={{
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center',
            flexWrap: 'wrap',
            gap: '20px',
          }}
        >
          <div style={{ display: 'flex', gap: '20px', alignItems: 'center' }}>
            <img
              src={currentWorker.avatar || `https://images.unsplash.com/photo-1540569014015-19a7be504e3a?w=150&auto=format&fit=crop&q=80`}
              alt={formState.name}
              style={{
                width: '80px',
                height: '80px',
                borderRadius: '50%',
                objectFit: 'cover',
                border: `3.5px solid ${currentVerified ? '#15803d' : '#94a3b8'}`,
                boxShadow: currentVerified ? '0 4px 12px rgba(21, 128, 61, 0.25)' : 'none',
              }}
            />

            <div>
              <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                <h2 style={{ fontSize: '22px', fontWeight: '800', color: '#111827' }}>
                  {formState.name || 'Worker Member'}
                </h2>
                <Badge status={currentVerified ? 'Verified' : 'Pending Review'} />
              </div>

              <div style={{ fontSize: '13.5px', fontWeight: '700', color: '#15803d', marginTop: '2px' }}>
                {currentCategory} Professional • Member #{currentWorker._id || id}
              </div>

              <div style={{ display: 'flex', gap: '16px', marginTop: '8px', fontSize: '12.5px', color: '#64748b', flexWrap: 'wrap' }}>
                <span style={{ display: 'flex', alignItems: 'center', gap: '4px' }}>
                  <Phone size={13} /> {formState.phone || '+91 98765 43210'}
                </span>
                <span style={{ display: 'flex', alignItems: 'center', gap: '4px' }}>
                  <Mail size={13} /> {formState.email || 'worker@cooperative.org'}
                </span>
              </div>
            </div>
          </div>

          {/* Quick Verification ON/OFF Toggle Control */}
          <div
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '14px',
              backgroundColor: currentVerified ? '#f0fdf4' : '#fffbe0',
              padding: '12px 18px',
              borderRadius: '12px',
              border: `1.5px solid ${currentVerified ? '#bbf7d0' : '#fef08a'}`,
            }}
          >
            <div>
              <div style={{ fontSize: '12px', fontWeight: '700', color: currentVerified ? '#15803d' : '#b45309' }}>
                VERIFICATION STATUS
              </div>
              <div style={{ fontSize: '13px', fontWeight: '800', color: currentVerified ? '#166534' : '#92400e' }}>
                {currentVerified ? '✅ VERIFIED MEMBER' : '⚠️ UNVERIFIED / PENDING'}
              </div>
            </div>

            <button
              type="button"
              onClick={handleToggleVerification}
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: '6px',
                padding: '8px 16px',
                borderRadius: '8px',
                backgroundColor: currentVerified ? '#15803d' : '#ca8a04',
                color: '#ffffff',
                border: 'none',
                fontSize: '13px',
                fontWeight: '700',
                cursor: 'pointer',
                boxShadow: '0 2px 6px rgba(0,0,0,0.1)'
              }}
              title="Click to Toggle Verification Status ON/OFF"
            >
              {currentVerified ? <ToggleRight size={18} /> : <ToggleLeft size={18} />}
              <span>{currentVerified ? 'Turn OFF (Unverify)' : 'Turn ON (Verify Member)'}</span>
            </button>
          </div>
        </div>
      </div>

      {/* Tabs Header */}
      <div style={{ display: 'flex', gap: '8px', borderBottom: '1px solid var(--border-light)', marginBottom: '20px' }}>
        {[
          { key: 'edit', label: '✏️ Edit Profile & Trade Details', icon: User },
          { key: 'documents', label: '📑 Identity & Document Verification', icon: FileText },
          { key: 'financials', label: '💳 Wallet & Financials', icon: DollarSign },
          { key: 'history', label: `📋 Job History (${workerBookings.length})`, icon: Briefcase },
        ].map((tab) => {
          const isActive = activeTab === tab.key;
          return (
            <button
              key={tab.key}
              type="button"
              onClick={() => setActiveTab(tab.key)}
              style={{
                padding: '10px 18px',
                fontSize: '13.5px',
                fontWeight: isActive ? '700' : '500',
                color: isActive ? '#15803d' : '#64748b',
                borderBottom: isActive ? '2.5px solid #15803d' : 'none',
                backgroundColor: 'transparent',
                border: 'none',
                cursor: 'pointer',
                marginBottom: '-1px',
              }}
            >
              {tab.label}
            </button>
          );
        })}
      </div>

      {/* TAB 1: EDIT PROFILE FORM */}
      {activeTab === 'edit' && (
        <form onSubmit={handleSaveProfile} style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
          {/* Section 1: Basic Credentials */}
          <div style={{ backgroundColor: '#ffffff', padding: '22px', borderRadius: '16px', border: '1px solid var(--border-light)' }}>
            <h3 style={{ fontSize: '15px', fontWeight: '700', color: '#111827', marginBottom: '16px' }}>
              Basic Member Information
            </h3>

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '16px' }}>
              <div>
                <label style={{ fontSize: '12px', fontWeight: '600', color: '#475569', display: 'block', marginBottom: '6px' }}>
                  Full Name
                </label>
                <input
                  type="text"
                  value={formState.name}
                  onChange={(e) => setFormState({ ...formState, name: e.target.value })}
                  required
                  style={{ width: '100%', padding: '9px 12px', borderRadius: '8px', border: '1px solid #cbd5e1', fontSize: '13px' }}
                />
              </div>

              <div>
                <label style={{ fontSize: '12px', fontWeight: '600', color: '#475569', display: 'block', marginBottom: '6px' }}>
                  Email Address
                </label>
                <input
                  type="email"
                  value={formState.email}
                  onChange={(e) => setFormState({ ...formState, email: e.target.value })}
                  required
                  style={{ width: '100%', padding: '9px 12px', borderRadius: '8px', border: '1px solid #cbd5e1', fontSize: '13px' }}
                />
              </div>

              <div>
                <label style={{ fontSize: '12px', fontWeight: '600', color: '#475569', display: 'block', marginBottom: '6px' }}>
                  Phone Number
                </label>
                <input
                  type="text"
                  value={formState.phone}
                  onChange={(e) => setFormState({ ...formState, phone: e.target.value })}
                  style={{ width: '100%', padding: '9px 12px', borderRadius: '8px', border: '1px solid #cbd5e1', fontSize: '13px' }}
                />
              </div>
            </div>
          </div>

          {/* Section 2: Trade & Skills Configuration */}
          <div style={{ backgroundColor: '#ffffff', padding: '22px', borderRadius: '16px', border: '1px solid var(--border-light)' }}>
            <h3 style={{ fontSize: '15px', fontWeight: '700', color: '#111827', marginBottom: '16px' }}>
              Trade, Skills & Pricing Configuration
            </h3>

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '16px', marginBottom: '16px' }}>
              <div>
                <label style={{ fontSize: '12px', fontWeight: '600', color: '#475569', display: 'block', marginBottom: '6px' }}>
                  Primary Service Trade
                </label>
                <select
                  value={formState.category}
                  onChange={(e) => setFormState({ ...formState, category: e.target.value })}
                  style={{ width: '100%', padding: '9px 12px', borderRadius: '8px', border: '1px solid #cbd5e1', fontSize: '13px', backgroundColor: '#ffffff' }}
                >
                  <option value="Plumbing">Plumbing</option>
                  <option value="Electrical">Electrical</option>
                  <option value="Carpentry">Carpentry</option>
                  <option value="Cleaning">Cleaning</option>
                  <option value="AC Repair">AC Repair</option>
                  <option value="Caregiving">Caregiving</option>
                  <option value="Painting">Painting</option>
                  <option value="Driving">Driving</option>
                  <option value="General">General Trade</option>
                </select>
              </div>

              <div>
                <label style={{ fontSize: '12px', fontWeight: '600', color: '#475569', display: 'block', marginBottom: '6px' }}>
                  Hourly Benchmark Rate (₹/hr)
                </label>
                <input
                  type="number"
                  value={formState.hourlyRate}
                  onChange={(e) => setFormState({ ...formState, hourlyRate: e.target.value })}
                  style={{ width: '100%', padding: '9px 12px', borderRadius: '8px', border: '1px solid #cbd5e1', fontSize: '13px' }}
                />
              </div>

              <div>
                <label style={{ fontSize: '12px', fontWeight: '600', color: '#475569', display: 'block', marginBottom: '6px' }}>
                  Experience (Years)
                </label>
                <input
                  type="number"
                  value={formState.experienceYears}
                  onChange={(e) => setFormState({ ...formState, experienceYears: e.target.value })}
                  style={{ width: '100%', padding: '9px 12px', borderRadius: '8px', border: '1px solid #cbd5e1', fontSize: '13px' }}
                />
              </div>
            </div>

            <div style={{ marginBottom: '16px' }}>
              <label style={{ fontSize: '12px', fontWeight: '600', color: '#475569', display: 'block', marginBottom: '6px' }}>
                Specific Skills (Comma Separated)
              </label>
              <input
                type="text"
                value={formState.skills}
                onChange={(e) => setFormState({ ...formState, skills: e.target.value })}
                placeholder="e.g. Pipe Fitting, Bathroom Fitting, Leak Detection, Geyser Installation"
                style={{ width: '100%', padding: '9px 12px', borderRadius: '8px', border: '1px solid #cbd5e1', fontSize: '13px' }}
              />
            </div>

            <div>
              <label style={{ fontSize: '12px', fontWeight: '600', color: '#475569', display: 'block', marginBottom: '6px' }}>
                Operational Bio & Summary
              </label>
              <textarea
                value={formState.bio}
                onChange={(e) => setFormState({ ...formState, bio: e.target.value })}
                rows="3"
                placeholder="Brief professional profile and experience summary..."
                style={{ width: '100%', padding: '9px 12px', borderRadius: '8px', border: '1px solid #cbd5e1', fontSize: '13px', fontFamily: 'inherit' }}
              />
            </div>
          </div>

          {/* Save Button */}
          <div style={{ display: 'flex', justifyContent: 'flex-end', marginTop: '10px' }}>
            <button
              type="submit"
              disabled={saving}
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: '8px',
                padding: '12px 28px',
                backgroundColor: '#15803d',
                color: '#ffffff',
                borderRadius: '10px',
                fontSize: '14px',
                fontWeight: '700',
                border: 'none',
                cursor: 'pointer',
                boxShadow: '0 4px 12px rgba(21, 128, 61, 0.25)',
              }}
            >
              <Save size={16} />
              <span>{saving ? 'Saving Edits...' : 'Save Worker Profile Changes'}</span>
            </button>
          </div>
        </form>
      )}

      {/* TAB 2: IDENTITY DOCUMENT VERIFICATION (FRONT & BACK PHOTOS SUPPORT) */}
      {activeTab === 'documents' && (
        <form onSubmit={handleSaveProfile} style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
          <div style={{ backgroundColor: '#ffffff', padding: '22px', borderRadius: '16px', border: '1px solid var(--border-light)' }}>
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '16px' }}>
              <div>
                <h3 style={{ fontSize: '15px', fontWeight: '700', color: '#111827' }}>
                  Government Identity Proof & Multiple Documents Status
                </h3>
                <p style={{ fontSize: '12.5px', color: '#64748b', marginTop: '2px' }}>
                  Verify official ID proof uploaded by the worker (Aadhaar Card, PAN Card, Driving License - Front & Back Photos).
                </p>
              </div>

              <div
                style={{
                  padding: '6px 12px',
                  borderRadius: '8px',
                  backgroundColor: hasDocs ? '#eaf8ef' : '#fff1f2',
                  color: hasDocs ? '#15803d' : '#e11d48',
                  fontSize: '12px',
                  fontWeight: '700',
                  border: `1px solid ${hasDocs ? '#bbf7d0' : '#fecdd3'}`,
                }}
              >
                {hasDocs ? '✅ Documents Uploaded' : '⚠️ Identity Proof Not Uploaded'}
              </div>
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px', marginBottom: '20px' }}>
              <div>
                <label style={{ fontSize: '12px', fontWeight: '600', color: '#475569', display: 'block', marginBottom: '6px' }}>
                  Government ID Type
                </label>
                <select
                  value={formState.govermentIdType}
                  onChange={(e) => setFormState({ ...formState, govermentIdType: e.target.value })}
                  style={{ width: '100%', padding: '9px 12px', borderRadius: '8px', border: '1px solid #cbd5e1', fontSize: '13px', backgroundColor: '#ffffff' }}
                >
                  <option value="Aadhaar Card">Aadhaar Card</option>
                  <option value="Driving License">Driving License</option>
                  <option value="PAN Card">PAN Card</option>
                  <option value="Voter ID">Voter ID</option>
                  <option value="Passport">Passport</option>
                </select>
              </div>

              <div>
                <label style={{ fontSize: '12px', fontWeight: '600', color: '#475569', display: 'block', marginBottom: '6px' }}>
                  Government Unique ID Number
                </label>
                <input
                  type="text"
                  value={formState.govermentIdNumber}
                  onChange={(e) => setFormState({ ...formState, govermentIdNumber: e.target.value })}
                  placeholder="e.g. 9874-5612-8492 or ABCDE1234F"
                  style={{ width: '100%', padding: '9px 12px', borderRadius: '8px', border: '1px solid #cbd5e1', fontSize: '13px' }}
                />
              </div>
            </div>

            {/* Front Photo & Back Photo Side-by-Side Cards */}
            <div style={{ marginTop: '10px' }}>
              <label style={{ fontSize: '13px', fontWeight: '700', color: '#1e293b', display: 'block', marginBottom: '12px' }}>
                Identity Proof Photos (Front Side & Back Side Preview)
              </label>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '20px' }}>
                {/* Front Side Document Card */}
                <div style={{ backgroundColor: '#f8fafc', padding: '16px', borderRadius: '12px', border: '1px solid #e2e8f0' }}>
                  <div style={{ fontSize: '13px', fontWeight: '700', color: '#0f172a', marginBottom: '8px', display: 'flex', alignItems: 'center', gap: '6px' }}>
                    <ImageIcon size={16} color="#15803d" />
                    <span>Front Side Photo ({formState.govermentIdType})</span>
                  </div>

                  {formState.identityFrontPhoto || formState.identityProofPhoto ? (
                    <div>
                      <img
                        src={formState.identityFrontPhoto || formState.identityProofPhoto}
                        alt="Front Side Doc"
                        style={{ width: '100%', height: '140px', objectFit: 'cover', borderRadius: '8px', border: '1px solid #cbd5e1', marginBottom: '8px' }}
                      />
                      <a
                        href={formState.identityFrontPhoto || formState.identityProofPhoto}
                        target="_blank"
                        rel="noreferrer"
                        style={{ fontSize: '12px', fontWeight: '700', color: '#2563eb', textDecoration: 'none', display: 'inline-flex', alignItems: 'center', gap: '4px' }}
                      >
                        <Eye size={14} /> <span>View Full Resolution Front Photo</span>
                      </a>
                    </div>
                  ) : (
                    <div style={{ backgroundColor: '#fff1f2', border: '1px dashed #fda4af', padding: '20px', borderRadius: '8px', textAlign: 'center', color: '#be123c', fontSize: '12px' }}>
                      <AlertTriangle size={24} color="#e11d48" style={{ margin: '0 auto 4px auto', display: 'block' }} />
                      <strong>Front Side Photo Not Uploaded</strong>
                    </div>
                  )}

                  <div style={{ marginTop: '12px' }}>
                    <label style={{ fontSize: '11.5px', fontWeight: '600', color: '#475569', display: 'block', marginBottom: '4px' }}>
                      Front Photo Image URL
                    </label>
                    <input
                      type="text"
                      value={formState.identityFrontPhoto}
                      onChange={(e) => setFormState({ ...formState, identityFrontPhoto: e.target.value })}
                      placeholder="https://example.com/aadhaar-front.jpg"
                      style={{ width: '100%', padding: '7px 10px', borderRadius: '6px', border: '1px solid #cbd5e1', fontSize: '12px' }}
                    />
                  </div>
                </div>

                {/* Back Side Document Card */}
                <div style={{ backgroundColor: '#f8fafc', padding: '16px', borderRadius: '12px', border: '1px solid #e2e8f0' }}>
                  <div style={{ fontSize: '13px', fontWeight: '700', color: '#0f172a', marginBottom: '8px', display: 'flex', alignItems: 'center', gap: '6px' }}>
                    <ImageIcon size={16} color="#15803d" />
                    <span>Back Side Photo ({formState.govermentIdType})</span>
                  </div>

                  {formState.identityBackPhoto ? (
                    <div>
                      <img
                        src={formState.identityBackPhoto}
                        alt="Back Side Doc"
                        style={{ width: '100%', height: '140px', objectFit: 'cover', borderRadius: '8px', border: '1px solid #cbd5e1', marginBottom: '8px' }}
                      />
                      <a
                        href={formState.identityBackPhoto}
                        target="_blank"
                        rel="noreferrer"
                        style={{ fontSize: '12px', fontWeight: '700', color: '#2563eb', textDecoration: 'none', display: 'inline-flex', alignItems: 'center', gap: '4px' }}
                      >
                        <Eye size={14} /> <span>View Full Resolution Back Photo</span>
                      </a>
                    </div>
                  ) : (
                    <div style={{ backgroundColor: '#fff1f2', border: '1px dashed #fda4af', padding: '20px', borderRadius: '8px', textAlign: 'center', color: '#be123c', fontSize: '12px' }}>
                      <AlertTriangle size={24} color="#e11d48" style={{ margin: '0 auto 4px auto', display: 'block' }} />
                      <strong>Back Side Photo Not Uploaded</strong>
                    </div>
                  )}

                  <div style={{ marginTop: '12px' }}>
                    <label style={{ fontSize: '11.5px', fontWeight: '600', color: '#475569', display: 'block', marginBottom: '4px' }}>
                      Back Photo Image URL
                    </label>
                    <input
                      type="text"
                      value={formState.identityBackPhoto}
                      onChange={(e) => setFormState({ ...formState, identityBackPhoto: e.target.value })}
                      placeholder="https://example.com/aadhaar-back.jpg"
                      style={{ width: '100%', padding: '7px 10px', borderRadius: '6px', border: '1px solid #cbd5e1', fontSize: '12px' }}
                    />
                  </div>
                </div>
              </div>
            </div>
          </div>

          <div style={{ display: 'flex', justifyContent: 'flex-end' }}>
            <button
              type="submit"
              disabled={saving}
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: '8px',
                padding: '12px 28px',
                backgroundColor: '#15803d',
                color: '#ffffff',
                borderRadius: '10px',
                fontSize: '14px',
                fontWeight: '700',
                border: 'none',
                cursor: 'pointer',
              }}
            >
              <Save size={16} />
              <span>{saving ? 'Saving Documents...' : 'Save All Document Settings'}</span>
            </button>
          </div>
        </form>
      )}

      {/* TAB 3: FINANCIALS & WALLET */}
      {activeTab === 'financials' && (
        <form onSubmit={handleSaveProfile} style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
          <div style={{ backgroundColor: '#ffffff', padding: '22px', borderRadius: '16px', border: '1px solid var(--border-light)' }}>
            <h3 style={{ fontSize: '15px', fontWeight: '700', color: '#111827', marginBottom: '16px' }}>
              Worker Wallet & Financial Ledger Balance
            </h3>

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '16px' }}>
              <div>
                <label style={{ fontSize: '12px', fontWeight: '600', color: '#475569', display: 'block', marginBottom: '6px' }}>
                  Wallet Balance (₹)
                </label>
                <input
                  type="number"
                  value={formState.walletBalance}
                  onChange={(e) => setFormState({ ...formState, walletBalance: e.target.value })}
                  style={{ width: '100%', padding: '9px 12px', borderRadius: '8px', border: '1px solid #cbd5e1', fontSize: '14px', fontWeight: '700', color: '#15803d' }}
                />
              </div>

              <div>
                <label style={{ fontSize: '12px', fontWeight: '600', color: '#475569', display: 'block', marginBottom: '6px' }}>
                  Total Lifetime Earnings (₹)
                </label>
                <input
                  type="number"
                  value={formState.totalEarnings}
                  onChange={(e) => setFormState({ ...formState, totalEarnings: e.target.value })}
                  style={{ width: '100%', padding: '9px 12px', borderRadius: '8px', border: '1px solid #cbd5e1', fontSize: '14px', fontWeight: '700', color: '#0f172a' }}
                />
              </div>

              <div>
                <label style={{ fontSize: '12px', fontWeight: '600', color: '#475569', display: 'block', marginBottom: '6px' }}>
                  Total Jobs Completed
                </label>
                <input
                  type="number"
                  value={formState.totalJobs}
                  onChange={(e) => setFormState({ ...formState, totalJobs: e.target.value })}
                  style={{ width: '100%', padding: '9px 12px', borderRadius: '8px', border: '1px solid #cbd5e1', fontSize: '14px', fontWeight: '700' }}
                />
              </div>
            </div>
          </div>

          <div style={{ display: 'flex', justifyContent: 'flex-end' }}>
            <button
              type="submit"
              disabled={saving}
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: '8px',
                padding: '12px 28px',
                backgroundColor: '#15803d',
                color: '#ffffff',
                borderRadius: '10px',
                fontSize: '14px',
                fontWeight: '700',
                border: 'none',
                cursor: 'pointer',
              }}
            >
              <Save size={16} />
              <span>{saving ? 'Updating Wallet...' : 'Update Wallet & Earnings'}</span>
            </button>
          </div>
        </form>
      )}

      {/* TAB 4: JOB ASSIGNMENT HISTORY */}
      {activeTab === 'history' && (
        <div style={{ backgroundColor: '#ffffff', borderRadius: '16px', border: '1px solid var(--border-light)', overflow: 'hidden' }}>
          <div style={{ padding: '16px 20px', borderBottom: '1px solid #f1f5f3', fontWeight: '700', fontSize: '15px' }}>
            Recent Job Assignments for {formState.name} ({workerBookings.length})
          </div>
          <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left' }}>
            <thead>
              <tr style={{ backgroundColor: '#f8faf9', borderBottom: '1px solid #e6ede8', color: '#55695e', fontSize: '12px', fontWeight: '700' }}>
                <th style={{ padding: '12px 18px' }}>Booking ID</th>
                <th style={{ padding: '12px 18px' }}>Customer</th>
                <th style={{ padding: '12px 18px' }}>Service</th>
                <th style={{ padding: '12px 18px' }}>Amount</th>
                <th style={{ padding: '12px 18px' }}>Status</th>
              </tr>
            </thead>
            <tbody>
              {workerBookings.length === 0 ? (
                <tr>
                  <td colSpan="5" style={{ padding: '24px', textAlign: 'center', color: '#64748b', fontSize: '13px' }}>
                    No bookings assigned to this worker yet.
                  </td>
                </tr>
              ) : (
                workerBookings.map((b) => {
                  const customerName = b.customer?.name || (typeof b.customer === 'string' ? b.customer : 'Customer');
                  const serviceTitle = b.service?.title || b.serviceTitle || (typeof b.service === 'string' ? b.service : 'Gig Service');
                  const bookingAmount = b.invoice?.totalAmount || b.pricing?.finalAmount || b.amount || 500;
                  const displayId = b.bookingId || (typeof b._id === 'string' ? b._id : b.id || 'BK-1001');

                  return (
                    <tr key={b._id || b.id || Math.random()} style={{ borderBottom: '1px solid #f1f5f3', fontSize: '13px' }}>
                      <td style={{ padding: '12px 18px', color: '#0284c7', fontWeight: '700' }}>
                        {displayId}
                      </td>
                      <td style={{ padding: '12px 18px' }}>{customerName}</td>
                      <td style={{ padding: '12px 18px' }}>{serviceTitle}</td>
                      <td style={{ padding: '12px 18px', fontWeight: '700' }}>₹{bookingAmount}</td>
                      <td style={{ padding: '12px 18px' }}><Badge status={b.status || 'COMPLETED'} /></td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
