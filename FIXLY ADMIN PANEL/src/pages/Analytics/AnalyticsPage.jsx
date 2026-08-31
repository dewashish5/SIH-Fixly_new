import React, { useState } from 'react';
import {
  TrendingUp,
  Clock,
  Users,
  Award,
  Zap,
  Target,
  ArrowUpRight,
  ShieldCheck,
  RotateCcw
} from 'lucide-react';
import BookingsOverviewChart from '../../components/charts/BookingsOverviewChart';
import RevenueGrowthChart from '../../components/charts/RevenueGrowthChart';
import TopServicesCard from '../../components/TopServicesCard';
import { analyticsData } from '../../data/analytics';

export default function AnalyticsPage() {
  const [selectedRange, setSelectedRange] = useState('This Week');

  return (
    <div style={{ padding: '0 32px 32px 32px', animation: 'fadeIn 0.2s ease', display: 'flex', flexDirection: 'column', gap: '22px' }}>
      {/* Header */}
      <div
        style={{
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          flexWrap: 'wrap',
          gap: '12px',
        }}
      >
        <div>
          <h2 style={{ fontSize: '20px', fontWeight: '700', color: '#111827' }}>
            Advanced Platform Analytics & KPIs
          </h2>
          <p style={{ fontSize: '13px', color: '#64748b' }}>
            Real-time fulfillment metrics, worker retention, customer NPS satisfaction, and geographic demand
          </p>
        </div>
      </div>

      {/* 4 Performance Metric Cards */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '16px' }}>
        <div style={{ backgroundColor: '#ffffff', padding: '18px 20px', borderRadius: '16px', border: '1px solid var(--border-light)' }}>
          <div style={{ fontSize: '12px', color: '#64748b' }}>Avg. Response & Arrival Time</div>
          <div style={{ fontSize: '22px', fontWeight: '800', color: '#111827', marginTop: '3px' }}>
            {analyticsData.kpis.avgResponseTime}
          </div>
          <div style={{ fontSize: '12px', color: '#15803d', fontWeight: '600', marginTop: '2px' }}>
            ⚡ {analyticsData.kpis.responseTimeTrend}
          </div>
        </div>

        <div style={{ backgroundColor: '#ffffff', padding: '18px 20px', borderRadius: '16px', border: '1px solid var(--border-light)' }}>
          <div style={{ fontSize: '12px', color: '#64748b' }}>Worker 30-Day Retention</div>
          <div style={{ fontSize: '22px', fontWeight: '800', color: '#15803d', marginTop: '3px' }}>
            {analyticsData.kpis.workerRetention}
          </div>
          <div style={{ fontSize: '12px', color: '#64748b', marginTop: '2px' }}>
            Fair revenue share guarantee
          </div>
        </div>

        <div style={{ backgroundColor: '#ffffff', padding: '18px 20px', borderRadius: '16px', border: '1px solid var(--border-light)' }}>
          <div style={{ fontSize: '12px', color: '#64748b' }}>Order Cancellation Rate</div>
          <div style={{ fontSize: '22px', fontWeight: '800', color: '#0f172a', marginTop: '3px' }}>
            {analyticsData.kpis.cancellationRate}
          </div>
          <div style={{ fontSize: '12px', color: '#15803d', fontWeight: '600', marginTop: '2px' }}>
            Industry lowest (~7% benchmark)
          </div>
        </div>

        <div style={{ backgroundColor: '#ffffff', padding: '18px 20px', borderRadius: '16px', border: '1px solid var(--border-light)' }}>
          <div style={{ fontSize: '12px', color: '#64748b' }}>Customer NPS Score</div>
          <div style={{ fontSize: '22px', fontWeight: '800', color: '#15803d', marginTop: '3px' }}>
            {analyticsData.kpis.npsScore}
          </div>
          <div style={{ fontSize: '12px', color: '#ca8a04', fontWeight: '600', marginTop: '2px' }}>
            ★ 4.6/5 average rating
          </div>
        </div>
      </div>

      {/* Row 1: Bookings Spline + Top Services */}
      <div style={{ display: 'grid', gridTemplateColumns: '1.65fr 1fr', gap: '20px' }}>
        <div style={{ minHeight: '320px' }}>
          <BookingsOverviewChart />
        </div>
        <div style={{ minHeight: '320px' }}>
          <TopServicesCard />
        </div>
      </div>

      {/* Row 2: Revenue vs Payouts Bar Chart + Geographic City Breakdown */}
      <div style={{ display: 'grid', gridTemplateColumns: '1.65fr 1fr', gap: '20px' }}>
        <div>
          <RevenueGrowthChart />
        </div>

        {/* City Demand Breakdown */}
        <div style={{ backgroundColor: '#ffffff', borderRadius: '16px', border: '1px solid var(--border-light)', padding: '22px 24px', boxShadow: 'var(--shadow-card)' }}>
          <h3 style={{ fontSize: '16px', fontWeight: '700', color: '#111827', marginBottom: '14px' }}>
            City Cluster Distribution
          </h3>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
            {analyticsData.cityDemand.map((city) => (
              <div
                key={city.city}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'space-between',
                  padding: '10px 14px',
                  backgroundColor: '#f8faf9',
                  borderRadius: '10px',
                }}
              >
                <div>
                  <div style={{ fontWeight: '700', fontSize: '13.5px', color: '#1e293b' }}>
                    {city.city}
                  </div>
                  <div style={{ fontSize: '11.5px', color: '#64748b' }}>
                    {city.workers.toLocaleString()} Field Workers • {city.bookings.toLocaleString()} Bookings
                  </div>
                </div>

                <span style={{ fontSize: '12px', fontWeight: '700', color: '#15803d', backgroundColor: '#eaf8ef', padding: '3px 8px', borderRadius: '6px' }}>
                  {city.growth}
                </span>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
