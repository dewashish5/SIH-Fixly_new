import React, { useState, useEffect } from 'react';
import {
  Settings,
  Shield,
  Sliders,
  Save,
  Percent,
  Smartphone,
  Database,
  RefreshCw,
  Trash2,
  CheckCircle2,
  AlertCircle,
  Zap,
  ExternalLink
} from 'lucide-react';
import { api } from '../services/api';

export default function SettingsView() {
  // Platform settings state
  const [welfarePercent, setWelfarePercent] = useState('5');
  const [emergencyHotline, setEmergencyHotline] = useState('1800-456-GIGS');
  const [autoDispatch, setAutoDispatch] = useState(true);
  const [isSavingPlatform, setIsSavingPlatform] = useState(false);

  // App Version state
  const [apiVersion, setApiVersion] = useState('V1');
  const [appVersion, setAppVersion] = useState('1.0.0');
  const [minVersion, setMinVersion] = useState('V1');
  const [forceUpdate, setForceUpdate] = useState(false);
  const [updateTitle, setUpdateTitle] = useState('Update Available');
  const [updateMessage, setUpdateMessage] = useState('A new version of Fixly is available. Please update the app to continue.');
  const [updateUrl, setUpdateUrl] = useState('https://play.google.com/store/apps/details?id=com.fixly.app');
  const [platform, setPlatform] = useState('all');
  const [isSavingVersion, setIsSavingVersion] = useState(false);

  // Redis cache state
  const [redisLoading, setRedisLoading] = useState(false);
  const [activeRedisAction, setActiveRedisAction] = useState('');

  // Status / feedback banners
  const [statusMessage, setStatusMessage] = useState({ type: '', text: '' });

  // Load initial settings and app version
  useEffect(() => {
    loadSettingsAndVersion();
  }, []);

  const loadSettingsAndVersion = async () => {
    try {
      // 1. Fetch platform settings
      const settingsRes = await api.getSettings().catch(() => null);
      if (settingsRes?.settings) {
        const s = settingsRes.settings;
        if (s.cooperativeWelfarePercent !== undefined) setWelfarePercent(String(s.cooperativeWelfarePercent));
        if (s.emergencyHotline) setEmergencyHotline(s.emergencyHotline);
        if (s.autoDispatchEnabled !== undefined) setAutoDispatch(Boolean(s.autoDispatchEnabled));
      }

      // 2. Fetch app version
      const versionRes = await api.getAppVersion().catch(() => null);
      if (versionRes?.version) {
        const v = versionRes.version;
        if (v.apiVersion) setApiVersion(v.apiVersion);
        if (v.appVersion) setAppVersion(v.appVersion);
        if (v.minVersion) setMinVersion(v.minVersion);
        if (v.forceUpdate !== undefined) setForceUpdate(Boolean(v.forceUpdate));
        if (v.updateTitle) setUpdateTitle(v.updateTitle);
        if (v.updateMessage) setUpdateMessage(v.updateMessage);
        if (v.updateUrl) setUpdateUrl(v.updateUrl);
        if (v.platform) setPlatform(v.platform);
      }
    } catch (err) {
      console.warn('Failed to load initial settings:', err);
    }
  };

  const showNotification = (type, text) => {
    setStatusMessage({ type, text });
    setTimeout(() => {
      setStatusMessage({ type: '', text: '' });
    }, 5000);
  };

  // Save Platform Settings
  const handleSavePlatform = async () => {
    try {
      setIsSavingPlatform(true);
      await api.updateSettings({
        cooperativeWelfarePercent: Number(welfarePercent) || 0,
        emergencyHotline,
        autoDispatchEnabled: autoDispatch
      });
      showNotification('success', 'Platform governance preferences saved successfully!');
    } catch (err) {
      showNotification('error', err.response?.data?.message || 'Failed to save platform preferences');
    } finally {
      setIsSavingPlatform(false);
    }
  };

  // Save App Version Settings & Sync Redis
  const handleSaveVersion = async () => {
    try {
      setIsSavingVersion(true);
      const res = await api.updateAppVersion({
        apiVersion: apiVersion.trim(),
        appVersion: appVersion.trim(),
        minVersion: minVersion.trim(),
        forceUpdate,
        updateTitle: updateTitle.trim(),
        updateMessage: updateMessage.trim(),
        updateUrl: updateUrl.trim(),
        platform
      });
      showNotification('success', res.message || `App version updated to ${apiVersion} and synced to Redis!`);
    } catch (err) {
      showNotification('error', err.response?.data?.message || 'Failed to update app version');
    } finally {
      setIsSavingVersion(false);
    }
  };

  // Clear / Flush Redis Cache
  const handleClearRedis = async (type) => {
    const isFullFlush = type === 'all';
    if (isFullFlush && !window.confirm('Are you sure you want to FLUSH all Redis cache? This will clear all active sessions, temporary caches, and catalogs.')) {
      return;
    }

    try {
      setRedisLoading(true);
      setActiveRedisAction(type);
      const res = await api.clearRedisCache(type);
      showNotification('success', res.message || `Redis cache cleared for ${type}!`);
    } catch (err) {
      showNotification('error', err.response?.data?.message || `Failed to clear Redis cache for ${type}`);
    } finally {
      setRedisLoading(false);
      setActiveRedisAction('');
    }
  };

  return (
    <div style={{ padding: '0 32px 32px 32px', animation: 'fadeIn 0.2s ease', maxWidth: '900px' }}>
      <div style={{ marginBottom: '20px' }}>
        <h2 style={{ fontSize: '22px', fontWeight: '700', color: '#111827' }}>
          Platform Settings & System Controls
        </h2>
        <p style={{ fontSize: '13px', color: '#64748b' }}>
          Mobile app versioning, Redis cache invalidation, and platform governance
        </p>
      </div>

      {/* Global Status Banner */}
      {statusMessage.text && (
        <div
          style={{
            marginBottom: '16px',
            padding: '12px 16px',
            borderRadius: '10px',
            display: 'flex',
            alignItems: 'center',
            gap: '10px',
            fontSize: '13.5px',
            fontWeight: '500',
            backgroundColor: statusMessage.type === 'success' ? '#f0fdf4' : '#fef2f2',
            color: statusMessage.type === 'success' ? '#15803d' : '#b91c1c',
            border: `1px solid ${statusMessage.type === 'success' ? '#bbf7d0' : '#fecaca'}`
          }}
        >
          {statusMessage.type === 'success' ? <CheckCircle2 size={18} /> : <AlertCircle size={18} />}
          <span>{statusMessage.text}</span>
        </div>
      )}

      <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>

        {/* SECTION 1: Mobile App Version & Force Update Governance */}
        <div style={{ backgroundColor: '#ffffff', padding: '24px', borderRadius: '16px', border: '1px solid var(--border-light)', boxShadow: '0 1px 3px rgba(0,0,0,0.05)' }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '14px' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
              <div style={{ padding: '8px', borderRadius: '8px', backgroundColor: '#eef2ff' }}>
                <Smartphone size={20} color="#4f46e5" />
              </div>
              <div>
                <h3 style={{ fontSize: '16px', fontWeight: '700', color: '#111827' }}>
                  Mobile App Version & Update Engine
                </h3>
                <p style={{ fontSize: '12.5px', color: '#64748b' }}>
                  Flutter mobile app verifies this on splash screen. Synchronized directly with Redis cache.
                </p>
              </div>
            </div>
            <span
              style={{
                fontSize: '12px',
                fontWeight: '700',
                padding: '4px 10px',
                borderRadius: '20px',
                backgroundColor: '#e0e7ff',
                color: '#3730a3'
              }}
            >
              Current Active: {apiVersion}
            </span>
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: '14px', marginBottom: '16px' }}>
            {/* API Version */}
            <div>
              <label style={{ display: 'block', fontSize: '12px', fontWeight: '600', color: '#374151', marginBottom: '6px' }}>
                Backend API Version (e.g. V1, V2)
              </label>
              <input
                type="text"
                value={apiVersion}
                onChange={(e) => setApiVersion(e.target.value)}
                placeholder="V1"
                style={{
                  width: '100%',
                  padding: '9px 12px',
                  borderRadius: '8px',
                  border: '1px solid #cbd5e1',
                  fontSize: '14px',
                  fontWeight: '700',
                  color: '#1e293b'
                }}
              />
            </div>

            {/* Semantic App Version */}
            <div>
              <label style={{ display: 'block', fontSize: '12px', fontWeight: '600', color: '#374151', marginBottom: '6px' }}>
                Mobile App Version Code (Semver)
              </label>
              <input
                type="text"
                value={appVersion}
                onChange={(e) => setAppVersion(e.target.value)}
                placeholder="1.0.0"
                style={{
                  width: '100%',
                  padding: '9px 12px',
                  borderRadius: '8px',
                  border: '1px solid #cbd5e1',
                  fontSize: '14px'
                }}
              />
            </div>

            {/* Minimum Supported Version */}
            <div>
              <label style={{ display: 'block', fontSize: '12px', fontWeight: '600', color: '#374151', marginBottom: '6px' }}>
                Minimum Supported Version
              </label>
              <input
                type="text"
                value={minVersion}
                onChange={(e) => setMinVersion(e.target.value)}
                placeholder="V1"
                style={{
                  width: '100%',
                  padding: '9px 12px',
                  borderRadius: '8px',
                  border: '1px solid #cbd5e1',
                  fontSize: '14px'
                }}
              />
            </div>

            {/* Platform Scope */}
            <div>
              <label style={{ display: 'block', fontSize: '12px', fontWeight: '600', color: '#374151', marginBottom: '6px' }}>
                Platform Scope
              </label>
              <select
                value={platform}
                onChange={(e) => setPlatform(e.target.value)}
                style={{
                  width: '100%',
                  padding: '9px 12px',
                  borderRadius: '8px',
                  border: '1px solid #cbd5e1',
                  fontSize: '14px',
                  backgroundColor: '#ffffff'
                }}
              >
                <option value="all">All Platforms (Android & iOS)</option>
                <option value="android">Android Only</option>
                <option value="ios">iOS Only</option>
              </select>
            </div>
          </div>

          {/* Force Update Toggle */}
          <div
            style={{
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'space-between',
              padding: '14px 16px',
              borderRadius: '10px',
              backgroundColor: '#f8fafc',
              border: '1px solid #e2e8f0',
              marginBottom: '16px'
            }}
          >
            <div>
              <div style={{ fontSize: '13.5px', fontWeight: '700', color: '#1e293b' }}>
                Enforce Mandatory Update (Force Update)
              </div>
              <div style={{ fontSize: '12px', color: '#64748b', marginTop: '2px' }}>
                If enabled, users on older versions cannot bypass the splash screen update modal.
              </div>
            </div>
            <input
              type="checkbox"
              checked={forceUpdate}
              onChange={(e) => setForceUpdate(e.target.checked)}
              style={{ width: '22px', height: '22px', accentColor: '#4f46e5', cursor: 'pointer' }}
            />
          </div>

          {/* Update Modal Content */}
          <div style={{ display: 'grid', gridTemplateColumns: '1fr', gap: '12px', marginBottom: '16px' }}>
            <div>
              <label style={{ display: 'block', fontSize: '12px', fontWeight: '600', color: '#374151', marginBottom: '6px' }}>
                Update Modal Title
              </label>
              <input
                type="text"
                value={updateTitle}
                onChange={(e) => setUpdateTitle(e.target.value)}
                placeholder="Update Available"
                style={{
                  width: '100%',
                  padding: '9px 12px',
                  borderRadius: '8px',
                  border: '1px solid #cbd5e1',
                  fontSize: '13.5px'
                }}
              />
            </div>

            <div>
              <label style={{ display: 'block', fontSize: '12px', fontWeight: '600', color: '#374151', marginBottom: '6px' }}>
                Update Modal Notice Message
              </label>
              <textarea
                rows={2}
                value={updateMessage}
                onChange={(e) => setUpdateMessage(e.target.value)}
                placeholder="A new version of Fixly is available. Please update to continue."
                style={{
                  width: '100%',
                  padding: '9px 12px',
                  borderRadius: '8px',
                  border: '1px solid #cbd5e1',
                  fontSize: '13px',
                  resize: 'vertical'
                }}
              />
            </div>

            <div>
              <label style={{ display: 'block', fontSize: '12px', fontWeight: '600', color: '#374151', marginBottom: '6px' }}>
                App Store / Play Store / APK Download Link
              </label>
              <input
                type="text"
                value={updateUrl}
                onChange={(e) => setUpdateUrl(e.target.value)}
                placeholder="https://play.google.com/store/apps/details?id=com.fixly.app"
                style={{
                  width: '100%',
                  padding: '9px 12px',
                  borderRadius: '8px',
                  border: '1px solid #cbd5e1',
                  fontSize: '13px'
                }}
              />
            </div>
          </div>

          <div style={{ display: 'flex', justifyContent: 'flex-end' }}>
            <button
              onClick={handleSaveVersion}
              disabled={isSavingVersion}
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: '8px',
                padding: '10px 22px',
                backgroundColor: '#4f46e5',
                color: '#ffffff',
                border: 'none',
                borderRadius: '8px',
                fontSize: '13.5px',
                fontWeight: '600',
                cursor: isSavingVersion ? 'not-allowed' : 'pointer',
                opacity: isSavingVersion ? 0.7 : 1
              }}
            >
              <Save size={16} />
              <span>{isSavingVersion ? 'Saving & Syncing Redis...' : 'Save App Version & Sync Redis'}</span>
            </button>
          </div>
        </div>

        {/* SECTION 2: Redis Cache Control Center */}
        <div style={{ backgroundColor: '#ffffff', padding: '24px', borderRadius: '16px', border: '1px solid var(--border-light)', boxShadow: '0 1px 3px rgba(0,0,0,0.05)' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '8px' }}>
            <div style={{ padding: '8px', borderRadius: '8px', backgroundColor: '#fef3c7' }}>
              <Database size={20} color="#d97706" />
            </div>
            <div>
              <h3 style={{ fontSize: '16px', fontWeight: '700', color: '#111827' }}>
                Redis Cache Control Center
              </h3>
              <p style={{ fontSize: '12.5px', color: '#64748b' }}>
                Instantly clear Redis keys after direct database edits in AWS or for staging tests.
              </p>
            </div>
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '12px', marginTop: '16px' }}>
            {/* Clear User Cache */}
            <div style={{ padding: '14px', borderRadius: '10px', border: '1px solid #e2e8f0', backgroundColor: '#f8fafc' }}>
              <div style={{ fontSize: '13px', fontWeight: '700', color: '#1e293b', marginBottom: '4px' }}>
                User Cache
              </div>
              <div style={{ fontSize: '11.5px', color: '#64748b', marginBottom: '10px' }}>
                Keys: <code>user:*</code>, <code>session:*</code>, <code>otp:*</code>
              </div>
              <button
                onClick={() => handleClearRedis('user')}
                disabled={redisLoading}
                style={{
                  width: '100%',
                  padding: '7px 12px',
                  borderRadius: '6px',
                  border: '1px solid #cbd5e1',
                  backgroundColor: '#ffffff',
                  color: '#334155',
                  fontSize: '12px',
                  fontWeight: '600',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  gap: '6px',
                  cursor: redisLoading ? 'not-allowed' : 'pointer'
                }}
              >
                <Trash2 size={14} color="#64748b" />
                <span>{activeRedisAction === 'user' ? 'Clearing...' : 'Clear User Cache'}</span>
              </button>
            </div>

            {/* Clear Booking Cache */}
            <div style={{ padding: '14px', borderRadius: '10px', border: '1px solid #e2e8f0', backgroundColor: '#f8fafc' }}>
              <div style={{ fontSize: '13px', fontWeight: '700', color: '#1e293b', marginBottom: '4px' }}>
                Booking Cache
              </div>
              <div style={{ fontSize: '11.5px', color: '#64748b', marginBottom: '10px' }}>
                Keys: <code>booking:*</code>, <code>scheduled:*</code>
              </div>
              <button
                onClick={() => handleClearRedis('booking')}
                disabled={redisLoading}
                style={{
                  width: '100%',
                  padding: '7px 12px',
                  borderRadius: '6px',
                  border: '1px solid #cbd5e1',
                  backgroundColor: '#ffffff',
                  color: '#334155',
                  fontSize: '12px',
                  fontWeight: '600',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  gap: '6px',
                  cursor: redisLoading ? 'not-allowed' : 'pointer'
                }}
              >
                <Trash2 size={14} color="#64748b" />
                <span>{activeRedisAction === 'booking' ? 'Clearing...' : 'Clear Booking Cache'}</span>
              </button>
            </div>

            {/* Clear App Version Cache */}
            <div style={{ padding: '14px', borderRadius: '10px', border: '1px solid #e2e8f0', backgroundColor: '#f8fafc' }}>
              <div style={{ fontSize: '13px', fontWeight: '700', color: '#1e293b', marginBottom: '4px' }}>
                App Version Cache
              </div>
              <div style={{ fontSize: '11.5px', color: '#64748b', marginBottom: '10px' }}>
                Keys: <code>app:version:*</code>
              </div>
              <button
                onClick={() => handleClearRedis('version')}
                disabled={redisLoading}
                style={{
                  width: '100%',
                  padding: '7px 12px',
                  borderRadius: '6px',
                  border: '1px solid #cbd5e1',
                  backgroundColor: '#ffffff',
                  color: '#334155',
                  fontSize: '12px',
                  fontWeight: '600',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  gap: '6px',
                  cursor: redisLoading ? 'not-allowed' : 'pointer'
                }}
              >
                <Trash2 size={14} color="#64748b" />
                <span>{activeRedisAction === 'version' ? 'Clearing...' : 'Clear Version Cache'}</span>
              </button>
            </div>

            {/* Clear Categories & Catalog */}
            <div style={{ padding: '14px', borderRadius: '10px', border: '1px solid #e2e8f0', backgroundColor: '#f8fafc' }}>
              <div style={{ fontSize: '13px', fontWeight: '700', color: '#1e293b', marginBottom: '4px' }}>
                Catalog & Services
              </div>
              <div style={{ fontSize: '11.5px', color: '#64748b', marginBottom: '10px' }}>
                Keys: <code>app:categories:*</code>, <code>app:services:*</code>
              </div>
              <button
                onClick={() => handleClearRedis('categories')}
                disabled={redisLoading}
                style={{
                  width: '100%',
                  padding: '7px 12px',
                  borderRadius: '6px',
                  border: '1px solid #cbd5e1',
                  backgroundColor: '#ffffff',
                  color: '#334155',
                  fontSize: '12px',
                  fontWeight: '600',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  gap: '6px',
                  cursor: redisLoading ? 'not-allowed' : 'pointer'
                }}
              >
                <Trash2 size={14} color="#64748b" />
                <span>{activeRedisAction === 'categories' ? 'Clearing...' : 'Clear Catalog Cache'}</span>
              </button>
            </div>
          </div>

          {/* Flush All Danger Button */}
          <div
            style={{
              marginTop: '16px',
              padding: '14px 16px',
              borderRadius: '10px',
              backgroundColor: '#fef2f2',
              border: '1px solid #fee2e2',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'space-between'
            }}
          >
            <div>
              <div style={{ fontSize: '13.5px', fontWeight: '700', color: '#991b1b' }}>
                Full Redis Reset (FLUSH ALL)
              </div>
              <div style={{ fontSize: '12px', color: '#b91c1c' }}>
                Wipes all Redis in-memory cache keys. Next client request will fetch directly from DB and repopulate Redis.
              </div>
            </div>
            <button
              onClick={() => handleClearRedis('all')}
              disabled={redisLoading}
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: '6px',
                padding: '8px 16px',
                backgroundColor: '#dc2626',
                color: '#ffffff',
                border: 'none',
                borderRadius: '8px',
                fontSize: '12.5px',
                fontWeight: '700',
                cursor: redisLoading ? 'not-allowed' : 'pointer'
              }}
            >
              <Zap size={14} />
              <span>{activeRedisAction === 'all' ? 'Flushing...' : 'Flush Entire Redis Cache'}</span>
            </button>
          </div>
        </div>

        {/* SECTION 3: Platform Governance & Dispatch (Existing) */}
        <div style={{ backgroundColor: '#ffffff', padding: '24px', borderRadius: '16px', border: '1px solid var(--border-light)', boxShadow: '0 1px 3px rgba(0,0,0,0.05)' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '14px' }}>
            <Percent size={18} color="var(--primary-brand)" />
            <h3 style={{ fontSize: '15px', fontWeight: '700', color: '#111827' }}>
              Cooperative Welfare Contribution Rate
            </h3>
          </div>
          <p style={{ fontSize: '12.5px', color: '#64748b', marginBottom: '12px' }}>
            Percentage of booking amount automatically allocated to worker health insurance, accident protection, and emergency credit pool.
          </p>
          <div style={{ display: 'flex', alignItems: 'center', gap: '12px', marginBottom: '20px' }}>
            <input
              type="number"
              value={welfarePercent}
              onChange={(e) => setWelfarePercent(e.target.value)}
              style={{
                width: '90px',
                padding: '8px 12px',
                borderRadius: '8px',
                border: '1px solid #cbd5e1',
                fontSize: '14px',
                fontWeight: '700',
              }}
            />
            <span style={{ fontSize: '14px', fontWeight: '600', color: '#111827' }}>%</span>
            <span style={{ fontSize: '12px', color: '#15803d', fontWeight: '600' }}>
              (Remaining {Math.max(0, 100 - (Number(welfarePercent) || 0))}% goes directly to the service worker)
            </span>
          </div>

          <div style={{ borderTop: '1px solid #f1f5f9', paddingTop: '16px', marginBottom: '20px' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '14px' }}>
              <Sliders size={18} color="var(--primary-brand)" />
              <h3 style={{ fontSize: '15px', fontWeight: '700', color: '#111827' }}>
                Automated Fair Dispatch Engine
              </h3>
            </div>
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
              <div>
                <div style={{ fontSize: '13px', fontWeight: '600', color: '#1e293b' }}>
                  Proximity + Fair Rotation Algorithm
                </div>
                <div style={{ fontSize: '12px', color: '#64748b', marginTop: '2px' }}>
                  Prevents gig monopolization by distributing high-value tasks equitably among local workers.
                </div>
              </div>
              <input
                type="checkbox"
                checked={autoDispatch}
                onChange={(e) => setAutoDispatch(e.target.checked)}
                style={{ width: '20px', height: '20px', accentColor: '#1e7e45', cursor: 'pointer' }}
              />
            </div>
          </div>

          <div style={{ borderTop: '1px solid #f1f5f9', paddingTop: '16px', marginBottom: '20px' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '14px' }}>
              <Shield size={18} color="var(--primary-brand)" />
              <h3 style={{ fontSize: '15px', fontWeight: '700', color: '#111827' }}>
                Worker Emergency SOS Line
              </h3>
            </div>
            <input
              type="text"
              value={emergencyHotline}
              onChange={(e) => setEmergencyHotline(e.target.value)}
              style={{
                width: '280px',
                padding: '8px 12px',
                borderRadius: '8px',
                border: '1px solid #cbd5e1',
                fontSize: '14px',
              }}
            />
          </div>

          <div style={{ display: 'flex', justifyContent: 'flex-end', marginTop: '8px' }}>
            <button
              onClick={handleSavePlatform}
              disabled={isSavingPlatform}
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: '6px',
                padding: '10px 22px',
                backgroundColor: 'var(--primary-brand)',
                color: '#ffffff',
                border: 'none',
                borderRadius: '8px',
                fontSize: '13.5px',
                fontWeight: '600',
                boxShadow: 'var(--shadow-pill)',
                cursor: isSavingPlatform ? 'not-allowed' : 'pointer'
              }}
            >
              <Save size={15} />
              <span>{isSavingPlatform ? 'Saving...' : 'Save Platform Preferences'}</span>
            </button>
          </div>
        </div>

      </div>
    </div>
  );
}
