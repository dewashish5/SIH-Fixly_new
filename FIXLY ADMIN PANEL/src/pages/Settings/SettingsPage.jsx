import React, { useState, useEffect, useRef } from 'react';
import { useSearchParams } from 'react-router-dom';
import { useApp } from '../../context/AppContext';
import { useToast } from '../../context/ToastContext';
import { api } from '../../services/api';
import {
  Sliders,
  User,
  MessageSquareText,
  Save,
  Building2,
  Tag,
  DollarSign,
  Plus,
  Trash2,
  Edit3,
  Search,
  CheckCircle2,
  X,
  Phone,
  MapPin,
  Users,
  Shield,
  Percent,
  Clock,
  RefreshCw,
  Camera,
  Link as LinkIcon,
  Zap,
  Wrench,
  Hammer,
  Sparkles,
  Flame,
  ChevronRight,
  Info
} from 'lucide-react';
import Avatar from '../../components/common/Avatar';

export default function SettingsPage() {
  const [searchParams, setSearchParams] = useSearchParams();
  const { settings, fetchSettings, updateSettings, adminUser, updateAdminProfile } = useApp();
  const { showToast } = useToast();

  const tabParam = searchParams.get('tab');
  const [activeTab, setActiveTab] = useState(tabParam || 'platform');

  const fileInputRef = useRef(null);

  // -------------------------------------------------------------
  // TAB 1: PLATFORM GOVERNANCE STATE
  // -------------------------------------------------------------
  const [platformForm, setPlatformForm] = useState({
    customerPlatformFee: 0,
    workerCommissionPercent: 5,
    cooperativeWelfarePercent: 5,
    workerSearchRadiusKm: 15,
    defaultLaborRatePerHour: 350,
    autoDispatchEnabled: true,
    emergencyHotline: '+91 98765 43210',
    workerDeclineTemplates: [
      'Your request to join as a worker has been declined.',
      'Documents unclear or incomplete. Please re-upload clear Aadhaar and PAN photos.',
      'Identity details do not match our records. Please correct and resubmit.'
    ]
  });
  const [savingPlatform, setSavingPlatform] = useState(false);

  // -------------------------------------------------------------
  // TAB 2: FEDERATION WAGE FLOORS & EMERGENCY SURCHARGES
  // -------------------------------------------------------------
  const [federationForm, setFederationForm] = useState({
    name: 'Fixly Cooperative Federation',
    federationName: 'National Labour Cooperative Federation of India',
    registrationNumber: 'FED-COOP-2026-001',
    fairWagePolicy: 'Cooperative Minimum Fair Wage Guarantee Policy v1.0',
    commissionRate: 0.05,
    welfareContributionRate: 0.05,
    emergencySurchargePercent: 20,
    emergencySurchargeFixed: 50,
    minimumWageFloor: {
      electrical: 450,
      plumbing: 400,
      carpentry: 400,
      cleaning: 300,
      painting: 400,
      appliance: 450,
      gardening: 300,
      default: 350
    }
  });
  const [loadingFederation, setLoadingFederation] = useState(false);
  const [savingFederation, setSavingFederation] = useState(false);

  // -------------------------------------------------------------
  // TAB 3: PRIMARY COOPERATIVE SOCIETIES
  // -------------------------------------------------------------
  const [societies, setSocieties] = useState([]);
  const [loadingSocieties, setLoadingSocieties] = useState(false);
  const [societySearch, setSocietySearch] = useState('');
  const [showAddSocietyModal, setShowAddSocietyModal] = useState(false);
  const [showAssignWorkerModal, setShowAssignWorkerModal] = useState(false);
  const [selectedSocietyForAssign, setSelectedSocietyForAssign] = useState(null);

  const [newSociety, setNewSociety] = useState({
    name: '',
    registrationNumber: '',
    state: '',
    district: '',
    wardOrArea: '',
    officeAddress: '',
    contactPhone: '',
    presidentName: '',
    secretaryName: '',
    fairWageComplianceScore: 100
  });
  const [assignWorkerData, setAssignWorkerData] = useState({
    workerId: '',
    societyId: '',
    societyMemberId: ''
  });

  // -------------------------------------------------------------
  // TAB 4: PROMOTIONAL COUPON BANNERS
  // -------------------------------------------------------------
  const [banners, setBanners] = useState([]);
  const [loadingBanners, setLoadingBanners] = useState(false);
  const [showAddBannerModal, setShowAddBannerModal] = useState(false);
  const [newBanner, setNewBanner] = useState({
    title: '',
    code: '',
    discount: '',
    discountPercent: 20,
    discountAmount: 0,
    description: '',
    category: 'all',
    targetUserRole: 'all',
    minOrderValue: 299,
    maxDiscount: 200,
    gradientStart: '#1E3A8A',
    gradientEnd: '#3B82F6',
    priority: 5,
    isActive: true
  });

  // -------------------------------------------------------------
  // TAB 5: ADMIN PROFILE
  // -------------------------------------------------------------
  const [profileState, setProfileState] = useState({
    name: adminUser?.name || 'Administrator',
    email: adminUser?.email || '',
    avatar: adminUser?.avatar || ''
  });
  const [isUploadingPhoto, setIsUploadingPhoto] = useState(false);
  const [showUrlInput, setShowUrlInput] = useState(false);

  // -------------------------------------------------------------
  // LIFECYCLE & SYNC
  // -------------------------------------------------------------
  useEffect(() => {
    if (tabParam) setActiveTab(tabParam);
  }, [tabParam]);

  useEffect(() => {
    fetchSettings();
  }, [fetchSettings]);

  useEffect(() => {
    if (settings && Object.keys(settings).length > 0) {
      setPlatformForm({
        customerPlatformFee: settings.customerPlatformFee ?? 0,
        workerCommissionPercent: settings.workerCommissionPercent ?? settings.platformCommissionPercent ?? 5,
        cooperativeWelfarePercent: settings.cooperativeWelfarePercent ?? 5,
        workerSearchRadiusKm: settings.workerSearchRadiusKm ?? 15,
        defaultLaborRatePerHour: settings.defaultLaborRatePerHour ?? 350,
        autoDispatchEnabled: settings.autoDispatchEnabled !== false,
        emergencyHotline: settings.emergencyHotline || '+91 98765 43210',
        workerDeclineTemplates: settings.workerDeclineTemplates?.length
          ? settings.workerDeclineTemplates
          : platformForm.workerDeclineTemplates
      });
    }
  }, [settings]);

  useEffect(() => {
    if (adminUser) {
      setProfileState({
        name: adminUser.name || 'Administrator',
        email: adminUser.email || '',
        avatar: adminUser.avatar || ''
      });
    }
  }, [adminUser]);

  // Fetch Federation details on tab switch
  const fetchFederationData = async () => {
    try {
      setLoadingFederation(true);
      const res = await api.getCooperative();
      if (res && res.data) {
        const data = res.data;
        setFederationForm({
          name: data.name || 'Fixly Cooperative Federation',
          federationName: data.federationName || 'National Labour Cooperative Federation of India',
          registrationNumber: data.registrationNumber || 'FED-COOP-2026-001',
          fairWagePolicy: data.fairWagePolicy || 'Cooperative Minimum Fair Wage Guarantee Policy v1.0',
          commissionRate: data.commissionRate ?? 0.05,
          welfareContributionRate: data.welfareContributionRate ?? 0.05,
          emergencySurchargePercent: data.emergencySurchargePercent ?? 20,
          emergencySurchargeFixed: data.emergencySurchargeFixed ?? 50,
          minimumWageFloor: {
            electrical: data.minimumWageFloor?.electrical ?? 450,
            plumbing: data.minimumWageFloor?.plumbing ?? 400,
            carpentry: data.minimumWageFloor?.carpentry ?? 400,
            cleaning: data.minimumWageFloor?.cleaning ?? 300,
            painting: data.minimumWageFloor?.painting ?? 400,
            appliance: data.minimumWageFloor?.appliance ?? 450,
            gardening: data.minimumWageFloor?.gardening ?? 300,
            default: data.minimumWageFloor?.default ?? 350
          }
        });
      }
    } catch (err) {
      console.warn('Could not fetch federation details:', err);
    } finally {
      setLoadingFederation(false);
    }
  };

  // Fetch Societies list
  const fetchSocieties = async () => {
    try {
      setLoadingSocieties(true);
      const res = await api.getSocieties({ search: societySearch });
      if (res && (res.societies || res.data)) {
        setSocieties(res.societies || res.data || []);
      }
    } catch (err) {
      console.warn('Could not fetch cooperative societies:', err);
    } finally {
      setLoadingSocieties(false);
    }
  };

  // Fetch Banners list
  const fetchBanners = async () => {
    try {
      setLoadingBanners(true);
      const res = await api.getBanners();
      if (res && res.banners) {
        setBanners(res.banners);
      }
    } catch (err) {
      console.warn('Could not fetch coupon banners:', err);
    } finally {
      setLoadingBanners(false);
    }
  };

  useEffect(() => {
    if (activeTab === 'wage_floors') fetchFederationData();
    if (activeTab === 'societies') fetchSocieties();
    if (activeTab === 'banners') fetchBanners();
  }, [activeTab]);

  // -------------------------------------------------------------
  // HANDLERS
  // -------------------------------------------------------------
  const handleSavePlatform = async (e) => {
    e.preventDefault();
    try {
      setSavingPlatform(true);
      await updateSettings(platformForm);
    } finally {
      setSavingPlatform(false);
    }
  };

  const handleSaveFederation = async (e) => {
    e.preventDefault();
    try {
      setSavingFederation(true);
      const res = await api.updateCooperative(federationForm);
      if (res && (res.success || res.data)) {
        showToast('success', 'Cooperative Federation wage floors & policy saved successfully!');
      }
    } catch (err) {
      showToast('error', err.response?.data?.message || 'Failed to update cooperative federation');
    } finally {
      setSavingFederation(false);
    }
  };

  const handleCreateSociety = async (e) => {
    e.preventDefault();
    try {
      const res = await api.createSociety(newSociety);
      if (res && res.success) {
        showToast('success', `Primary Society '${newSociety.name}' registered successfully!`);
        setShowAddSocietyModal(false);
        setNewSociety({
          name: '',
          registrationNumber: '',
          state: '',
          district: '',
          wardOrArea: '',
          officeAddress: '',
          contactPhone: '',
          presidentName: '',
          secretaryName: '',
          fairWageComplianceScore: 100
        });
        fetchSocieties();
      }
    } catch (err) {
      showToast('error', err.response?.data?.message || 'Failed to create cooperative society');
    }
  };

  const handleAssignWorker = async (e) => {
    e.preventDefault();
    try {
      const res = await api.assignWorkerToSociety(assignWorkerData);
      if (res && res.success) {
        showToast('success', res.message || 'Worker successfully assigned to Cooperative Society!');
        setShowAssignWorkerModal(false);
        setAssignWorkerData({ workerId: '', societyId: '', societyMemberId: '' });
        fetchSocieties();
      }
    } catch (err) {
      showToast('error', err.response?.data?.message || 'Failed to assign worker');
    }
  };

  const handleCreateBanner = async (e) => {
    e.preventDefault();
    try {
      const payload = {
        title: newBanner.title,
        code: newBanner.code.toUpperCase().trim(),
        discount: newBanner.discount,
        discountPercent: Number(newBanner.discountPercent) || 0,
        discountAmount: Number(newBanner.discountAmount) || 0,
        description: newBanner.description,
        gradient: [newBanner.gradientStart, newBanner.gradientEnd],
        category: newBanner.category,
        targetUserRole: newBanner.targetUserRole,
        minOrderValue: Number(newBanner.minOrderValue) || 0,
        maxDiscount: Number(newBanner.maxDiscount) || 500,
        priority: Number(newBanner.priority) || 0,
        isActive: Boolean(newBanner.isActive)
      };

      const res = await api.createBanner(payload);
      if (res && res.success) {
        showToast('success', `Coupon banner '${newBanner.code}' created successfully!`);
        setShowAddBannerModal(false);
        fetchBanners();
      }
    } catch (err) {
      showToast('error', err.response?.data?.message || 'Failed to create coupon banner');
    }
  };

  const handleDeleteBanner = async (id, code) => {
    if (!window.confirm(`Are you sure you want to delete coupon '${code}'?`)) return;
    try {
      await api.deleteBanner(id);
      showToast('success', `Coupon banner '${code}' deleted`);
      fetchBanners();
    } catch (err) {
      showToast('error', 'Failed to delete banner');
    }
  };

  const handleSaveProfile = async (e) => {
    e.preventDefault();
    await updateAdminProfile(profileState);
  };

  const handleFileChange = async (e) => {
    const file = e.target.files?.[0];
    if (!file) return;

    const reader = new FileReader();
    reader.onload = async (evt) => {
      const dataUrl = evt.target?.result;
      setProfileState((prev) => ({ ...prev, avatar: dataUrl }));

      try {
        setIsUploadingPhoto(true);
        const uploadRes = await api.uploadImage(file);
        if (uploadRes && uploadRes.url) {
          setProfileState((prev) => ({ ...prev, avatar: uploadRes.url }));
        }
      } catch (err) {
        console.warn('Direct upload failed, keeping base64 preview:', err);
      } finally {
        setIsUploadingPhoto(false);
      }
    };
    reader.readAsDataURL(file);
  };

  // Calculations for net worker earnings preview
  const commPercent = Number(platformForm.workerCommissionPercent || 0);
  const welfarePercent = Number(platformForm.cooperativeWelfarePercent || 0);
  const workerNetPercent = Math.max(0, 100 - (commPercent + welfarePercent));

  return (
    <div style={{ padding: '0 32px 36px 32px', animation: 'fadeIn 0.2s ease', maxWidth: '1000px' }}>
      {/* Header */}
      <div style={{ marginBottom: '22px' }}>
        <h2 style={{ fontSize: '22px', fontWeight: '800', color: '#0f172a', letterSpacing: '-0.02em' }}>
          Platform Settings & Cooperative Governance
        </h2>
        <p style={{ fontSize: '13.5px', color: '#64748b', marginTop: '2px' }}>
          Configure dynamic platform fees, fair wage floors, primary cooperative societies, promotional vouchers, and admin credentials.
        </p>
      </div>

      {/* Tabs */}
      <div style={{ display: 'flex', gap: '4px', borderBottom: '1px solid #e2e8f0', marginBottom: '24px', overflowX: 'auto' }}>
        {[
          { key: 'platform', label: 'Platform & Fees', icon: Sliders },
          { key: 'wage_floors', label: 'Wage Floors & Policy', icon: DollarSign },
          { key: 'societies', label: 'Cooperative Societies', icon: Building2 },
          { key: 'banners', label: 'Promotions & Coupons', icon: Tag },
          { key: 'decline', label: 'Decline Templates', icon: MessageSquareText },
          { key: 'profile', label: 'Admin Identity', icon: User },
        ].map((tab) => {
          const Icon = tab.icon;
          const isActive = activeTab === tab.key;
          return (
            <button
              key={tab.key}
              type="button"
              onClick={() => {
                setActiveTab(tab.key);
                setSearchParams({ tab: tab.key });
              }}
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: '8px',
                padding: '11px 18px',
                fontSize: '13.5px',
                fontWeight: isActive ? '700' : '500',
                color: isActive ? '#15803d' : '#64748b',
                borderBottom: isActive ? '2.5px solid #15803d' : '2.5px solid transparent',
                backgroundColor: 'transparent',
                borderTop: 'none',
                borderLeft: 'none',
                borderRight: 'none',
                cursor: 'pointer',
                marginBottom: '-1px',
                whiteSpace: 'nowrap',
                transition: 'all 0.15s ease'
              }}
            >
              <Icon size={16} color={isActive ? '#15803d' : '#64748b'} />
              <span>{tab.label}</span>
            </button>
          );
        })}
      </div>

      {/* ========================================================= */}
      {/* TAB 1: PLATFORM & DYNAMIC FEES */}
      {/* ========================================================= */}
      {activeTab === 'platform' && (
        <form onSubmit={handleSavePlatform} style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
          {/* Realtime Worker Earnings Preview Card */}
          <div style={{
            background: 'linear-gradient(135deg, #064e3b 0%, #047857 100%)',
            padding: '20px 24px',
            borderRadius: '16px',
            color: '#ffffff',
            boxShadow: '0 10px 25px -5px rgba(5, 150, 105, 0.25)'
          }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '12px' }}>
              <div>
                <span style={{ fontSize: '11px', fontWeight: '800', letterSpacing: '0.08em', textTransform: 'uppercase', color: '#a7f3d0' }}>
                  Transparent Cooperative Economy
                </span>
                <h3 style={{ fontSize: '18px', fontWeight: '800', margin: '2px 0 0 0' }}>
                  Worker Direct Payout: {workerNetPercent}%
                </h3>
              </div>
              <div style={{ textAlign: 'right' }}>
                <span style={{ fontSize: '12px', opacity: 0.9 }}>Customer Platform Fee</span>
                <div style={{ fontSize: '18px', fontWeight: '800' }}>
                  {platformForm.customerPlatformFee === 0 ? '₹0 (Free)' : `₹${platformForm.customerPlatformFee}`}
                </div>
              </div>
            </div>

            {/* Split Bar */}
            <div style={{ display: 'flex', height: '10px', borderRadius: '5px', overflow: 'hidden', backgroundColor: 'rgba(255,255,255,0.2)', marginBottom: '10px' }}>
              <div style={{ width: `${workerNetPercent}%`, backgroundColor: '#34d399', transition: 'width 0.3s' }} title={`Worker Net: ${workerNetPercent}%`} />
              <div style={{ width: `${welfarePercent}%`, backgroundColor: '#fbbf24', transition: 'width 0.3s' }} title={`Welfare Pool: ${welfarePercent}%`} />
              <div style={{ width: `${commPercent}%`, backgroundColor: '#60a5fa', transition: 'width 0.3s' }} title={`Platform Fee: ${commPercent}%`} />
            </div>

            <div style={{ display: 'flex', gap: '16px', fontSize: '12px', flexWrap: 'wrap' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                <span style={{ width: '8px', height: '8px', borderRadius: '50%', backgroundColor: '#34d399' }} />
                <span>Worker Take-Home ({workerNetPercent}%)</span>
              </div>
              <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                <span style={{ width: '8px', height: '8px', borderRadius: '50%', backgroundColor: '#fbbf24' }} />
                <span>Cooperative Welfare ({welfarePercent}%)</span>
              </div>
              <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                <span style={{ width: '8px', height: '8px', borderRadius: '50%', backgroundColor: '#60a5fa' }} />
                <span>Tech Maintenance Fee ({commPercent}%)</span>
              </div>
            </div>
          </div>

          {/* Core Fee Controls */}
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))', gap: '18px' }}>
            {/* 1. Customer Platform Fee */}
            <div style={{ backgroundColor: '#ffffff', padding: '20px', borderRadius: '14px', border: '1px solid #e2e8f0' }}>
              <label style={{ display: 'block', fontSize: '13px', fontWeight: '700', color: '#1e293b', marginBottom: '4px' }}>
                Customer Platform Convenience Fee (₹)
              </label>
              <p style={{ fontSize: '12px', color: '#64748b', marginBottom: '12px' }}>
                Flat fee added to each customer invoice. Set to <strong>₹0</strong> for zero customer markup.
              </p>
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                <span style={{ fontSize: '16px', fontWeight: '700', color: '#0f172a' }}>₹</span>
                <input
                  type="number"
                  min="0"
                  value={platformForm.customerPlatformFee}
                  onChange={(e) => setPlatformForm({ ...platformForm, customerPlatformFee: Number(e.target.value) || 0 })}
                  style={{ width: '120px', padding: '8px 12px', borderRadius: '8px', border: '1px solid #cbd5e1', fontSize: '14px', fontWeight: '700' }}
                />
                {platformForm.customerPlatformFee === 0 && (
                  <span style={{ fontSize: '11px', fontWeight: '700', color: '#15803d', backgroundColor: '#dcfce7', padding: '4px 8px', borderRadius: '6px' }}>
                    Zero-Fee Active
                  </span>
                )}
              </div>
            </div>

            {/* 2. Worker Commission Rate */}
            <div style={{ backgroundColor: '#ffffff', padding: '20px', borderRadius: '14px', border: '1px solid #e2e8f0' }}>
              <label style={{ display: 'block', fontSize: '13px', fontWeight: '700', color: '#1e293b', marginBottom: '4px' }}>
                Worker Platform Commission (%)
              </label>
              <p style={{ fontSize: '12px', color: '#64748b', marginBottom: '12px' }}>
                Base software operating margin deducted from job earnings to fund servers. Supports 0%.
              </p>
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                <input
                  type="number"
                  min="0"
                  max="50"
                  value={platformForm.workerCommissionPercent}
                  onChange={(e) => setPlatformForm({ ...platformForm, workerCommissionPercent: Number(e.target.value) || 0 })}
                  style={{ width: '100px', padding: '8px 12px', borderRadius: '8px', border: '1px solid #cbd5e1', fontSize: '14px', fontWeight: '700' }}
                />
                <span style={{ fontSize: '15px', fontWeight: '700', color: '#0f172a' }}>%</span>
              </div>
            </div>

            {/* 3. Cooperative Welfare Reserve */}
            <div style={{ backgroundColor: '#ffffff', padding: '20px', borderRadius: '14px', border: '1px solid #e2e8f0' }}>
              <label style={{ display: 'block', fontSize: '13px', fontWeight: '700', color: '#1e293b', marginBottom: '4px' }}>
                Cooperative Welfare Reserve Split (%)
              </label>
              <p style={{ fontSize: '12px', color: '#64748b', marginBottom: '12px' }}>
                Routed into the worker's cooperative social security, accident insurance, and emergency pool.
              </p>
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                <input
                  type="number"
                  min="0"
                  max="30"
                  value={platformForm.cooperativeWelfarePercent}
                  onChange={(e) => setPlatformForm({ ...platformForm, cooperativeWelfarePercent: Number(e.target.value) || 0 })}
                  style={{ width: '100px', padding: '8px 12px', borderRadius: '8px', border: '1px solid #cbd5e1', fontSize: '14px', fontWeight: '700' }}
                />
                <span style={{ fontSize: '15px', fontWeight: '700', color: '#0f172a' }}>%</span>
              </div>
            </div>

            {/* 4. Worker Search & Dispatch Radius */}
            <div style={{ backgroundColor: '#ffffff', padding: '20px', borderRadius: '14px', border: '1px solid #e2e8f0' }}>
              <label style={{ display: 'block', fontSize: '13px', fontWeight: '700', color: '#1e293b', marginBottom: '4px' }}>
                Worker Search Radius (km)
              </label>
              <p style={{ fontSize: '12px', color: '#64748b', marginBottom: '12px' }}>
                Maximum geographic perimeter in kilometers to locate and notify available cooperative workers.
              </p>
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                <input
                  type="number"
                  min="1"
                  max="100"
                  value={platformForm.workerSearchRadiusKm}
                  onChange={(e) => setPlatformForm({ ...platformForm, workerSearchRadiusKm: Number(e.target.value) || 15 })}
                  style={{ width: '100px', padding: '8px 12px', borderRadius: '8px', border: '1px solid #cbd5e1', fontSize: '14px', fontWeight: '700' }}
                />
                <span style={{ fontSize: '14px', fontWeight: '700', color: '#64748b' }}>km radius</span>
              </div>
            </div>

            {/* 5. Default Labor Rate Floor */}
            <div style={{ backgroundColor: '#ffffff', padding: '20px', borderRadius: '14px', border: '1px solid #e2e8f0' }}>
              <label style={{ display: 'block', fontSize: '13px', fontWeight: '700', color: '#1e293b', marginBottom: '4px' }}>
                Default Base Labor Rate Floor (₹ / hr)
              </label>
              <p style={{ fontSize: '12px', color: '#64748b', marginBottom: '12px' }}>
                Minimum legal fallback hourly wage floor for service estimates.
              </p>
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                <span style={{ fontSize: '16px', fontWeight: '700', color: '#0f172a' }}>₹</span>
                <input
                  type="number"
                  min="100"
                  value={platformForm.defaultLaborRatePerHour}
                  onChange={(e) => setPlatformForm({ ...platformForm, defaultLaborRatePerHour: Number(e.target.value) || 350 })}
                  style={{ width: '120px', padding: '8px 12px', borderRadius: '8px', border: '1px solid #cbd5e1', fontSize: '14px', fontWeight: '700' }}
                />
                <span style={{ fontSize: '13px', color: '#64748b' }}>/ hour</span>
              </div>
            </div>

            {/* 6. Emergency SOS Dispatch Hotline */}
            <div style={{ backgroundColor: '#ffffff', padding: '20px', borderRadius: '14px', border: '1px solid #e2e8f0' }}>
              <label style={{ display: 'block', fontSize: '13px', fontWeight: '700', color: '#1e293b', marginBottom: '4px' }}>
                Emergency SOS Dispatch Hotline
              </label>
              <p style={{ fontSize: '12px', color: '#64748b', marginBottom: '12px' }}>
                24/7 dedicated helpline displayed on mobile client during urgent SOS triggers.
              </p>
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                <Phone size={16} color="#0f172a" />
                <input
                  type="text"
                  value={platformForm.emergencyHotline}
                  onChange={(e) => setPlatformForm({ ...platformForm, emergencyHotline: e.target.value })}
                  style={{ width: '100%', padding: '8px 12px', borderRadius: '8px', border: '1px solid #cbd5e1', fontSize: '13px' }}
                />
              </div>
            </div>
          </div>

          {/* Toggle: Automated Fair Dispatch Engine */}
          <div style={{ backgroundColor: '#ffffff', padding: '20px 24px', borderRadius: '14px', border: '1px solid #e2e8f0', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <div>
              <h4 style={{ fontSize: '14px', fontWeight: '700', color: '#0f172a', margin: '0 0 2px 0' }}>
                Automated Fair Dispatch & Rotation Engine
              </h4>
              <p style={{ fontSize: '12.5px', color: '#64748b', margin: 0 }}>
                Prevents gig monopolization by rotating booking requests equitably among verified cooperative members.
              </p>
            </div>
            <label style={{ position: 'relative', display: 'inline-block', width: '48px', height: '26px' }}>
              <input
                type="checkbox"
                checked={platformForm.autoDispatchEnabled}
                onChange={(e) => setPlatformForm({ ...platformForm, autoDispatchEnabled: e.target.checked })}
                style={{ opacity: 0, width: 0, height: 0 }}
              />
              <span style={{
                position: 'absolute', cursor: 'pointer', top: 0, left: 0, right: 0, bottom: 0,
                backgroundColor: platformForm.autoDispatchEnabled ? '#15803d' : '#cbd5e1',
                borderRadius: '34px', transition: '.3s'
              }}>
                <span style={{
                  position: 'absolute', content: '""', height: '20px', width: '20px', left: platformForm.autoDispatchEnabled ? '24px' : '3px', bottom: '3px',
                  backgroundColor: 'white', borderRadius: '50%', transition: '.3s'
                }} />
              </span>
            </label>
          </div>

          <div style={{ display: 'flex', justifyContent: 'flex-end', marginTop: '6px' }}>
            <button
              type="submit"
              disabled={savingPlatform}
              style={{
                display: 'flex', alignItems: 'center', gap: '8px',
                padding: '11px 26px', backgroundColor: '#15803d', color: '#ffffff',
                borderRadius: '9px', fontSize: '14px', fontWeight: '700', border: 'none',
                cursor: 'pointer', boxShadow: '0 4px 10px rgba(21, 128, 61, 0.25)'
              }}
            >
              <Save size={16} />
              <span>{savingPlatform ? 'Saving...' : 'Save Platform Governance Settings'}</span>
            </button>
          </div>
        </form>
      )}

      {/* ========================================================= */}
      {/* TAB 2: FEDERATION WAGE FLOORS & EMERGENCY SURCHARGES */}
      {/* ========================================================= */}
      {activeTab === 'wage_floors' && (
        <form onSubmit={handleSaveFederation} style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
          <div style={{ backgroundColor: '#ffffff', padding: '24px', borderRadius: '16px', border: '1px solid #e2e8f0' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '16px' }}>
              <Building2 size={20} color="#15803d" />
              <div>
                <h3 style={{ fontSize: '16px', fontWeight: '700', color: '#0f172a', margin: 0 }}>
                  Federation Identification & Fair Wage Policy
                </h3>
                <p style={{ fontSize: '12.5px', color: '#64748b', margin: '2px 0 0 0' }}>
                  Governed by state cooperative laws to enforce statutory minimum compensation per trade.
                </p>
              </div>
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px' }}>
              <div>
                <label style={{ display: 'block', fontSize: '12.5px', fontWeight: '600', color: '#334155', marginBottom: '5px' }}>
                  Apex Federation Name
                </label>
                <input
                  type="text"
                  value={federationForm.federationName}
                  onChange={(e) => setFederationForm({ ...federationForm, federationName: e.target.value })}
                  style={{ width: '100%', padding: '9px 12px', borderRadius: '8px', border: '1px solid #cbd5e1', fontSize: '13.5px' }}
                />
              </div>
              <div>
                <label style={{ display: 'block', fontSize: '12.5px', fontWeight: '600', color: '#334155', marginBottom: '5px' }}>
                  Federation Registration Number
                </label>
                <input
                  type="text"
                  value={federationForm.registrationNumber}
                  onChange={(e) => setFederationForm({ ...federationForm, registrationNumber: e.target.value })}
                  style={{ width: '100%', padding: '9px 12px', borderRadius: '8px', border: '1px solid #cbd5e1', fontSize: '13.5px' }}
                />
              </div>
            </div>
          </div>

          {/* Trade Minimum Wage Floors */}
          <div style={{ backgroundColor: '#ffffff', padding: '24px', borderRadius: '16px', border: '1px solid #e2e8f0' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px' }}>
              <div>
                <h3 style={{ fontSize: '16px', fontWeight: '700', color: '#0f172a', margin: 0 }}>
                  Statutory Trade Wage Floors (₹ / hr)
                </h3>
                <p style={{ fontSize: '12.5px', color: '#64748b', margin: '2px 0 0 0' }}>
                  Under-bidding below these floors is strictly prevented by the booking pricing engine.
                </p>
              </div>
              <span style={{ fontSize: '11.5px', fontWeight: '700', color: '#15803d', backgroundColor: '#dcfce7', padding: '5px 10px', borderRadius: '6px' }}>
                Fair Wage Compliant
              </span>
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '14px' }}>
              {[
                { key: 'electrical', label: 'Electrical', icon: Zap, color: '#eab308' },
                { key: 'plumbing', label: 'Plumbing', icon: Wrench, color: '#0284c7' },
                { key: 'carpentry', label: 'Carpentry', icon: Hammer, color: '#b45309' },
                { key: 'cleaning', label: 'Cleaning', icon: Sparkles, color: '#10b981' },
                { key: 'painting', label: 'Painting', icon: Flame, color: '#8b5cf6' },
                { key: 'appliance', label: 'Appliance & Tech', icon: Wrench, color: '#6366f1' },
                { key: 'gardening', label: 'Gardening', icon: Sparkles, color: '#059669' },
                { key: 'default', label: 'General / Other', icon: Sliders, color: '#64748b' },
              ].map((trade) => {
                const TradeIcon = trade.icon;
                return (
                  <div key={trade.key} style={{ padding: '14px', borderRadius: '12px', border: '1px solid #e2e8f0', backgroundColor: '#f8fafc' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '8px' }}>
                      <TradeIcon size={16} color={trade.color} />
                      <span style={{ fontSize: '13px', fontWeight: '700', color: '#1e293b' }}>{trade.label}</span>
                    </div>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                      <span style={{ fontSize: '14px', fontWeight: '700', color: '#64748b' }}>₹</span>
                      <input
                        type="number"
                        min="100"
                        value={federationForm.minimumWageFloor?.[trade.key] ?? 350}
                        onChange={(e) => {
                          const val = Number(e.target.value) || 0;
                          setFederationForm({
                            ...federationForm,
                            minimumWageFloor: {
                              ...federationForm.minimumWageFloor,
                              [trade.key]: val
                            }
                          });
                        }}
                        style={{ width: '100%', padding: '7px 10px', borderRadius: '6px', border: '1px solid #cbd5e1', fontSize: '13.5px', fontWeight: '700' }}
                      />
                    </div>
                  </div>
                );
              })}
            </div>
          </div>

          {/* Emergency SOS Booking Surcharges */}
          <div style={{ backgroundColor: '#ffffff', padding: '24px', borderRadius: '16px', border: '1px solid #e2e8f0' }}>
            <h3 style={{ fontSize: '16px', fontWeight: '700', color: '#0f172a', margin: '0 0 4px 0' }}>
              Emergency SOS Urgent Job Surcharges
            </h3>
            <p style={{ fontSize: '12.5px', color: '#64748b', margin: '0 0 16px 0' }}>
              Added to immediate SOS requests to incentivize rapid worker mobilization.
            </p>

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px' }}>
              <div>
                <label style={{ display: 'block', fontSize: '12.5px', fontWeight: '600', color: '#334155', marginBottom: '5px' }}>
                  Emergency Surcharge Percentage (%)
                </label>
                <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                  <input
                    type="number"
                    min="0"
                    max="100"
                    value={federationForm.emergencySurchargePercent}
                    onChange={(e) => setFederationForm({ ...federationForm, emergencySurchargePercent: Number(e.target.value) || 0 })}
                    style={{ width: '120px', padding: '8px 12px', borderRadius: '8px', border: '1px solid #cbd5e1', fontSize: '14px', fontWeight: '700' }}
                  />
                  <span style={{ fontSize: '14px', fontWeight: '700', color: '#0f172a' }}>% surcharge</span>
                </div>
              </div>

              <div>
                <label style={{ display: 'block', fontSize: '12.5px', fontWeight: '600', color: '#334155', marginBottom: '5px' }}>
                  Emergency Fixed Mobilization Fee (₹)
                </label>
                <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                  <span style={{ fontSize: '16px', fontWeight: '700', color: '#0f172a' }}>₹</span>
                  <input
                    type="number"
                    min="0"
                    value={federationForm.emergencySurchargeFixed}
                    onChange={(e) => setFederationForm({ ...federationForm, emergencySurchargeFixed: Number(e.target.value) || 0 })}
                    style={{ width: '120px', padding: '8px 12px', borderRadius: '8px', border: '1px solid #cbd5e1', fontSize: '14px', fontWeight: '700' }}
                  />
                  <span style={{ fontSize: '12px', color: '#64748b' }}>flat bonus per callout</span>
                </div>
              </div>
            </div>
          </div>

          <div style={{ display: 'flex', justifyContent: 'flex-end' }}>
            <button
              type="submit"
              disabled={savingFederation}
              style={{
                display: 'flex', alignItems: 'center', gap: '8px',
                padding: '11px 26px', backgroundColor: '#15803d', color: '#ffffff',
                borderRadius: '9px', fontSize: '14px', fontWeight: '700', border: 'none',
                cursor: 'pointer', boxShadow: '0 4px 10px rgba(21, 128, 61, 0.25)'
              }}
            >
              <Save size={16} />
              <span>{savingFederation ? 'Saving...' : 'Save Federation Policy & Wage Floors'}</span>
            </button>
          </div>
        </form>
      )}

      {/* ========================================================= */}
      {/* TAB 3: PRIMARY COOPERATIVE SOCIETIES */}
      {/* ========================================================= */}
      {activeTab === 'societies' && (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '12px' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
              <div style={{ position: 'relative', width: '280px' }}>
                <Search size={15} color="#94a3b8" style={{ position: 'absolute', left: '10px', top: '10px' }} />
                <input
                  type="text"
                  placeholder="Search society, district..."
                  value={societySearch}
                  onChange={(e) => setSocietySearch(e.target.value)}
                  onKeyDown={(e) => { if (e.key === 'Enter') fetchSocieties(); }}
                  style={{ width: '100%', padding: '8px 10px 8px 32px', borderRadius: '8px', border: '1px solid #cbd5e1', fontSize: '13px' }}
                />
              </div>
              <button
                type="button"
                onClick={fetchSocieties}
                style={{ padding: '8px 14px', backgroundColor: '#f1f5f9', color: '#334155', borderRadius: '8px', border: '1px solid #cbd5e1', fontSize: '13px', fontWeight: '600', cursor: 'pointer' }}
              >
                Filter
              </button>
            </div>

            <div style={{ display: 'flex', gap: '10px' }}>
              <button
                type="button"
                onClick={() => setShowAssignWorkerModal(true)}
                style={{
                  display: 'flex', alignItems: 'center', gap: '6px',
                  padding: '9px 16px', backgroundColor: '#eff6ff', color: '#1d4ed8',
                  borderRadius: '8px', border: '1px solid #bfdbfe', fontSize: '13px', fontWeight: '700', cursor: 'pointer'
                }}
              >
                <Users size={15} />
                <span>Assign Worker</span>
              </button>
              <button
                type="button"
                onClick={() => setShowAddSocietyModal(true)}
                style={{
                  display: 'flex', alignItems: 'center', gap: '6px',
                  padding: '9px 18px', backgroundColor: '#15803d', color: '#ffffff',
                  borderRadius: '8px', border: 'none', fontSize: '13px', fontWeight: '700', cursor: 'pointer'
                }}
              >
                <Plus size={16} />
                <span>Register Primary Society</span>
              </button>
            </div>
          </div>

          {/* Societies Grid */}
          {loadingSocieties ? (
            <div style={{ padding: '60px', textAlign: 'center', color: '#64748b' }}>Loading societies...</div>
          ) : societies.length === 0 ? (
            <div style={{ padding: '60px', textAlign: 'center', backgroundColor: '#ffffff', borderRadius: '16px', border: '1px solid #e2e8f0' }}>
              <Building2 size={36} color="#94a3b8" style={{ margin: '0 auto 12px auto' }} />
              <h4 style={{ fontSize: '16px', fontWeight: '700', color: '#1e293b', margin: '0 0 4px 0' }}>No Primary Cooperative Societies Found</h4>
              <p style={{ fontSize: '13px', color: '#64748b', margin: '0 0 16px 0' }}>Register local labour contract cooperative societies to affiliate workers.</p>
              <button
                type="button"
                onClick={() => setShowAddSocietyModal(true)}
                style={{ padding: '8px 16px', backgroundColor: '#15803d', color: '#ffffff', borderRadius: '8px', border: 'none', fontSize: '13px', fontWeight: '700', cursor: 'pointer' }}
              >
                + Register First Society
              </button>
            </div>
          ) : (
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(310px, 1fr))', gap: '18px' }}>
              {societies.map((soc) => (
                <div key={soc._id} style={{ backgroundColor: '#ffffff', borderRadius: '14px', border: '1px solid #e2e8f0', padding: '20px', display: 'flex', flexDirection: 'column', justifyContent: 'space-between' }}>
                  <div>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '8px' }}>
                      <span style={{ fontSize: '11px', fontWeight: '800', color: '#15803d', backgroundColor: '#dcfce7', padding: '3px 8px', borderRadius: '6px' }}>
                        {soc.registrationNumber}
                      </span>
                      <span style={{ fontSize: '11.5px', fontWeight: '700', color: soc.fairWageComplianceScore >= 90 ? '#15803d' : '#d97706' }}>
                        {soc.fairWageComplianceScore}% Compliance
                      </span>
                    </div>

                    <h4 style={{ fontSize: '15px', fontWeight: '700', color: '#0f172a', margin: '0 0 6px 0' }}>
                      {soc.name}
                    </h4>

                    <div style={{ display: 'flex', alignItems: 'center', gap: '6px', fontSize: '12.5px', color: '#64748b', marginBottom: '10px' }}>
                      <MapPin size={14} color="#64748b" />
                      <span>{soc.district}, {soc.state} {soc.wardOrArea ? `(${soc.wardOrArea})` : ''}</span>
                    </div>

                    {soc.presidentName && (
                      <div style={{ fontSize: '12px', color: '#475569', marginBottom: '4px' }}>
                        President: <strong>{soc.presidentName}</strong>
                      </div>
                    )}
                    {soc.contactPhone && (
                      <div style={{ fontSize: '12px', color: '#475569' }}>
                        Phone: <strong>{soc.contactPhone}</strong>
                      </div>
                    )}
                  </div>

                  <div style={{ marginTop: '16px', paddingTop: '12px', borderTop: '1px solid #f1f5f9', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <span style={{ fontSize: '12px', fontWeight: '600', color: '#2563eb' }}>
                      {soc.activeMembersCount || 0} Affiliated Workers
                    </span>
                    <button
                      type="button"
                      onClick={() => {
                        setSelectedSocietyForAssign(soc);
                        setAssignWorkerData({ ...assignWorkerData, societyId: soc._id });
                        setShowAssignWorkerModal(true);
                      }}
                      style={{ fontSize: '12px', fontWeight: '700', color: '#15803d', backgroundColor: '#dcfce7', border: 'none', padding: '4px 10px', borderRadius: '6px', cursor: 'pointer' }}
                    >
                      + Add Member
                    </button>
                  </div>
                </div>
              ))}
            </div>
          )}

          {/* MODAL: Register New Primary Society */}
          {showAddSocietyModal && (
            <div style={{ position: 'fixed', inset: 0, backgroundColor: 'rgba(0,0,0,0.5)', zIndex: 1000, display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '16px' }}>
              <div style={{ backgroundColor: '#ffffff', borderRadius: '16px', width: '100%', maxWidth: '540px', padding: '24px', maxHeight: '90vh', overflowY: 'auto' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px' }}>
                  <h3 style={{ fontSize: '17px', fontWeight: '700', color: '#0f172a', margin: 0 }}>
                    Register Primary Labour Cooperative Society
                  </h3>
                  <button type="button" onClick={() => setShowAddSocietyModal(false)} style={{ background: 'none', border: 'none', cursor: 'pointer' }}>
                    <X size={18} color="#64748b" />
                  </button>
                </div>

                <form onSubmit={handleCreateSociety} style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
                  <div>
                    <label style={{ display: 'block', fontSize: '12.5px', fontWeight: '600', color: '#334155', marginBottom: '4px' }}>Society Name *</label>
                    <input
                      type="text"
                      required
                      placeholder="e.g. South Delhi Technicians Cooperative Society"
                      value={newSociety.name}
                      onChange={(e) => setNewSociety({ ...newSociety, name: e.target.value })}
                      style={{ width: '100%', padding: '8px 12px', borderRadius: '8px', border: '1px solid #cbd5e1', fontSize: '13px' }}
                    />
                  </div>

                  <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
                    <div>
                      <label style={{ display: 'block', fontSize: '12.5px', fontWeight: '600', color: '#334155', marginBottom: '4px' }}>Registration Number *</label>
                      <input
                        type="text"
                        required
                        placeholder="e.g. SOC-DL-2026-104"
                        value={newSociety.registrationNumber}
                        onChange={(e) => setNewSociety({ ...newSociety, registrationNumber: e.target.value })}
                        style={{ width: '100%', padding: '8px 12px', borderRadius: '8px', border: '1px solid #cbd5e1', fontSize: '13px' }}
                      />
                    </div>
                    <div>
                      <label style={{ display: 'block', fontSize: '12.5px', fontWeight: '600', color: '#334155', marginBottom: '4px' }}>Contact Phone</label>
                      <input
                        type="text"
                        placeholder="+91 98765 43210"
                        value={newSociety.contactPhone}
                        onChange={(e) => setNewSociety({ ...newSociety, contactPhone: e.target.value })}
                        style={{ width: '100%', padding: '8px 12px', borderRadius: '8px', border: '1px solid #cbd5e1', fontSize: '13px' }}
                      />
                    </div>
                  </div>

                  <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
                    <div>
                      <label style={{ display: 'block', fontSize: '12.5px', fontWeight: '600', color: '#334155', marginBottom: '4px' }}>State *</label>
                      <input
                        type="text"
                        required
                        placeholder="e.g. Delhi"
                        value={newSociety.state}
                        onChange={(e) => setNewSociety({ ...newSociety, state: e.target.value })}
                        style={{ width: '100%', padding: '8px 12px', borderRadius: '8px', border: '1px solid #cbd5e1', fontSize: '13px' }}
                      />
                    </div>
                    <div>
                      <label style={{ display: 'block', fontSize: '12.5px', fontWeight: '600', color: '#334155', marginBottom: '4px' }}>District *</label>
                      <input
                        type="text"
                        required
                        placeholder="e.g. South Delhi"
                        value={newSociety.district}
                        onChange={(e) => setNewSociety({ ...newSociety, district: e.target.value })}
                        style={{ width: '100%', padding: '8px 12px', borderRadius: '8px', border: '1px solid #cbd5e1', fontSize: '13px' }}
                      />
                    </div>
                  </div>

                  <div>
                    <label style={{ display: 'block', fontSize: '12.5px', fontWeight: '600', color: '#334155', marginBottom: '4px' }}>Ward or Area Coverage</label>
                    <input
                      type="text"
                      placeholder="e.g. Saket, Malviya Nagar & Hauz Khas"
                      value={newSociety.wardOrArea}
                      onChange={(e) => setNewSociety({ ...newSociety, wardOrArea: e.target.value })}
                      style={{ width: '100%', padding: '8px 12px', borderRadius: '8px', border: '1px solid #cbd5e1', fontSize: '13px' }}
                    />
                  </div>

                  <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
                    <div>
                      <label style={{ display: 'block', fontSize: '12.5px', fontWeight: '600', color: '#334155', marginBottom: '4px' }}>President Name</label>
                      <input
                        type="text"
                        placeholder="e.g. Harish Chandra"
                        value={newSociety.presidentName}
                        onChange={(e) => setNewSociety({ ...newSociety, presidentName: e.target.value })}
                        style={{ width: '100%', padding: '8px 12px', borderRadius: '8px', border: '1px solid #cbd5e1', fontSize: '13px' }}
                      />
                    </div>
                    <div>
                      <label style={{ display: 'block', fontSize: '12.5px', fontWeight: '600', color: '#334155', marginBottom: '4px' }}>Secretary Name</label>
                      <input
                        type="text"
                        placeholder="e.g. Suresh Pal"
                        value={newSociety.secretaryName}
                        onChange={(e) => setNewSociety({ ...newSociety, secretaryName: e.target.value })}
                        style={{ width: '100%', padding: '8px 12px', borderRadius: '8px', border: '1px solid #cbd5e1', fontSize: '13px' }}
                      />
                    </div>
                  </div>

                  <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '10px', marginTop: '10px' }}>
                    <button
                      type="button"
                      onClick={() => setShowAddSocietyModal(false)}
                      style={{ padding: '8px 16px', backgroundColor: '#f1f5f9', border: '1px solid #cbd5e1', borderRadius: '8px', fontSize: '13px', fontWeight: '600', cursor: 'pointer' }}
                    >
                      Cancel
                    </button>
                    <button
                      type="submit"
                      style={{ padding: '8px 20px', backgroundColor: '#15803d', color: '#ffffff', border: 'none', borderRadius: '8px', fontSize: '13px', fontWeight: '700', cursor: 'pointer' }}
                    >
                      Save Society
                    </button>
                  </div>
                </form>
              </div>
            </div>
          )}

          {/* MODAL: Assign Worker to Society */}
          {showAssignWorkerModal && (
            <div style={{ position: 'fixed', inset: 0, backgroundColor: 'rgba(0,0,0,0.5)', zIndex: 1000, display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '16px' }}>
              <div style={{ backgroundColor: '#ffffff', borderRadius: '16px', width: '100%', maxWidth: '480px', padding: '24px' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px' }}>
                  <h3 style={{ fontSize: '17px', fontWeight: '700', color: '#0f172a', margin: 0 }}>
                    Assign Worker to Cooperative Society
                  </h3>
                  <button type="button" onClick={() => setShowAssignWorkerModal(false)} style={{ background: 'none', border: 'none', cursor: 'pointer' }}>
                    <X size={18} color="#64748b" />
                  </button>
                </div>

                <form onSubmit={handleAssignWorker} style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
                  <div>
                    <label style={{ display: 'block', fontSize: '12.5px', fontWeight: '600', color: '#334155', marginBottom: '4px' }}>Worker MongoDB ID *</label>
                    <input
                      type="text"
                      required
                      placeholder="e.g. 64f1bc..."
                      value={assignWorkerData.workerId}
                      onChange={(e) => setAssignWorkerData({ ...assignWorkerData, workerId: e.target.value })}
                      style={{ width: '100%', padding: '8px 12px', borderRadius: '8px', border: '1px solid #cbd5e1', fontSize: '13px' }}
                    />
                  </div>

                  <div>
                    <label style={{ display: 'block', fontSize: '12.5px', fontWeight: '600', color: '#334155', marginBottom: '4px' }}>Select Cooperative Society *</label>
                    <select
                      required
                      value={assignWorkerData.societyId}
                      onChange={(e) => setAssignWorkerData({ ...assignWorkerData, societyId: e.target.value })}
                      style={{ width: '100%', padding: '8px 12px', borderRadius: '8px', border: '1px solid #cbd5e1', fontSize: '13px', backgroundColor: '#ffffff' }}
                    >
                      <option value="">-- Choose Society --</option>
                      {societies.map((s) => (
                        <option key={s._id} value={s._id}>{s.name} ({s.district})</option>
                      ))}
                    </select>
                  </div>

                  <div>
                    <label style={{ display: 'block', fontSize: '12.5px', fontWeight: '600', color: '#334155', marginBottom: '4px' }}>Society Member ID (Optional)</label>
                    <input
                      type="text"
                      placeholder="e.g. MEM-SD-2026-0042 (Auto-generated if blank)"
                      value={assignWorkerData.societyMemberId}
                      onChange={(e) => setAssignWorkerData({ ...assignWorkerData, societyMemberId: e.target.value })}
                      style={{ width: '100%', padding: '8px 12px', borderRadius: '8px', border: '1px solid #cbd5e1', fontSize: '13px' }}
                    />
                  </div>

                  <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '10px', marginTop: '10px' }}>
                    <button
                      type="button"
                      onClick={() => setShowAssignWorkerModal(false)}
                      style={{ padding: '8px 16px', backgroundColor: '#f1f5f9', border: '1px solid #cbd5e1', borderRadius: '8px', fontSize: '13px', fontWeight: '600', cursor: 'pointer' }}
                    >
                      Cancel
                    </button>
                    <button
                      type="submit"
                      style={{ padding: '8px 20px', backgroundColor: '#15803d', color: '#ffffff', border: 'none', borderRadius: '8px', fontSize: '13px', fontWeight: '700', cursor: 'pointer' }}
                    >
                      Confirm Assignment
                    </button>
                  </div>
                </form>
              </div>
            </div>
          )}
        </div>
      )}

      {/* ========================================================= */}
      {/* TAB 4: PROMOTIONAL COUPON BANNERS */}
      {/* ========================================================= */}
      {activeTab === 'banners' && (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <div>
              <h3 style={{ fontSize: '16px', fontWeight: '700', color: '#0f172a', margin: 0 }}>
                Promotional Coupon Banners (MongoDB)
              </h3>
              <p style={{ fontSize: '12.5px', color: '#64748b', margin: '2px 0 0 0' }}>
                Manage live mobile home banners, discounts, category tags, and priority ordering.
              </p>
            </div>
            <button
              type="button"
              onClick={() => setShowAddBannerModal(true)}
              style={{
                display: 'flex', alignItems: 'center', gap: '6px',
                padding: '9px 18px', backgroundColor: '#15803d', color: '#ffffff',
                borderRadius: '8px', border: 'none', fontSize: '13px', fontWeight: '700', cursor: 'pointer'
              }}
            >
              <Plus size={16} />
              <span>Create Coupon Banner</span>
            </button>
          </div>

          {loadingBanners ? (
            <div style={{ padding: '60px', textAlign: 'center', color: '#64748b' }}>Loading coupon banners...</div>
          ) : banners.length === 0 ? (
            <div style={{ padding: '60px', textAlign: 'center', backgroundColor: '#ffffff', borderRadius: '16px', border: '1px solid #e2e8f0' }}>
              <Tag size={36} color="#94a3b8" style={{ margin: '0 auto 12px auto' }} />
              <h4 style={{ fontSize: '16px', fontWeight: '700', color: '#1e293b', margin: '0 0 4px 0' }}>No Promotional Banners Found</h4>
              <p style={{ fontSize: '13px', color: '#64748b', margin: '0 0 16px 0' }}>Create discount coupons to display on the mobile app home screen.</p>
              <button
                type="button"
                onClick={() => setShowAddBannerModal(true)}
                style={{ padding: '8px 16px', backgroundColor: '#15803d', color: '#ffffff', borderRadius: '8px', border: 'none', fontSize: '13px', fontWeight: '700', cursor: 'pointer' }}
              >
                + Create First Banner
              </button>
            </div>
          ) : (
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(300px, 1fr))', gap: '18px' }}>
              {banners.map((b) => {
                const gradStart = b.gradient?.[0] || '#1E3A8A';
                const gradEnd = b.gradient?.[1] || '#3B82F6';
                return (
                  <div key={b._id} style={{
                    borderRadius: '16px',
                    overflow: 'hidden',
                    backgroundColor: '#ffffff',
                    border: '1px solid #e2e8f0',
                    display: 'flex',
                    flexDirection: 'column',
                    boxShadow: '0 4px 6px -1px rgba(0,0,0,0.05)'
                  }}>
                    {/* Visual Voucher Preview */}
                    <div style={{
                      background: `linear-gradient(135deg, ${gradStart} 0%, ${gradEnd} 100%)`,
                      padding: '18px',
                      color: '#ffffff',
                      position: 'relative'
                    }}>
                      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '8px' }}>
                        <span style={{ fontSize: '11px', fontWeight: '800', backgroundColor: 'rgba(255,255,255,0.25)', padding: '3px 8px', borderRadius: '6px' }}>
                          {b.category?.toUpperCase()}
                        </span>
                        <span style={{ fontSize: '14px', fontWeight: '900' }}>
                          {b.discount}
                        </span>
                      </div>
                      <h4 style={{ fontSize: '15px', fontWeight: '800', margin: '0 0 6px 0', lineHeight: 1.3 }}>
                        {b.title}
                      </h4>
                      <p style={{ fontSize: '12px', opacity: 0.9, margin: 0, lineHeight: 1.4 }}>
                        {b.description}
                      </p>
                    </div>

                    {/* Voucher Details & Controls */}
                    <div style={{ padding: '16px', display: 'flex', flexDirection: 'column', gap: '10px' }}>
                      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                        <div>
                          <span style={{ fontSize: '11px', color: '#64748b' }}>COUPON CODE</span>
                          <div style={{ fontSize: '15px', fontWeight: '900', color: '#0f172a', letterSpacing: '0.05em' }}>
                            {b.code}
                          </div>
                        </div>
                        <div style={{ textAlign: 'right' }}>
                          <span style={{ fontSize: '11px', color: '#64748b' }}>MIN ORDER</span>
                          <div style={{ fontSize: '13px', fontWeight: '700', color: '#1e293b' }}>
                            ₹{b.minOrderValue || 0}
                          </div>
                        </div>
                      </div>

                      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', paddingTop: '10px', borderTop: '1px solid #f1f5f9' }}>
                        <span style={{ fontSize: '11.5px', color: b.isActive ? '#15803d' : '#94a3b8', fontWeight: '700' }}>
                          {b.isActive ? '● Active in App' : '○ Inactive'}
                        </span>
                        <button
                          type="button"
                          onClick={() => handleDeleteBanner(b._id, b.code)}
                          style={{
                            display: 'flex', alignItems: 'center', gap: '4px',
                            background: 'none', border: 'none', color: '#ef4444',
                            fontSize: '12px', fontWeight: '700', cursor: 'pointer'
                          }}
                        >
                          <Trash2 size={13} />
                          <span>Delete</span>
                        </button>
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>
          )}

          {/* MODAL: Create Coupon Banner */}
          {showAddBannerModal && (
            <div style={{ position: 'fixed', inset: 0, backgroundColor: 'rgba(0,0,0,0.5)', zIndex: 1000, display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '16px' }}>
              <div style={{ backgroundColor: '#ffffff', borderRadius: '16px', width: '100%', maxWidth: '500px', padding: '24px', maxHeight: '90vh', overflowY: 'auto' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px' }}>
                  <h3 style={{ fontSize: '17px', fontWeight: '700', color: '#0f172a', margin: 0 }}>
                    Create Promotional Coupon Banner
                  </h3>
                  <button type="button" onClick={() => setShowAddBannerModal(false)} style={{ background: 'none', border: 'none', cursor: 'pointer' }}>
                    <X size={18} color="#64748b" />
                  </button>
                </div>

                <form onSubmit={handleCreateBanner} style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
                  <div>
                    <label style={{ display: 'block', fontSize: '12.5px', fontWeight: '600', color: '#334155', marginBottom: '4px' }}>Banner Title *</label>
                    <input
                      type="text"
                      required
                      placeholder="e.g. Flat 50% Off First Booking"
                      value={newBanner.title}
                      onChange={(e) => setNewBanner({ ...newBanner, title: e.target.value })}
                      style={{ width: '100%', padding: '8px 12px', borderRadius: '8px', border: '1px solid #cbd5e1', fontSize: '13px' }}
                    />
                  </div>

                  <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
                    <div>
                      <label style={{ display: 'block', fontSize: '12.5px', fontWeight: '600', color: '#334155', marginBottom: '4px' }}>Coupon Code *</label>
                      <input
                        type="text"
                        required
                        placeholder="e.g. FIXLY50"
                        value={newBanner.code}
                        onChange={(e) => setNewBanner({ ...newBanner, code: e.target.value.toUpperCase() })}
                        style={{ width: '100%', padding: '8px 12px', borderRadius: '8px', border: '1px solid #cbd5e1', fontSize: '13px', fontWeight: '700', textTransform: 'uppercase' }}
                      />
                    </div>
                    <div>
                      <label style={{ display: 'block', fontSize: '12.5px', fontWeight: '600', color: '#334155', marginBottom: '4px' }}>Discount Tag *</label>
                      <input
                        type="text"
                        required
                        placeholder="e.g. 50% OFF or ₹100 FLAT"
                        value={newBanner.discount}
                        onChange={(e) => setNewBanner({ ...newBanner, discount: e.target.value })}
                        style={{ width: '100%', padding: '8px 12px', borderRadius: '8px', border: '1px solid #cbd5e1', fontSize: '13px' }}
                      />
                    </div>
                  </div>

                  <div>
                    <label style={{ display: 'block', fontSize: '12.5px', fontWeight: '600', color: '#334155', marginBottom: '4px' }}>Short Description</label>
                    <textarea
                      rows={2}
                      placeholder="Get up to ₹150 off on your first home service"
                      value={newBanner.description}
                      onChange={(e) => setNewBanner({ ...newBanner, description: e.target.value })}
                      style={{ width: '100%', padding: '8px 12px', borderRadius: '8px', border: '1px solid #cbd5e1', fontSize: '13px', fontFamily: 'inherit' }}
                    />
                  </div>

                  <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
                    <div>
                      <label style={{ display: 'block', fontSize: '12.5px', fontWeight: '600', color: '#334155', marginBottom: '4px' }}>Target Category</label>
                      <select
                        value={newBanner.category}
                        onChange={(e) => setNewBanner({ ...newBanner, category: e.target.value })}
                        style={{ width: '100%', padding: '8px 12px', borderRadius: '8px', border: '1px solid #cbd5e1', fontSize: '13px', backgroundColor: '#ffffff' }}
                      >
                        <option value="all">All Categories</option>
                        <option value="plumber">Plumbing</option>
                        <option value="electrician">Electrical</option>
                        <option value="technician">Technician / AC</option>
                        <option value="cleaning">Cleaning</option>
                        <option value="carpenter">Carpentry</option>
                      </select>
                    </div>
                    <div>
                      <label style={{ display: 'block', fontSize: '12.5px', fontWeight: '600', color: '#334155', marginBottom: '4px' }}>Min Order Value (₹)</label>
                      <input
                        type="number"
                        min="0"
                        value={newBanner.minOrderValue}
                        onChange={(e) => setNewBanner({ ...newBanner, minOrderValue: Number(e.target.value) || 0 })}
                        style={{ width: '100%', padding: '8px 12px', borderRadius: '8px', border: '1px solid #cbd5e1', fontSize: '13px' }}
                      />
                    </div>
                  </div>

                  <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
                    <div>
                      <label style={{ display: 'block', fontSize: '12.5px', fontWeight: '600', color: '#334155', marginBottom: '4px' }}>Gradient Start</label>
                      <input
                        type="color"
                        value={newBanner.gradientStart}
                        onChange={(e) => setNewBanner({ ...newBanner, gradientStart: e.target.value })}
                        style={{ width: '100%', height: '38px', borderRadius: '8px', border: '1px solid #cbd5e1', cursor: 'pointer' }}
                      />
                    </div>
                    <div>
                      <label style={{ display: 'block', fontSize: '12.5px', fontWeight: '600', color: '#334155', marginBottom: '4px' }}>Gradient End</label>
                      <input
                        type="color"
                        value={newBanner.gradientEnd}
                        onChange={(e) => setNewBanner({ ...newBanner, gradientEnd: e.target.value })}
                        style={{ width: '100%', height: '38px', borderRadius: '8px', border: '1px solid #cbd5e1', cursor: 'pointer' }}
                      />
                    </div>
                  </div>

                  <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '10px', marginTop: '10px' }}>
                    <button
                      type="button"
                      onClick={() => setShowAddBannerModal(false)}
                      style={{ padding: '8px 16px', backgroundColor: '#f1f5f9', border: '1px solid #cbd5e1', borderRadius: '8px', fontSize: '13px', fontWeight: '600', cursor: 'pointer' }}
                    >
                      Cancel
                    </button>
                    <button
                      type="submit"
                      style={{ padding: '8px 20px', backgroundColor: '#15803d', color: '#ffffff', border: 'none', borderRadius: '8px', fontSize: '13px', fontWeight: '700', cursor: 'pointer' }}
                    >
                      Save Banner
                    </button>
                  </div>
                </form>
              </div>
            </div>
          )}
        </div>
      )}

      {/* ========================================================= */}
      {/* TAB 5: DECLINE MESSAGE TEMPLATES */}
      {/* ========================================================= */}
      {activeTab === 'decline' && (
        <form
          onSubmit={(e) => {
            e.preventDefault();
            const cleaned = (platformForm.workerDeclineTemplates || [])
              .map((t) => String(t || '').trim())
              .filter(Boolean);
            updateSettings({ ...platformForm, workerDeclineTemplates: cleaned });
          }}
          style={{ display: 'flex', flexDirection: 'column', gap: '18px' }}
        >
          <div style={{ backgroundColor: '#ffffff', padding: '22px', borderRadius: '16px', border: '1px solid #e2e8f0' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '8px' }}>
              <MessageSquareText size={18} color="#15803d" />
              <h3 style={{ fontSize: '15.5px', fontWeight: '700', color: '#0f172a', margin: 0 }}>
                Worker Verification Decline Message Templates
              </h3>
            </div>
            <p style={{ fontSize: '12.5px', color: '#64748b', marginBottom: '16px', lineHeight: 1.45 }}>
              Quick-pick templates used in the Approvals queue when rejecting worker verification. The selected reason is delivered via push notification and displayed in the worker's mobile app.
            </p>

            {(platformForm.workerDeclineTemplates || []).map((text, idx) => (
              <div key={idx} style={{ display: 'flex', gap: '8px', marginBottom: '10px' }}>
                <textarea
                  value={text}
                  onChange={(e) => {
                    const next = [...(platformForm.workerDeclineTemplates || [])];
                    next[idx] = e.target.value;
                    setPlatformForm({ ...platformForm, workerDeclineTemplates: next });
                  }}
                  rows={2}
                  style={{
                    flex: 1, padding: '8px 12px', borderRadius: '8px', border: '1px solid #cbd5e1',
                    fontSize: '13px', fontFamily: 'inherit'
                  }}
                />
                <button
                  type="button"
                  onClick={() => {
                    const next = (platformForm.workerDeclineTemplates || []).filter((_, i) => i !== idx);
                    setPlatformForm({ ...platformForm, workerDeclineTemplates: next });
                  }}
                  style={{
                    padding: '8px 10px', borderRadius: '8px', border: '1px solid #fecaca',
                    background: '#fef2f2', color: '#dc2626', cursor: 'pointer', height: 'fit-content'
                  }}
                >
                  <Trash2 size={14} />
                </button>
              </div>
            ))}

            <button
              type="button"
              onClick={() =>
                setPlatformForm({
                  ...platformForm,
                  workerDeclineTemplates: [...(platformForm.workerDeclineTemplates || []), '']
                })
              }
              style={{
                padding: '8px 14px', borderRadius: '8px', border: '1px dashed #94a3b8',
                background: '#f8fafc', fontSize: '13px', fontWeight: '600', color: '#475569', cursor: 'pointer'
              }}
            >
              + Add Template
            </button>
          </div>

          <div style={{ display: 'flex', justifyContent: 'flex-end' }}>
            <button
              type="submit"
              style={{
                display: 'flex', alignItems: 'center', gap: '6px',
                padding: '10px 24px', backgroundColor: '#15803d', color: '#ffffff',
                borderRadius: '8px', fontSize: '13.5px', fontWeight: '700', border: 'none', cursor: 'pointer'
              }}
            >
              <Save size={15} />
              <span>Save Decline Templates</span>
            </button>
          </div>
        </form>
      )}

      {/* ========================================================= */}
      {/* TAB 6: ADMIN IDENTITY & PROFILE */}
      {/* ========================================================= */}
      {activeTab === 'profile' && (
        <form onSubmit={handleSaveProfile} style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
          <div style={{ backgroundColor: '#ffffff', padding: '26px 28px', borderRadius: '16px', border: '1px solid #e2e8f0' }}>
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '20px', borderBottom: '1px solid #f1f5f9', paddingBottom: '14px' }}>
              <div>
                <h3 style={{ fontSize: '16px', fontWeight: '700', color: '#0f172a', margin: 0 }}>
                  Administrator Identity & Avatar
                </h3>
                <p style={{ fontSize: '12.5px', color: '#64748b', margin: '2px 0 0 0' }}>
                  Your official identity displayed across audits, activity logs, and cooperative decrees.
                </p>
              </div>
              <span style={{ fontSize: '11px', fontWeight: '700', color: '#15803d', backgroundColor: '#dcfce7', padding: '4px 10px', borderRadius: '6px' }}>
                Active Session
              </span>
            </div>

            {/* Avatar Row */}
            <div style={{ display: 'flex', alignItems: 'center', gap: '20px', marginBottom: '24px' }}>
              <div style={{ position: 'relative' }}>
                <Avatar
                  src={profileState.avatar}
                  name={profileState.name}
                  size="xl"
                  style={{ width: '80px', height: '80px', fontSize: '26px', border: '3px solid #15803d' }}
                />
                {isUploadingPhoto && (
                  <div style={{ position: 'absolute', inset: 0, backgroundColor: 'rgba(0,0,0,0.4)', borderRadius: '50%', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#fff', fontSize: '11px' }}>
                    ...
                  </div>
                )}
              </div>

              <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
                <div style={{ display: 'flex', gap: '8px', flexWrap: 'wrap' }}>
                  <input
                    type="file"
                    ref={fileInputRef}
                    onChange={handleFileChange}
                    accept="image/*"
                    style={{ display: 'none' }}
                  />
                  <button
                    type="button"
                    onClick={() => fileInputRef.current?.click()}
                    disabled={isUploadingPhoto}
                    style={{
                      display: 'flex', alignItems: 'center', gap: '6px',
                      padding: '7px 14px', backgroundColor: '#eff6ff', color: '#2563eb',
                      border: '1px solid #bfdbfe', borderRadius: '7px', fontSize: '12.5px', fontWeight: '600', cursor: 'pointer'
                    }}
                  >
                    <Camera size={14} />
                    <span>{isUploadingPhoto ? 'Uploading...' : 'Upload Avatar'}</span>
                  </button>

                  <button
                    type="button"
                    onClick={() => setShowUrlInput(!showUrlInput)}
                    style={{
                      display: 'flex', alignItems: 'center', gap: '6px',
                      padding: '7px 14px', backgroundColor: '#f8fafc', color: '#475569',
                      border: '1px solid #cbd5e1', borderRadius: '7px', fontSize: '12.5px', fontWeight: '600', cursor: 'pointer'
                    }}
                  >
                    <LinkIcon size={14} />
                    <span>Image URL</span>
                  </button>

                  {profileState.avatar && (
                    <button
                      type="button"
                      onClick={() => setProfileState({ ...profileState, avatar: '' })}
                      style={{
                        display: 'flex', alignItems: 'center', gap: '4px',
                        padding: '7px 10px', backgroundColor: '#fef2f2', color: '#dc2626',
                        border: '1px solid #fecaca', borderRadius: '7px', fontSize: '12px', cursor: 'pointer'
                      }}
                    >
                      <Trash2 size={13} />
                      <span>Remove</span>
                    </button>
                  )}
                </div>

                {showUrlInput && (
                  <input
                    type="text"
                    placeholder="Paste image URL (https://...)"
                    value={profileState.avatar}
                    onChange={(e) => setProfileState({ ...profileState, avatar: e.target.value })}
                    style={{ width: '320px', padding: '7px 12px', borderRadius: '6px', border: '1px solid #cbd5e1', fontSize: '12px' }}
                  />
                )}
              </div>
            </div>

            {/* Inputs */}
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px' }}>
              <div>
                <label style={{ display: 'block', fontSize: '12.5px', fontWeight: '600', color: '#334155', marginBottom: '5px' }}>Administrator Name</label>
                <input
                  type="text"
                  required
                  value={profileState.name}
                  onChange={(e) => setProfileState({ ...profileState, name: e.target.value })}
                  style={{ width: '100%', padding: '9px 12px', borderRadius: '8px', border: '1px solid #cbd5e1', fontSize: '13.5px' }}
                />
              </div>
              <div>
                <label style={{ display: 'block', fontSize: '12.5px', fontWeight: '600', color: '#334155', marginBottom: '5px' }}>Administrator Official Email</label>
                <input
                  type="email"
                  required
                  value={profileState.email}
                  onChange={(e) => setProfileState({ ...profileState, email: e.target.value })}
                  style={{ width: '100%', padding: '9px 12px', borderRadius: '8px', border: '1px solid #cbd5e1', fontSize: '13.5px' }}
                />
              </div>
            </div>

            <div style={{ display: 'flex', justifyContent: 'flex-end', marginTop: '20px' }}>
              <button
                type="submit"
                style={{
                  display: 'flex', alignItems: 'center', gap: '6px',
                  padding: '10px 24px', backgroundColor: '#15803d', color: '#ffffff',
                  borderRadius: '8px', fontSize: '13.5px', fontWeight: '700', border: 'none', cursor: 'pointer'
                }}
              >
                <Save size={15} />
                <span>Save Profile Changes</span>
              </button>
            </div>
          </div>
        </form>
      )}
    </div>
  );
}
