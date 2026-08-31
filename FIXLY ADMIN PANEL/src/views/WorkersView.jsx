import React, { useState } from 'react';
import { liveWorkers } from '../data/mockData';
import {
  Users,
  Search,
  Plus,
  ShieldCheck,
  Star,
  Phone,
  Battery,
  MapPin,
  Award
} from 'lucide-react';

export default function WorkersView({ onOpenMapModal }) {
  const [filter, setFilter] = useState('All');
  const [search, setSearch] = useState('');

  const filtered = liveWorkers.filter((w) => {
    const matchFilter = filter === 'All' || w.service === filter;
    const matchSearch =
      w.name.toLowerCase().includes(search.toLowerCase()) ||
      w.service.toLowerCase().includes(search.toLowerCase());
    return matchFilter && matchSearch;
  });

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
            Gig Workers & Cooperative Members (12,458)
          </h2>
          <p style={{ fontSize: '13px', color: '#64748b' }}>
            Member verification, daily earnings, performance ratings, and telemetry
          </p>
        </div>

        <div style={{ display: 'flex', gap: '10px' }}>
          <button
            onClick={onOpenMapModal}
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '6px',
              padding: '9px 14px',
              backgroundColor: '#eaf7ee',
              color: '#15803d',
              border: '1px solid #bbf7d0',
              borderRadius: '8px',
              fontSize: '13px',
              fontWeight: '600',
            }}
          >
            <MapPin size={15} />
            <span>Open Live GPS Radar</span>
          </button>

          <button
            onClick={() => alert('Opening Worker Onboarding Form')}
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
            <span>Onboard Member</span>
          </button>
        </div>
      </div>

      {/* Workers Grid Cards */}
      <div
        style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fill, minmax(310px, 1fr))',
          gap: '18px',
        }}
      >
        {filtered.map((w) => (
          <div
            key={w.id}
            style={{
              backgroundColor: '#ffffff',
              borderRadius: '16px',
              border: '1px solid var(--border-light)',
              padding: '20px',
              boxShadow: 'var(--shadow-card)',
              display: 'flex',
              flexDirection: 'column',
              justifyContent: 'space-between',
            }}
          >
            <div>
              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                  <img
                    src={w.avatar}
                    alt={w.name}
                    style={{
                      width: '48px',
                      height: '48px',
                      borderRadius: '50%',
                      objectFit: 'cover',
                      border: '2px solid #22c55e',
                    }}
                  />
                  <div>
                    <div style={{ fontSize: '15px', fontWeight: '700', color: '#111827' }}>
                      {w.name}
                    </div>
                    <div style={{ fontSize: '12.5px', color: '#64748b' }}>
                      {w.service}
                    </div>
                  </div>
                </div>

                <span
                  style={{
                    fontSize: '11px',
                    fontWeight: '600',
                    padding: '3px 8px',
                    borderRadius: '999px',
                    backgroundColor: w.status === 'Available' ? '#eaf8ef' : '#fef8e7',
                    color: w.status === 'Available' ? '#15803d' : '#d97706',
                  }}
                >
                  {w.status}
                </span>
              </div>

              {/* Badges / Metrics */}
              <div
                style={{
                  display: 'grid',
                  gridTemplateColumns: '1fr 1fr 1fr',
                  gap: '8px',
                  backgroundColor: '#f8faf9',
                  borderRadius: '10px',
                  padding: '10px',
                  marginTop: '16px',
                  textAlign: 'center',
                }}
              >
                <div>
                  <div style={{ fontSize: '11px', color: '#64748b' }}>Rating</div>
                  <div style={{ fontSize: '13px', fontWeight: '700', color: '#15803d' }}>
                    ★ {w.rating}
                  </div>
                </div>
                <div>
                  <div style={{ fontSize: '11px', color: '#64748b' }}>Today Jobs</div>
                  <div style={{ fontSize: '13px', fontWeight: '700', color: '#111827' }}>
                    {w.completedToday}
                  </div>
                </div>
                <div>
                  <div style={{ fontSize: '11px', color: '#64748b' }}>Battery</div>
                  <div style={{ fontSize: '13px', fontWeight: '700', color: '#0284c7' }}>
                    {w.battery}
                  </div>
                </div>
              </div>

              <div
                style={{
                  marginTop: '12px',
                  display: 'flex',
                  alignItems: 'center',
                  gap: '6px',
                  fontSize: '12px',
                  color: '#15803d',
                  fontWeight: '600',
                }}
              >
                <ShieldCheck size={14} />
                <span>KYC Verified • Cooperative Health Insured</span>
              </div>
            </div>

            <div style={{ display: 'flex', gap: '8px', marginTop: '16px' }}>
              <button
                style={{
                  flex: 1,
                  padding: '8px',
                  borderRadius: '8px',
                  backgroundColor: '#f1f5f9',
                  color: '#334155',
                  fontSize: '12px',
                  fontWeight: '600',
                }}
              >
                View Profile
              </button>
              <button
                style={{
                  flex: 1,
                  padding: '8px',
                  borderRadius: '8px',
                  backgroundColor: 'var(--primary-brand)',
                  color: '#ffffff',
                  fontSize: '12px',
                  fontWeight: '600',
                }}
              >
                Direct Dispatch
              </button>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
