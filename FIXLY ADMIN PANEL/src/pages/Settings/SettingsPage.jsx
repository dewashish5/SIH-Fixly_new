import React, { useState, useEffect, useRef } from 'react';
import { useSearchParams } from 'react-router-dom';
import { useApp } from '../../context/AppContext';
import { useLanguage } from '../../context/LanguageContext';
import { api } from '../../services/api';
import {
  Settings,
  Shield,
  Bell,
  Sliders,
  Save,
  Globe,
  Lock,
  Percent,
  User,
  CreditCard,
  CheckCircle2,
  MessageSquareText,
  Upload,
  Trash2,
  Camera,
  Link as LinkIcon
} from 'lucide-react';
import Avatar from '../../components/common/Avatar';

export default function SettingsPage() {
  const [searchParams, setSearchParams] = useSearchParams();
  const { settings, fetchSettings, updateSettings, adminUser, updateAdminProfile } = useApp();
  const { language, setLanguage } = useLanguage();

  const tabParam = searchParams.get('tab');
  const [activeTab, setActiveTab] = useState(tabParam || 'platform');

  const fileInputRef = useRef(null);

  // Platform governance form
  const [formState, setFormState] = useState({
    platformCommissionPercent: 5,
    cooperativeWelfarePercent: 5,
    autoDispatchEnabled: true,
    emergencyHotline: '+91 98765 43210',
    emailNotifications: true,
    smsAlerts: true,
    payoutSchedule: 'Instant Automated UPI',
    twoFactorAuth: false,
    workerDeclineTemplates: [
      'Your request to join as a worker has been declined.',
      'Documents unclear or incomplete. Please re-upload clear Aadhaar and PAN photos.',
      'Identity details do not match our records. Please correct and resubmit.',
    ],
    ...settings
  });

  // Admin Profile form
  const [profileState, setProfileState] = useState({
    name: adminUser?.name || 'Administrator',
    email: adminUser?.email || '',
    avatar: adminUser?.avatar || '',
  });
  const [isUploadingPhoto, setIsUploadingPhoto] = useState(false);
  const [showUrlInput, setShowUrlInput] = useState(false);

  useEffect(() => {
    if (tabParam) {
      setActiveTab(tabParam);
    }
  }, [tabParam]);

  useEffect(() => {
    fetchSettings();
  }, [fetchSettings]);

  useEffect(() => {
    if (settings && Object.keys(settings).length > 0) {
      setFormState((prev) => ({
        ...prev,
        ...settings,
        platformCommissionPercent: settings.platformCommissionPercent ?? 5,
        cooperativeWelfarePercent: settings.cooperativeWelfarePercent ?? 5,
        emergencyHotline: settings.emergencyHotline || '+91 98765 43210'
      }));
    }
  }, [settings]);

  useEffect(() => {
    if (adminUser) {
      setProfileState({
        name: adminUser.name || 'Administrator',
        email: adminUser.email || '',
        avatar: adminUser.avatar || '',
      });
    }
  }, [adminUser]);

  const handleSavePlatform = (e) => {
    e.preventDefault();
    updateSettings(formState);
  };

  const handleSaveProfile = async (e) => {
    e.preventDefault();
    await updateAdminProfile(profileState);
  };

  const handleFileChange = async (e) => {
    const file = e.target.files?.[0];
    if (!file) return;

    // Immediately create local preview
    const reader = new FileReader();
    reader.onload = async (evt) => {
      const dataUrl = evt.target?.result;
      setProfileState((prev) => ({ ...prev, avatar: dataUrl }));

      // Try uploading to backend / cloudinary if available
      try {
        setIsUploadingPhoto(true);
        const uploadRes = await api.uploadImage(file);
        if (uploadRes && uploadRes.url) {
          setProfileState((prev) => ({ ...prev, avatar: uploadRes.url }));
        }
      } catch (err) {
        console.warn('Direct image upload failed, keeping base64 dataUrl preview:', err);
      } finally {
        setIsUploadingPhoto(false);
      }
    };
    reader.readAsDataURL(file);
  };

  const platformComm = Number(formState.platformCommissionPercent ?? 5);
  const welfarePercent = Number(formState.cooperativeWelfarePercent ?? 5);
  const workerNetPercent = Math.max(0, 100 - (platformComm + welfarePercent));

  return (
    <div style={{ padding: '0 32px 32px 32px', animation: 'fadeIn 0.2s ease', maxWidth: '920px' }}>
      {/* Header */}
      <div style={{ marginBottom: '20px' }}>
        <h2 style={{ fontSize: '20px', fontWeight: '700', color: '#111827' }}>
          Platform Settings & Governance
        </h2>
        <p style={{ fontSize: '13px', color: '#64748b' }}>
          Cooperative bylaws, administrator profile identity, welfare allocation rates, and security policies
        </p>
      </div>

      {/* Tabs */}
      <div style={{ display: 'flex', gap: '6px', borderBottom: '1px solid var(--border-light)', marginBottom: '20px', overflowX: 'auto' }}>
        {[
          { key: 'platform', label: 'Platform & Cooperative Bylaws', icon: Sliders },
          { key: 'profile', label: 'Admin Profile', icon: User },
          { key: 'decline', label: 'Worker Decline Messages', icon: MessageSquareText },
          { key: 'notifications', label: 'Notification Channels', icon: Bell },
          { key: 'payments', label: 'Payout & Escrow Rules', icon: CreditCard },
          { key: 'security', label: 'Security & Two-Factor', icon: Lock },
          { key: 'roles', label: 'Roles & Permissions', icon: Shield },
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
                padding: '10px 16px',
                fontSize: '13px',
                fontWeight: isActive ? '700' : '500',
                color: isActive ? '#15803d' : '#64748b',
                borderBottom: isActive ? '2.5px solid #15803d' : 'none',
                backgroundColor: 'transparent',
                border: 'none',
                cursor: 'pointer',
                marginBottom: '-1px',
                whiteSpace: 'nowrap',
              }}
            >
              <Icon size={15} />
              <span>{tab.label}</span>
            </button>
          );
        })}
      </div>

      {/* TAB 1: PLATFORM SETTINGS */}
      {activeTab === 'platform' && (
        <form onSubmit={handleSavePlatform} style={{ display: 'flex', flexDirection: 'column', gap: '18px' }}>
          {/* 1. Platform Commission */}
          <div style={{ backgroundColor: '#ffffff', padding: '22px', borderRadius: '16px', border: '1px solid var(--border-light)' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '12px' }}>
              <Percent size={18} color="#1e7e45" />
              <h3 style={{ fontSize: '15px', fontWeight: '700', color: '#111827' }}>
                Platform Maintenance Fee (%)
              </h3>
            </div>
            <p style={{ fontSize: '12.5px', color: '#64748b', marginBottom: '14px', lineHeight: '1.4' }}>
              Base technology operating fee charged to sustain servers, 24/7 client dispatching, and software operations.
            </p>
            <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
              <input
                type="number"
                min="0"
                max="50"
                value={formState.platformCommissionPercent === '' ? '' : formState.platformCommissionPercent}
                onChange={(e) => {
                  const val = e.target.value;
                  setFormState({
                    ...formState,
                    platformCommissionPercent: val === '' ? '' : Number(val)
                  });
                }}
                style={{
                  width: '90px',
                  padding: '8px 12px',
                  borderRadius: '8px',
                  border: '1px solid #cbd5e1',
                  fontSize: '14px',
                  fontWeight: '700',
                }}
              />
              <span style={{ fontSize: '14px', fontWeight: '700', color: '#111827' }}>%</span>
              <span style={{ fontSize: '12px', color: '#2563eb', fontWeight: '600' }}>
                Platform Commission
              </span>
            </div>
          </div>

          {/* 2. Cooperative Welfare Reserve Split */}
          <div style={{ backgroundColor: '#ffffff', padding: '22px', borderRadius: '16px', border: '1px solid var(--border-light)' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '12px' }}>
              <Percent size={18} color="#15803d" />
              <h3 style={{ fontSize: '15px', fontWeight: '700', color: '#111827' }}>
                Cooperative Welfare Reserve Split (%)
              </h3>
            </div>
            <p style={{ fontSize: '12.5px', color: '#64748b', marginBottom: '14px', lineHeight: '1.4' }}>
              Percentage of each booking automatically routed to the Worker Health, Accidental Insurance, and Emergency Pension Pool.
            </p>
            <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
              <input
                type="number"
                min="0"
                max="50"
                value={formState.cooperativeWelfarePercent === '' ? '' : formState.cooperativeWelfarePercent}
                onChange={(e) => {
                  const val = e.target.value;
                  setFormState({
                    ...formState,
                    cooperativeWelfarePercent: val === '' ? '' : Number(val)
                  });
                }}
                style={{
                  width: '90px',
                  padding: '8px 12px',
                  borderRadius: '8px',
                  border: '1px solid #cbd5e1',
                  fontSize: '14px',
                  fontWeight: '700',
                }}
              />
              <span style={{ fontSize: '14px', fontWeight: '700', color: '#111827' }}>%</span>
              <span style={{ fontSize: '12px', color: '#15803d', fontWeight: '700' }}>
                (Remaining {workerNetPercent}% goes directly to the service provider via instant UPI)
              </span>
            </div>
          </div>

          <div style={{ backgroundColor: '#ffffff', padding: '22px', borderRadius: '16px', border: '1px solid var(--border-light)' }}>
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
              <div>
                <h3 style={{ fontSize: '15px', fontWeight: '700', color: '#111827' }}>
                  Automated Fair Dispatch & Rotation Engine
                </h3>
                <p style={{ fontSize: '12.5px', color: '#64748b', marginTop: '3px' }}>
                  Prevents monopoly by distributing high-value gig calls equitably among verified cooperative members.
                </p>
              </div>
              <input
                type="checkbox"
                checked={formState.autoDispatchEnabled}
                onChange={(e) => setFormState({ ...formState, autoDispatchEnabled: e.target.checked })}
                style={{ width: '20px', height: '20px', accentColor: '#1e7e45', cursor: 'pointer' }}
              />
            </div>
          </div>

          <div style={{ backgroundColor: '#ffffff', padding: '22px', borderRadius: '16px', border: '1px solid var(--border-light)' }}>
            <h3 style={{ fontSize: '15px', fontWeight: '700', color: '#111827', marginBottom: '8px' }}>
              Emergency SOS Dispatch Hotline
            </h3>
            <input
              type="text"
              value={formState.emergencyHotline}
              onChange={(e) => setFormState({ ...formState, emergencyHotline: e.target.value })}
              style={{
                width: '320px',
                padding: '8px 12px',
                borderRadius: '8px',
                border: '1px solid #cbd5e1',
                fontSize: '13px',
              }}
            />
          </div>

          <div style={{ display: 'flex', justifyContent: 'flex-end', marginTop: '10px' }}>
            <button
              type="submit"
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: '6px',
                padding: '10px 24px',
                backgroundColor: '#15803d',
                color: '#ffffff',
                borderRadius: '8px',
                fontSize: '13.5px',
                fontWeight: '700',
                border: 'none',
                cursor: 'pointer',
                boxShadow: '0 2px 4px rgba(21, 128, 61, 0.2)',
              }}
            >
              <Save size={15} />
              <span>Save Platform Preferences</span>
            </button>
          </div>
        </form>
      )}

      {activeTab === 'decline' && (
        <form
          onSubmit={(e) => {
            e.preventDefault();
            const cleaned = (formState.workerDeclineTemplates || [])
              .map((t) => String(t || '').trim())
              .filter(Boolean);
            updateSettings({ ...formState, workerDeclineTemplates: cleaned.length ? cleaned : formState.workerDeclineTemplates });
          }}
          style={{ display: 'flex', flexDirection: 'column', gap: '18px' }}
        >
          <div style={{ backgroundColor: '#ffffff', padding: '22px', borderRadius: '16px', border: '1px solid var(--border-light)' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '8px' }}>
              <MessageSquareText size={18} color="#1e7e45" />
              <h3 style={{ fontSize: '15px', fontWeight: '700', color: '#111827' }}>
                Worker decline message templates
              </h3>
            </div>
            <p style={{ fontSize: '12.5px', color: '#64748b', marginBottom: '14px', lineHeight: 1.45 }}>
              Shown as quick picks on Approvals → Decline. Admin can still edit the text before confirming. Flutter verification screen shows the final message.
            </p>
            {(formState.workerDeclineTemplates || []).map((text, idx) => (
              <div key={idx} style={{ display: 'flex', gap: 8, marginBottom: 10 }}>
                <textarea
                  value={text}
                  onChange={(e) => {
                    const next = [...(formState.workerDeclineTemplates || [])];
                    next[idx] = e.target.value;
                    setFormState({ ...formState, workerDeclineTemplates: next });
                  }}
                  rows={2}
                  style={{
                    flex: 1,
                    padding: '8px 12px',
                    borderRadius: 8,
                    border: '1px solid #cbd5e1',
                    fontSize: 13,
                    fontFamily: 'inherit',
                  }}
                />
                <button
                  type="button"
                  onClick={() => {
                    const next = (formState.workerDeclineTemplates || []).filter((_, i) => i !== idx);
                    setFormState({ ...formState, workerDeclineTemplates: next });
                  }}
                  style={{
                    padding: '8px 10px',
                    borderRadius: 8,
                    border: '1px solid #fecaca',
                    background: '#fef2f2',
                    color: '#dc2626',
                    cursor: 'pointer',
                    height: 'fit-content',
                  }}
                  aria-label="Remove template"
                >
                  <Trash2 size={14} />
                </button>
              </div>
            ))}
            <button
              type="button"
              onClick={() =>
                setFormState({
                  ...formState,
                  workerDeclineTemplates: [...(formState.workerDeclineTemplates || []), ''],
                })
              }
              style={{
                padding: '8px 12px',
                borderRadius: 8,
                border: '1px dashed #94a3b8',
                background: '#f8fafc',
                fontSize: 13,
                fontWeight: 600,
                color: '#475569',
                cursor: 'pointer',
              }}
            >
              + Add template
            </button>
          </div>
          <div style={{ display: 'flex', justifyContent: 'flex-end' }}>
            <button
              type="submit"
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: 6,
                padding: '10px 24px',
                backgroundColor: '#15803d',
                color: '#fff',
                borderRadius: 8,
                fontSize: 13.5,
                fontWeight: 700,
                border: 'none',
                cursor: 'pointer',
              }}
            >
              <Save size={15} />
              Save decline templates
            </button>
          </div>
        </form>
      )}

      {/* TAB 2: ADMIN PROFILE SECTION (REAL DATA & CUSTOM IMAGE SETTING) */}
      {activeTab === 'profile' && (
        <form onSubmit={handleSaveProfile} style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
          <div style={{ backgroundColor: '#ffffff', padding: '26px 28px', borderRadius: '16px', border: '1px solid var(--border-light)', boxShadow: 'var(--shadow-card)' }}>
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '20px', borderBottom: '1px solid #f1f5f9', paddingBottom: '14px' }}>
              <div>
                <h3 style={{ fontSize: '16px', fontWeight: '700', color: '#111827' }}>
                  Admin Profile & Avatar Customization
                </h3>
                <p style={{ fontSize: '12.5px', color: '#64748b', marginTop: '2px' }}>
                  Set your official administrator photo, display name, and system credentials
                </p>
              </div>
              <span style={{ fontSize: '11px', fontWeight: '700', color: '#15803d', backgroundColor: '#eaf7ee', padding: '4px 10px', borderRadius: '6px' }}>
                Role: Super Admin
              </span>
            </div>

            {/* Profile Avatar Control */}
            <div style={{ display: 'flex', alignItems: 'center', gap: '24px', marginBottom: '24px', flexWrap: 'wrap' }}>
              <div style={{ position: 'relative' }}>
                <Avatar
                  src={profileState.avatar}
                  name={profileState.name}
                  size={88}
                  style={{
                    border: '3px solid #22c55e',
                    boxShadow: '0 4px 14px rgba(34, 197, 94, 0.25)',
                  }}
                />
              </div>

              <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '10px', flexWrap: 'wrap' }}>
                  <input
                    ref={fileInputRef}
                    type="file"
                    accept="image/*"
                    onChange={handleFileChange}
                    style={{ display: 'none' }}
                  />

                  <button
                    type="button"
                    onClick={() => fileInputRef.current?.click()}
                    disabled={isUploadingPhoto}
                    style={{
                      display: 'flex',
                      alignItems: 'center',
                      gap: '6px',
                      padding: '8px 16px',
                      backgroundColor: 'var(--primary-brand)',
                      color: '#ffffff',
                      borderRadius: '8px',
                      fontSize: '13px',
                      fontWeight: '600',
                      cursor: 'pointer',
                      border: 'none',
                    }}
                  >
                    <Upload size={14} />
                    <span>{isUploadingPhoto ? 'Uploading...' : 'Upload New Photo'}</span>
                  </button>

                  <button
                    type="button"
                    onClick={() => setShowUrlInput(!showUrlInput)}
                    style={{
                      display: 'flex',
                      alignItems: 'center',
                      gap: '6px',
                      padding: '8px 14px',
                      backgroundColor: '#f8fafc',
                      color: '#334155',
                      border: '1px solid #cbd5e1',
                      borderRadius: '8px',
                      fontSize: '13px',
                      fontWeight: '500',
                      cursor: 'pointer',
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
                        display: 'flex',
                        alignItems: 'center',
                        gap: '6px',
                        padding: '8px 12px',
                        backgroundColor: '#fef2f2',
                        color: '#dc2626',
                        border: '1px solid #fecaca',
                        borderRadius: '8px',
                        fontSize: '12.5px',
                        fontWeight: '600',
                        cursor: 'pointer',
                      }}
                    >
                      <Trash2 size={13} />
                      <span>Remove Photo</span>
                    </button>
                  )}
                </div>

                <div style={{ fontSize: '11.5px', color: '#64748b' }}>
                  Supports PNG, JPG, or WEBP. If no picture is provided, clean admin initials are displayed.
                </div>

                {showUrlInput && (
                  <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginTop: '4px' }}>
                    <input
                      type="text"
                      placeholder="Paste image URL (https://...)"
                      value={profileState.avatar}
                      onChange={(e) => setProfileState({ ...profileState, avatar: e.target.value })}
                      style={{
                        width: '320px',
                        padding: '7px 12px',
                        borderRadius: '6px',
                        border: '1px solid #cbd5e1',
                        fontSize: '12px',
                      }}
                    />
                  </div>
                )}
              </div>
            </div>

            {/* Form Inputs */}
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '18px' }}>
              <div>
                <label style={{ fontSize: '12.5px', fontWeight: '600', color: '#334155', display: 'block', marginBottom: '6px' }}>
                  Administrator Full Name
                </label>
                <input
                  type="text"
                  required
                  value={profileState.name}
                  onChange={(e) => setProfileState({ ...profileState, name: e.target.value })}
                  placeholder="e.g. Rajesh Kumar"
                  style={{
                    width: '100%',
                    padding: '9px 14px',
                    borderRadius: '8px',
                    border: '1px solid #cbd5e1',
                    fontSize: '13.5px',
                    color: '#0f172a',
                    outline: 'none',
                  }}
                />
              </div>

              <div>
                <label style={{ fontSize: '12.5px', fontWeight: '600', color: '#334155', display: 'block', marginBottom: '6px' }}>
                  Administrator Official Email
                </label>
                <input
                  type="email"
                  required
                  value={profileState.email}
                  onChange={(e) => setProfileState({ ...profileState, email: e.target.value })}
                  placeholder="admin@cooperative.org"
                  style={{
                    width: '100%',
                    padding: '9px 14px',
                    borderRadius: '8px',
                    border: '1px solid #cbd5e1',
                    fontSize: '13.5px',
                    color: '#0f172a',
                    outline: 'none',
                  }}
                />
              </div>
            </div>

            <div style={{ display: 'flex', justifyContent: 'flex-end', marginTop: '24px' }}>
              <button
                type="submit"
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: '6px',
                  padding: '10px 22px',
                  backgroundColor: '#15803d',
                  color: '#ffffff',
                  borderRadius: '8px',
                  fontSize: '13.5px',
                  fontWeight: '700',
                  border: 'none',
                  cursor: 'pointer',
                  boxShadow: '0 2px 4px rgba(21, 128, 61, 0.25)',
                }}
              >
                <Save size={15} />
                <span>Save Profile Changes</span>
              </button>
            </div>
          </div>
        </form>
      )}

      {/* TAB 3: NOTIFICATIONS */}
      {activeTab === 'notifications' && (
        <div style={{ backgroundColor: '#ffffff', padding: '22px', borderRadius: '16px', border: '1px solid var(--border-light)', display: 'flex', flexDirection: 'column', gap: '14px' }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
            <div>
              <div style={{ fontSize: '13.5px', fontWeight: '600', color: '#1e293b' }}>
                Email Notifications for New Bookings
              </div>
              <div style={{ fontSize: '12px', color: '#64748b' }}>Receive instant email copy for high-value orders and cancellations.</div>
            </div>
            <input
              type="checkbox"
              checked={formState.emailNotifications}
              onChange={(e) => setFormState({ ...formState, emailNotifications: e.target.checked })}
              style={{ width: '18px', height: '18px', accentColor: '#1e7e45' }}
            />
          </div>

          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
            <div>
              <div style={{ fontSize: '13.5px', fontWeight: '600', color: '#1e293b' }}>
                SMS / WhatsApp Gateway Alerts
              </div>
              <div style={{ fontSize: '12px', color: '#64748b' }}>Dispatch SMS confirmations to workers and OTPs to customers.</div>
            </div>
            <input
              type="checkbox"
              checked={formState.smsAlerts}
              onChange={(e) => setFormState({ ...formState, smsAlerts: e.target.checked })}
              style={{ width: '18px', height: '18px', accentColor: '#1e7e45' }}
            />
          </div>
        </div>
      )}

      {/* TAB 4: PAYMENTS */}
      {activeTab === 'payments' && (
        <div style={{ backgroundColor: '#ffffff', padding: '22px', borderRadius: '16px', border: '1px solid var(--border-light)' }}>
          <h3 style={{ fontSize: '15px', fontWeight: '700', color: '#111827', marginBottom: '12px' }}>
            Automated Payout & Escrow Window
          </h3>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '12px', fontSize: '13px' }}>
            <div>
              <label style={{ fontSize: '12px', fontWeight: '600', color: '#475569', display: 'block', marginBottom: '4px' }}>
                Settlement Method
              </label>
              <select
                value={formState.payoutSchedule}
                onChange={(e) => setFormState({ ...formState, payoutSchedule: e.target.value })}
                style={{ width: '280px', padding: '8px 12px', borderRadius: '8px', border: '1px solid #cbd5e1', fontSize: '13px', backgroundColor: '#ffffff' }}
              >
                <option value="Instant Automated UPI">Instant Automated UPI (Recommended)</option>
                <option value="Daily Batch Settlement">Daily Batch Settlement (Midnight)</option>
                <option value="Weekly Wednesday Cycle">Weekly Cycle (Wednesday)</option>
              </select>
            </div>
          </div>
        </div>
      )}

      {/* TAB 5: SECURITY */}
      {activeTab === 'security' && (
        <div style={{ backgroundColor: '#ffffff', padding: '22px', borderRadius: '16px', border: '1px solid var(--border-light)' }}>
          <h3 style={{ fontSize: '15px', fontWeight: '700', color: '#111827', marginBottom: '12px' }}>
            Security & Audit Access Controls
          </h3>
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px', color: '#15803d', fontWeight: '600', fontSize: '13px' }}>
            <CheckCircle2 size={16} />
            <span>Two-Factor Authentication (2FA) is Active for Admin Account</span>
          </div>
        </div>
      )}

      {/* TAB 6: ROLES */}
      {activeTab === 'roles' && (
        <div style={{ backgroundColor: '#ffffff', padding: '22px', borderRadius: '16px', border: '1px solid var(--border-light)' }}>
          <h3 style={{ fontSize: '15px', fontWeight: '700', color: '#111827', marginBottom: '12px' }}>
            Admin Roles & Multi-Level Delegation
          </h3>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '8px', fontSize: '13px' }}>
            <div style={{ padding: '10px 14px', backgroundColor: '#f8faf9', borderRadius: '8px', display: 'flex', justifyContent: 'space-between' }}>
              <div><strong>Super Admin</strong> (Full Access to Escrow & Welfare Pool)</div>
              <span style={{ color: '#15803d', fontWeight: '700' }}>Active</span>
            </div>
            <div style={{ padding: '10px 14px', backgroundColor: '#f8faf9', borderRadius: '8px', display: 'flex', justifyContent: 'space-between' }}>
              <div><strong>Field Dispatch Supervisor</strong> (Manage Bookings & Worker Dispatch)</div>
              <span style={{ color: '#0284c7', fontWeight: '600' }}>Active</span>
            </div>
            <div style={{ padding: '10px 14px', backgroundColor: '#f8faf9', borderRadius: '8px', display: 'flex', justifyContent: 'space-between' }}>
              <div><strong>Welfare & Claims Auditor</strong> (Review Insurance Claims)</div>
              <span style={{ color: '#0284c7', fontWeight: '600' }}>Active</span>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
