import React, { useState } from 'react';
import {
  Settings,
  Shield,
  Bell,
  Sliders,
  Save,
  Globe,
  Lock,
  Percent
} from 'lucide-react';

export default function SettingsView() {
  const [welfarePercent, setWelfarePercent] = useState('5');
  const [emergencyHotline, setEmergencyHotline] = useState('1800-456-GIGS');
  const [autoDispatch, setAutoDispatch] = useState(true);

  return (
    <div style={{ padding: '0 32px 32px 32px', animation: 'fadeIn 0.2s ease', maxWidth: '850px' }}>
      <div style={{ marginBottom: '20px' }}>
        <h2 style={{ fontSize: '20px', fontWeight: '700', color: '#111827' }}>
          Platform Settings & Governance
        </h2>
        <p style={{ fontSize: '13px', color: '#64748b' }}>
          Cooperative bylaws, split algorithms, security, and alert integrations
        </p>
      </div>

      <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
        {/* Cooperative Fee & Welfare pool config */}
        <div style={{ backgroundColor: '#ffffff', padding: '22px', borderRadius: '16px', border: '1px solid var(--border-light)' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '14px' }}>
            <Percent size={18} color="var(--primary-brand)" />
            <h3 style={{ fontSize: '15px', fontWeight: '700', color: '#111827' }}>
              Cooperative Welfare Contribution Rate
            </h3>
          </div>
          <p style={{ fontSize: '12.5px', color: '#64748b', marginBottom: '12px' }}>
            Percentage of booking amount automatically allocated to worker health insurance, accident protection, and emergency credit pool.
          </p>
          <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
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
              (Remaining 95% goes directly to the service worker)
            </span>
          </div>
        </div>

        {/* Dispatch Settings */}
        <div style={{ backgroundColor: '#ffffff', padding: '22px', borderRadius: '16px', border: '1px solid var(--border-light)' }}>
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

        {/* Emergency SOS Hotline */}
        <div style={{ backgroundColor: '#ffffff', padding: '22px', borderRadius: '16px', border: '1px solid var(--border-light)' }}>
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
            onClick={() => alert('Settings saved successfully!')}
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '6px',
              padding: '10px 22px',
              backgroundColor: 'var(--primary-brand)',
              color: '#ffffff',
              borderRadius: '8px',
              fontSize: '13.5px',
              fontWeight: '600',
              boxShadow: 'var(--shadow-pill)',
            }}
          >
            <Save size={15} />
            <span>Save Platform Preferences</span>
          </button>
        </div>
      </div>
    </div>
  );
}
