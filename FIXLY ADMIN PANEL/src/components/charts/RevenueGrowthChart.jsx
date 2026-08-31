import React, { useState } from 'react';
import {
  ResponsiveContainer,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  Tooltip,
  CartesianGrid,
} from 'recharts';
import { analyticsData } from '../../data/analytics';

export default function RevenueGrowthChart() {
  const [metric, setMetric] = useState('revenue');

  const data = [
    { period: 'Jan', revenue: 7800000, payout: 7410000, welfare: 390000 },
    { period: 'Feb', revenue: 9200000, payout: 8740000, welfare: 460000 },
    { period: 'Mar', revenue: 11400000, payout: 10830000, welfare: 570000 },
    { period: 'Apr', revenue: 13300000, payout: 12635000, welfare: 665000 },
    { period: 'May', revenue: 16800000, payout: 15960000, welfare: 840000 },
  ];

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
          <BarChart data={data} margin={{ top: 10, right: 10, left: 10, bottom: 0 }}>
            <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#f1f5f3" />
            <XAxis dataKey="period" tick={{ fontSize: 11, fill: '#8c9e94' }} axisLine={{ stroke: '#e2ece5' }} />
            <YAxis
              tick={{ fontSize: 11, fill: '#8c9e94' }}
              axisLine={false}
              tickFormatter={(val) => `₹${val / 100000}L`}
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
