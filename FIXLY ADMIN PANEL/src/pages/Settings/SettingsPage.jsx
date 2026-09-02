import React, { useState } from 'react';
import { useApp } from '../../context/AppContext';
import { useLanguage } from '../../context/LanguageContext';
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
  CheckCircle2
} from 'lucide-react';

export default function SettingsPage() {
  const { settings, fetchSettings, updateSettings } = useApp();
  const { language, setLanguage } = useLanguage();

  const [activeTab, setActiveTab] = useState('platform');
  const [formState, setFormState] = useState({
    platformCommissionPercent: 5,
    cooperativeWelfarePercent: 5,
    autoDispatchEnabled: true,
    emergencyHotline: '+91 98765 43210',
    emailNotifications: true,
    smsAlerts: true,
    payoutSchedule: 'Instant Automated UPI',
    twoFactorAuth: false,
    ...settings
  });

  React.useEffect(() => {
    fetchSettings();
  }, [fetchSettings]);

  React.useEffect(() => {
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

  const handleSave = (e) => {
    e.preventDefault();
    updateSettings(formState);
  };

  const platformComm = Number(formState.platformCommissionPercent ?? 5);
  const welfarePercent = Number(formState.cooperativeWelfarePercent ?? 5);
  const workerNetPercent = Math.max(0, 100 - (platformComm + welfarePercent));

  return (
    <div style={{ padding: '0 32px 32px 32px', animation: 'fadeIn 0.2s ease', maxWidth: '900px' }}>
      {/* Header */}
      <div style={{ marginBottom: '20px' }}>
        <h2 style={{ fontSize: '20px', fontWeight: '700', color: '#111827' }}>
          Platform Settings & Governance
        </h2>
        <p style={{ fontSize: '13px', color: '#64748b' }}>
          Cooperative bylaws, platform commission, welfare allocation rates, security policies, and notification channels
        </p>
      </div>

      {/* Tabs */}
      <div style={{ display: 'flex', gap: '6px', borderBottom: '1px solid var(--border-light)', marginBottom: '20px', overflowX: 'auto' }}>
        {[
          { key: 'platform', label: 'Platform & Cooperative Bylaws', icon: Sliders },
          { key: 'profile', label: 'Admin Profile', icon: User },
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
              onClick={() => setActiveTab(tab.key)}
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

      {/* Settings Form */}
      <form onSubmit={handleSave} style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
        {/* Tab 1: Platform & Bylaws */}
        {activeTab === 'platform' && (
          <>
            {/* 1. Platform Commission Split */}
            <div style={{ backgroundColor: '#ffffff', padding: '22px', borderRadius: '16px', border: '1px solid var(--border-light)' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '12px' }}>
                <Percent size={18} color="#15803d" />
                <h3 style={{ fontSize: '15px', fontWeight: '700', color: '#111827' }}>
                  Platform Commission Fee (%)
                </h3>
              </div>
              <p style={{ fontSize: '12.5px', color: '#64748b', marginBottom: '14px', lineHeight: '1.4' }}>
                Percentage of each booking transaction retained for Platform Infrastructure, Cloud Hosting, Maintenance, and Support.
              </p>
              <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
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
          </>
        )}

        {/* Tab 2: Profile */}
        {activeTab === 'profile' && (
          <div style={{ backgroundColor: '#ffffff', padding: '22px', borderRadius: '16px', border: '1px solid var(--border-light)' }}>
            <h3 style={{ fontSize: '15px', fontWeight: '700', color: '#111827', marginBottom: '16px' }}>
              Administrator Account Credentials
            </h3>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '14px' }}>
              <div>
                <label style={{ fontSize: '12px', fontWeight: '600', color: '#475569', display: 'block', marginBottom: '4px' }}>
                  Admin Name
                </label>
                <input
                  type="text"
                  defaultValue="Super Administrator"
                  style={{ width: '100%', padding: '8px 12px', borderRadius: '8px', border: '1px solid #cbd5e1', fontSize: '13px' }}
                />
              </div>

              <div>
                <label style={{ fontSize: '12px', fontWeight: '600', color: '#475569', display: 'block', marginBottom: '4px' }}>
                  Admin Email
                </label>
                <input
                  type="email"
                  defaultValue="admin@cooperative.org"
                  style={{ width: '100%', padding: '8px 12px', borderRadius: '8px', border: '1px solid #cbd5e1', fontSize: '13px' }}
                />
              </div>
            </div>
          </div>
        )}

        {/* Tab 3: Notifications */}
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

        {/* Tab 4: Payments */}
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

        {/* Tab 5: Security */}
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

        {/* Tab 6: Roles & Permissions */}
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
                <span style={{ color: '#0284c7', fontWeight: '600' }}>4 Officers</span>
              </div>
              <div style={{ padding: '10px 14px', backgroundColor: '#f8faf9', borderRadius: '8px', display: 'flex', justifyContent: 'space-between' }}>
                <div><strong>Welfare & Claims Auditor</strong> (Review Insurance Claims)</div>
                <span style={{ color: '#0284c7', fontWeight: '600' }}>2 Officers</span>
              </div>
            </div>
          </div>
        )}

        {/* Save Button */}
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
    </div>
  );
}
