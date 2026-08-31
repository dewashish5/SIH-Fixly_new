import React from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useApp } from '../../context/AppContext';
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
  Battery,
  Clock,
  Download,
  FileCheck
} from 'lucide-react';
import Badge from '../../components/common/Badge';

export default function WorkerDetailPage() {
  const { id } = useParams();
  const navigate = useNavigate();
  const { workers, bookings, verifyWorker, suspendWorker } = useApp();

  const worker = workers.find((w) => w.id === id) || workers[0];
  const workerBookings = bookings.filter((b) => b.workerId === worker.id || b.worker === worker.name);

  return (
    <div style={{ padding: '0 32px 32px 32px', animation: 'fadeIn 0.2s ease', maxWidth: '1100px' }}>
      {/* Back button */}
      <button
        onClick={() => navigate('/workers')}
        style={{
          display: 'flex',
          alignItems: 'center',
          gap: '6px',
          padding: '6px 12px',
          borderRadius: '8px',
          backgroundColor: '#ffffff',
          border: '1px solid var(--border-light)',
          color: '#475569',
          fontSize: '13px',
          fontWeight: '600',
          marginBottom: '18px',
        }}
      >
        <ArrowLeft size={15} />
        <span>Back to Workers Directory</span>
      </button>

      {/* Main Profile Header Card */}
      <div
        style={{
          backgroundColor: '#ffffff',
          borderRadius: '16px',
          border: '1px solid var(--border-light)',
          padding: '24px 28px',
          boxShadow: 'var(--shadow-card)',
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'flex-start',
          flexWrap: 'wrap',
          gap: '20px',
          marginBottom: '20px',
        }}
      >
        <div style={{ display: 'flex', gap: '20px' }}>
          <img
            src={worker.avatar}
            alt={worker.name}
            style={{
              width: '84px',
              height: '84px',
              borderRadius: '50%',
              objectFit: 'cover',
              border: '3px solid #22c55e',
              boxShadow: '0 4px 12px rgba(34, 197, 94, 0.25)',
            }}
          />

          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
              <h2 style={{ fontSize: '22px', fontWeight: '800', color: '#111827' }}>
                {worker.name}
              </h2>
              <Badge status={worker.verification} />
              <Badge status={worker.availability} />
            </div>

            <div style={{ fontSize: '14px', fontWeight: '600', color: '#15803d', marginTop: '2px' }}>
              {worker.service} Professional • Member #{worker.id}
            </div>

            <div style={{ display: 'flex', gap: '16px', marginTop: '8px', fontSize: '12.5px', color: '#64748b', flexWrap: 'wrap' }}>
              <span style={{ display: 'flex', alignItems: 'center', gap: '4px' }}>
                <Phone size={13} /> {worker.phone}
              </span>
              <span style={{ display: 'flex', alignItems: 'center', gap: '4px' }}>
                <Mail size={13} /> {worker.email || `${worker.name.toLowerCase().replace(' ', '.')}@gigcoop.in`}
              </span>
              <span style={{ display: 'flex', alignItems: 'center', gap: '4px' }}>
                <MapPin size={13} /> {worker.location}, {worker.city}
              </span>
            </div>
          </div>
        </div>

        {/* Action Controls */}
        <div style={{ display: 'flex', gap: '8px' }}>
          {worker.verification !== 'Verified' ? (
            <button
              onClick={() => verifyWorker(worker.id)}
              style={{
                padding: '8px 16px',
                borderRadius: '8px',
                backgroundColor: 'var(--primary-brand)',
                color: '#ffffff',
                fontSize: '13px',
                fontWeight: '600',
              }}
            >
              Approve Verification
            </button>
          ) : (
            <button
              onClick={() => suspendWorker(worker.id)}
              style={{
                padding: '8px 16px',
                borderRadius: '8px',
                backgroundColor: '#fef2f2',
                color: '#dc2626',
                border: '1px solid #fecaca',
                fontSize: '13px',
                fontWeight: '600',
              }}
            >
              Suspend Member
            </button>
          )}

          <button
            onClick={() => alert(`ID Badge downloaded for ${worker.name}`)}
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '6px',
              padding: '8px 14px',
              borderRadius: '8px',
              border: '1px solid #cbd5e1',
              backgroundColor: '#ffffff',
              fontSize: '13px',
              fontWeight: '600',
              color: '#334155',
            }}
          >
            <Download size={14} />
            <span>Digital ID Badge</span>
          </button>
        </div>
      </div>

      {/* 4 Stats Cards */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '16px', marginBottom: '20px' }}>
        <div style={{ backgroundColor: '#ffffff', padding: '16px', borderRadius: '12px', border: '1px solid var(--border-light)' }}>
          <div style={{ fontSize: '12px', color: '#64748b' }}>Satisfaction Rating</div>
          <div style={{ fontSize: '20px', fontWeight: '800', color: '#15803d', marginTop: '2px' }}>
            ★ {worker.rating} / 5.0
          </div>
          <div style={{ fontSize: '11px', color: '#64748b' }}>{worker.totalReviews} verified reviews</div>
        </div>

        <div style={{ backgroundColor: '#ffffff', padding: '16px', borderRadius: '12px', border: '1px solid var(--border-light)' }}>
          <div style={{ fontSize: '12px', color: '#64748b' }}>Completed Jobs</div>
          <div style={{ fontSize: '20px', fontWeight: '800', color: '#111827', marginTop: '2px' }}>
            {worker.completedJobs} tasks
          </div>
          <div style={{ fontSize: '11px', color: '#15803d' }}>100% Completion SLA</div>
        </div>

        <div style={{ backgroundColor: '#ffffff', padding: '16px', borderRadius: '12px', border: '1px solid var(--border-light)' }}>
          <div style={{ fontSize: '12px', color: '#64748b' }}>Today's Earnings</div>
          <div style={{ fontSize: '20px', fontWeight: '800', color: '#111827', marginTop: '2px' }}>
            {worker.todayEarnings}
          </div>
          <div style={{ fontSize: '11px', color: '#15803d' }}>Instant UPI Settlement</div>
        </div>

        <div style={{ backgroundColor: '#ffffff', padding: '16px', borderRadius: '12px', border: '1px solid var(--border-light)' }}>
          <div style={{ fontSize: '12px', color: '#64748b' }}>Lifetime Earnings</div>
          <div style={{ fontSize: '20px', fontWeight: '800', color: '#0f172a', marginTop: '2px' }}>
            {worker.lifetimeEarnings}
          </div>
          <div style={{ fontSize: '11px', color: '#64748b' }}>Cooperative member since {worker.joinedDate}</div>
        </div>
      </div>

      {/* Skills, Certifications, Insurance & Documents Grid */}
      <div style={{ display: 'grid', gridTemplateColumns: '1.2fr 1fr', gap: '20px', marginBottom: '20px' }}>
        {/* Left: Skills & Certifications */}
        <div style={{ backgroundColor: '#ffffff', padding: '20px 24px', borderRadius: '16px', border: '1px solid var(--border-light)' }}>
          <h3 style={{ fontSize: '15px', fontWeight: '700', color: '#111827', marginBottom: '12px' }}>
            Verified Skill Profile & Guild Badges
          </h3>

          <div style={{ display: 'flex', gap: '8px', flexWrap: 'wrap', marginBottom: '16px' }}>
            {worker.skills.map((skill, idx) => (
              <span
                key={idx}
                style={{
                  padding: '6px 12px',
                  borderRadius: '8px',
                  backgroundColor: '#f1f8f3',
                  color: '#15803d',
                  fontSize: '12.5px',
                  fontWeight: '600',
                  border: '1px solid #bbf7d0',
                }}
              >
                ✓ {skill}
              </span>
            ))}
          </div>

          <h4 style={{ fontSize: '13px', fontWeight: '700', color: '#475569', marginBottom: '8px' }}>
            Certifications & Accreditation
          </h4>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '6px' }}>
            {worker.certifications.map((cert, idx) => (
              <div
                key={idx}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: '8px',
                  fontSize: '12.5px',
                  color: '#1e293b',
                  backgroundColor: '#f8fafc',
                  padding: '8px 12px',
                  borderRadius: '8px',
                }}
              >
                <Award size={16} color="#ca8a04" />
                <span>{cert}</span>
              </div>
            ))}
          </div>
        </div>

        {/* Right: Insurance & Social Security */}
        <div style={{ backgroundColor: '#ffffff', padding: '20px 24px', borderRadius: '16px', border: '1px solid var(--border-light)' }}>
          <h3 style={{ fontSize: '15px', fontWeight: '700', color: '#111827', marginBottom: '12px' }}>
            Social Security & Insurance
          </h3>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '10px', fontSize: '13px' }}>
            <div style={{ backgroundColor: '#f0fdf4', padding: '12px', borderRadius: '10px', border: '1px solid #bbf7d0' }}>
              <div style={{ fontWeight: '700', color: '#15803d' }}>
                🛡️ Group Accidental & Health Policy
              </div>
              <div style={{ color: '#166534', fontSize: '12px', marginTop: '2px' }}>
                Coverage: ₹5,00,000 • Fully sponsored via 5% Welfare Fund
              </div>
            </div>

            <div style={{ display: 'flex', justifyContent: 'space-between', padding: '6px 0', borderBottom: '1px solid #f1f5f9' }}>
              <span style={{ color: '#64748b' }}>ID Proof Verification:</span>
              <strong style={{ color: '#15803d' }}>{worker.idProof}</strong>
            </div>

            <div style={{ display: 'flex', justifyContent: 'space-between', padding: '6px 0', borderBottom: '1px solid #f1f5f9' }}>
              <span style={{ color: '#64748b' }}>Battery Telemetry:</span>
              <strong style={{ color: '#0284c7' }}>{worker.battery} (Live)</strong>
            </div>

            <div style={{ display: 'flex', justifyContent: 'space-between', padding: '6px 0' }}>
              <span style={{ color: '#64748b' }}>Hourly Benchmark Rate:</span>
              <strong>{worker.hourlyRate}</strong>
            </div>
          </div>
        </div>
      </div>

      {/* Worker's Assigned Bookings History */}
      <div style={{ backgroundColor: '#ffffff', borderRadius: '16px', border: '1px solid var(--border-light)', overflow: 'hidden' }}>
        <div style={{ padding: '16px 20px', borderBottom: '1px solid #f1f5f3', fontWeight: '700', fontSize: '15px' }}>
          Recent Job Assignments for {worker.name} ({workerBookings.length})
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
            {workerBookings.map((b) => (
              <tr key={b.id} style={{ borderBottom: '1px solid #f1f5f3', fontSize: '13px' }}>
                <td style={{ padding: '12px 18px', color: 'var(--text-link)', fontWeight: '700' }}>{b.id}</td>
                <td style={{ padding: '12px 18px' }}>{b.customer}</td>
                <td style={{ padding: '12px 18px' }}>{b.service}</td>
                <td style={{ padding: '12px 18px', fontWeight: '700' }}>{b.amount}</td>
                <td style={{ padding: '12px 18px' }}><Badge status={b.status} /></td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
