import React from 'react';
import {
  ResponsiveContainer,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  Tooltip,
  CartesianGrid,
} from 'recharts';
import { useApp } from '../../context/AppContext';

export default function RevenueGrowthChart({ customData }) {
  const { dashboardStats } = useApp();

  const totalRev = dashboardStats?.totalRevenue || 10598;

  const defaultData = [
    { period: 'Jan', revenue: Math.round(totalRev * 0.2), payout: Math.round(totalRev * 0.19), welfare: Math.round(totalRev * 0.01) },
    { period: 'Feb', revenue: Math.round(totalRev * 0.4), payout: Math.round(totalRev * 0.38), welfare: Math.round(totalRev * 0.02) },
    { period: 'Mar', revenue: Math.round(totalRev * 0.6), payout: Math.round(totalRev * 0.57), welfare: Math.round(totalRev * 0.03) },
    { period: 'Apr', revenue: Math.round(totalRev * 0.8), payout: Math.round(totalRev * 0.76), welfare: Math.round(totalRev * 0.04) },
    { period: 'May', revenue: totalRev, payout: Math.round(totalRev * 0.95), welfare: Math.round(totalRev * 0.05) },
  ];

  const chartData = customData && customData.length > 0 ? customData : defaultData;

  return (
    <div
      style={{
        backgroundColor: 'var(--bg-card)',
        borderRadius: 'var(--radius-lg)',
        border: '1px solid var(--border-light)',
        padding: '22px 24px',
        boxShadow: 'var(--shadow-card)',
      }}
    >
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px' }}>
        <div>
          <h3 style={{ fontSize: '16px', fontWeight: '700', color: '#111827' }}>
            Revenue & Worker Payout Trajectory
          </h3>
          <p style={{ fontSize: '12px', color: '#64748b' }}>
            Gross transaction value vs direct member payout
          </p>
        </div>
      </div>

      <div style={{ width: '100%', height: '240px' }}>
        <ResponsiveContainer width="100%" height="100%">
          <BarChart data={chartData} margin={{ top: 10, right: 10, left: 10, bottom: 0 }}>
            <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#f1f5f3" />
            <XAxis dataKey="period" tick={{ fontSize: 11, fill: '#8c9e94' }} axisLine={{ stroke: '#e2ece5' }} />
            <YAxis
              tick={{ fontSize: 11, fill: '#8c9e94' }}
              axisLine={false}
              tickFormatter={(val) => `₹${val >= 1000 ? `${(val / 1000).toFixed(0)}k` : val}`}
            />
            <Tooltip
              formatter={(val) => [`₹${val.toLocaleString()}`, 'Amount']}
              contentStyle={{ backgroundColor: '#122319', borderRadius: '8px', border: 'none', color: '#fff' }}
            />
            <Bar dataKey="revenue" fill="#1e7e45" name="Gross Platform Revenue" radius={[4, 4, 0, 0]} />
            <Bar dataKey="payout" fill="#86efac" name="Worker Net Payout (95%)" radius={[4, 4, 0, 0]} />
          </BarChart>
        </ResponsiveContainer>
      </div>
    </div>
  );
}
