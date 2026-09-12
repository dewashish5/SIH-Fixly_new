import React from 'react';
import {
  TrendingUp,
  Clock,
  Users,
  Award,
  Zap,
  Target,
  ArrowUpRight,
  ShieldCheck,
  RotateCcw,
  CheckCircle2,
  AlertCircle
} from 'lucide-react';
import BookingsOverviewChart from '../../components/charts/BookingsOverviewChart';
import RevenueGrowthChart from '../../components/charts/RevenueGrowthChart';
import TopServicesCard from '../../components/TopServicesCard';
import { useApp } from '../../context/AppContext';

export default function AnalyticsPage() {
  const { workers = [], bookings = [], customers = [], dashboardStats, reviews = [] } = useApp();

  // Compute live analytics from real DB data
  const totalWorkers = workers.length;
  const verifiedWorkers = workers.filter((w) => w.isVerified || w.verification === 'Verified').length;
  const workerVerificationRate = totalWorkers > 0 ? `${Math.round((verifiedWorkers / totalWorkers) * 100)}%` : '100%';

  const totalBookings = bookings.length;
  const completedBookings = bookings.filter((b) => (b.status || '').toUpperCase() === 'COMPLETED').length;
  const cancelledBookings = bookings.filter((b) => (b.status || '').toUpperCase() === 'CANCELLED').length;
  
  const completionRate = totalBookings > 0 ? `${Math.round((completedBookings / totalBookings) * 100)}%` : '0%';
  const cancellationRate = totalBookings > 0 ? `${((cancelledBookings / totalBookings) * 100).toFixed(1)}%` : '0.0%';

  const avgRating = reviews.length > 0
    ? (reviews.reduce((acc, r) => acc + (r.rating || 5), 0) / reviews.length).toFixed(1)
    : '5.0';

  // Group workers by actual city
  const cityClusterMap = {};
  workers.forEach((w) => {
    const city = w.city || 'Delhi NCR';
    if (!cityClusterMap[city]) {
      cityClusterMap[city] = { city, workers: 0, bookings: 0 };
    }
    cityClusterMap[city].workers += 1;
  });

  // Assign bookings to cities if present
  bookings.forEach((b) => {
    const city = b.city || 'Delhi NCR';
    if (cityClusterMap[city]) {
      cityClusterMap[city].bookings += 1;
    }
  });

  const cityList = Object.values(cityClusterMap);

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
            Live Platform Analytics & KPIs
          </h2>
          <p style={{ fontSize: '13px', color: '#64748b' }}>
            Real-time fulfillment metrics, worker verification, task completion, and regional distribution
          </p>
        </div>
      </div>

      {/* 4 Performance Metric Cards */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '16px' }}>
        <div style={{ backgroundColor: '#ffffff', padding: '18px 20px', borderRadius: '16px', border: '1px solid var(--border-light)' }}>
          <div style={{ fontSize: '12px', color: '#64748b' }}>Fulfillment Completion Rate</div>
          <div style={{ fontSize: '22px', fontWeight: '800', color: '#111827', marginTop: '3px' }}>
            {completionRate}
          </div>
          <div style={{ fontSize: '12px', color: '#15803d', fontWeight: '600', marginTop: '2px' }}>
            {completedBookings} of {totalBookings} tasks done
          </div>
        </div>

        <div style={{ backgroundColor: '#ffffff', padding: '18px 20px', borderRadius: '16px', border: '1px solid var(--border-light)' }}>
          <div style={{ fontSize: '12px', color: '#64748b' }}>Worker Verification Ratio</div>
          <div style={{ fontSize: '22px', fontWeight: '800', color: '#15803d', marginTop: '3px' }}>
            {workerVerificationRate}
          </div>
          <div style={{ fontSize: '12px', color: '#64748b', marginTop: '2px' }}>
            {verifiedWorkers} active verified members
          </div>
        </div>

        <div style={{ backgroundColor: '#ffffff', padding: '18px 20px', borderRadius: '16px', border: '1px solid var(--border-light)' }}>
          <div style={{ fontSize: '12px', color: '#64748b' }}>Order Cancellation Rate</div>
          <div style={{ fontSize: '22px', fontWeight: '800', color: '#0f172a', marginTop: '3px' }}>
            {cancellationRate}
          </div>
          <div style={{ fontSize: '12px', color: '#15803d', fontWeight: '600', marginTop: '2px' }}>
            {cancelledBookings} cancelled orders
          </div>
        </div>

        <div style={{ backgroundColor: '#ffffff', padding: '18px 20px', borderRadius: '16px', border: '1px solid var(--border-light)' }}>
          <div style={{ fontSize: '12px', color: '#64748b' }}>Customer Satisfaction Score</div>
          <div style={{ fontSize: '22px', fontWeight: '800', color: '#15803d', marginTop: '3px' }}>
            ★ {avgRating} / 5
          </div>
          <div style={{ fontSize: '12px', color: '#ca8a04', fontWeight: '600', marginTop: '2px' }}>
            Based on {reviews.length} customer reviews
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
            {cityList.length === 0 ? (
              <div style={{ padding: '24px 0', textAlign: 'center', color: '#94a3b8', fontSize: '13px' }}>
                No regional worker data available yet.
              </div>
            ) : (
              cityList.map((city) => (
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
                    Active
                  </span>
                </div>
              ))
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
