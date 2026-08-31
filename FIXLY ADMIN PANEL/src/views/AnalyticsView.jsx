import React from 'react';
import {
  TrendingUp,
  MapPin,
  Clock,
  Users,
  Target,
  ArrowUpRight
} from 'lucide-react';
import BookingsChart from '../components/BookingsChart';
import TopServicesCard from '../components/TopServicesCard';

export default function AnalyticsView() {
  return (
    <div style={{ padding: '0 32px 32px 32px', animation: 'fadeIn 0.2s ease', display: 'flex', flexDirection: 'column', gap: '20px' }}>
      <div>
        <h2 style={{ fontSize: '20px', fontWeight: '700', color: '#111827' }}>
          Deep Platform Analytics & Forecasts
        </h2>
        <p style={{ fontSize: '13px', color: '#64748b' }}>
          Real-time service demand metrics, cluster heatmaps, and retention analysis
        </p>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: '18px' }}>
        <div style={{ backgroundColor: '#ffffff', padding: '20px', borderRadius: '16px', border: '1px solid var(--border-light)' }}>
          <div style={{ fontSize: '12.5px', color: '#64748b' }}>Average Order Fulfillment Time</div>
          <div style={{ fontSize: '24px', fontWeight: '800', color: '#111827', marginTop: '4px' }}>
            24 mins
          </div>
          <div style={{ fontSize: '12px', color: '#15803d', fontWeight: '600', marginTop: '4px' }}>
            ⚡ 18% faster than conventional aggregators
          </div>
        </div>

        <div style={{ backgroundColor: '#ffffff', padding: '20px', borderRadius: '16px', border: '1px solid var(--border-light)' }}>
          <div style={{ fontSize: '12.5px', color: '#64748b' }}>Worker 30-Day Retention Rate</div>
          <div style={{ fontSize: '24px', fontWeight: '800', color: '#15803d', marginTop: '4px' }}>
            94.2%
          </div>
          <div style={{ fontSize: '12px', color: '#64748b', marginTop: '4px' }}>
            Highest in gig cooperative industry
          </div>
        </div>

        <div style={{ backgroundColor: '#ffffff', padding: '20px', borderRadius: '16px', border: '1px solid var(--border-light)' }}>
          <div style={{ fontSize: '12.5px', color: '#64748b' }}>Customer NPS Satisfaction Score</div>
          <div style={{ fontSize: '24px', fontWeight: '800', color: '#0f172a', marginTop: '4px' }}>
            78 / 100
          </div>
          <div style={{ fontSize: '12px', color: '#15803d', fontWeight: '600', marginTop: '4px' }}>
            ★ 4.88 average verified rating
          </div>
        </div>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: '1.65fr 1fr', gap: '20px' }}>
        <div style={{ minHeight: '320px' }}>
          <BookingsChart />
        </div>
        <div style={{ minHeight: '320px' }}>
          <TopServicesCard />
        </div>
      </div>
    </div>
  );
}
