import React, { useState } from 'react';
import { chartData } from '../data/mockData';
import { ArrowUpRight, Filter, Download } from 'lucide-react';

export default function BookingsChart() {
  const [activePoint, setActivePoint] = useState(null);
  const [selectedRange, setSelectedRange] = useState('7d');

  // Chart Dimensions
  const width = 620;
  const height = 230;
  const padding = { top: 25, right: 30, bottom: 35, left: 45 };

  const graphWidth = width - padding.left - padding.right;
  const graphHeight = height - padding.top - padding.bottom;

  const maxVal = 2000;
  const minVal = 0;

  // Calculate coordinates for points
  const points = chartData.map((d, index) => {
    const x = padding.left + (index / (chartData.length - 1)) * graphWidth;
    const y = padding.top + graphHeight - ((d.bookings - minVal) / (maxVal - minVal)) * graphHeight;
    return { ...d, x, y };
  });

  // Generate smooth cubic bezier SVG path
  const getSmoothPath = (pts) => {
    if (pts.length === 0) return '';
    let path = `M ${pts[0].x} ${pts[0].y}`;
    for (let i = 0; i < pts.length - 1; i++) {
      const curr = pts[i];
      const next = pts[i + 1];
      const cp1x = curr.x + (next.x - curr.x) / 2;
      const cp1y = curr.y;
      const cp2x = curr.x + (next.x - curr.x) / 2;
      const cp2y = next.y;
      path += ` C ${cp1x} ${cp1y}, ${cp2x} ${cp2y}, ${next.x} ${next.y}`;
    }
    return path;
  };

  const linePath = getSmoothPath(points);
  const areaPath = `${linePath} L ${points[points.length - 1].x} ${padding.top + graphHeight} L ${points[0].x} ${padding.top + graphHeight} Z`;

  const yTicks = [
    { value: 2000, label: '2K' },
    { value: 1500, label: '1.5K' },
    { value: 1000, label: '1K' },
    { value: 500, label: '500' },
    { value: 0, label: '0' },
  ];

  return (
    <div
      style={{
        backgroundColor: 'var(--bg-card)',
        borderRadius: 'var(--radius-lg)',
        border: '1px solid var(--border-light)',
        padding: '22px 24px',
        boxShadow: 'var(--shadow-card)',
        display: 'flex',
        flexDirection: 'column',
        height: '100%',
      }}
    >
      {/* Card Header */}
      <div
        style={{
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          marginBottom: '16px',
        }}
      >
        <div>
          <h2
            style={{
              fontSize: '16px',
              fontWeight: '700',
              color: '#12251a',
            }}
          >
            Bookings Overview
          </h2>
          <p style={{ fontSize: '12px', color: '#62766a', marginTop: '2px' }}>
            Daily booked tasks breakdown
          </p>
        </div>

        <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
          {['7d', '1m', '1y'].map((range) => (
            <button
              key={range}
              onClick={() => setSelectedRange(range)}
              style={{
                padding: '4px 10px',
                borderRadius: '6px',
                fontSize: '11px',
                fontWeight: '600',
                textTransform: 'uppercase',
                backgroundColor: selectedRange === range ? '#eaf7ee' : 'transparent',
                color: selectedRange === range ? '#15803d' : '#64748b',
                transition: 'all 0.15s ease',
              }}
            >
              {range}
            </button>
          ))}
        </div>
      </div>

      {/* Interactive SVG Chart */}
      <div style={{ position: 'relative', width: '100%', flex: 1, minHeight: '220px' }}>
        <svg
          viewBox={`0 0 ${width} ${height}`}
          style={{ width: '100%', height: 'auto', overflow: 'visible' }}
        >
          <defs>
            <linearGradient id="bookingAreaGrad" x1="0" y1="0" x2="0" y2="1">
              <stop offset="0%" stop-color="#22864c" stop-opacity="0.18" />
              <stop offset="60%" stop-color="#22864c" stop-opacity="0.05" />
              <stop offset="100%" stop-color="#22864c" stop-opacity="0.0" />
            </linearGradient>
            <filter id="shadowFilter" x="-10%" y="-10%" width="120%" height="120%">
              <feDropShadow dx="0" dy="3" stdDeviation="4" flood-color="#15803d" flood-opacity="0.25" />
            </filter>
          </defs>

          {/* Horizontal Grid lines */}
          {yTicks.map((tick) => {
            const yPos =
              padding.top +
              graphHeight -
              ((tick.value - minVal) / (maxVal - minVal)) * graphHeight;
            return (
              <g key={tick.value}>
                <line
                  x1={padding.left}
                  y1={yPos}
                  x2={width - padding.right}
                  y2={yPos}
                  stroke="#f1f5f3"
                  strokeWidth="1.2"
                  strokeDasharray={tick.value === 0 ? 'none' : '3 3'}
                />
                <text
                  x={padding.left - 10}
                  y={yPos + 4}
                  textAnchor="end"
                  fontSize="11"
                  fontWeight="500"
                  fill="#8c9e94"
                >
                  {tick.label}
                </text>
              </g>
            );
          })}

          {/* Area Gradient Fill */}
          <path d={areaPath} fill="url(#bookingAreaGrad)" />

          {/* Line Path */}
          <path
            d={linePath}
            fill="none"
            stroke="#22864c"
            strokeWidth="3.2"
            strokeLinecap="round"
            strokeLinejoin="round"
            filter="url(#shadowFilter)"
          />

          {/* Vertical Guides and Interactive Data Points */}
          {points.map((pt, idx) => {
            const isHovered = activePoint?.date === pt.date;
            return (
              <g key={idx}>
                {/* X-axis labels */}
                <text
                  x={pt.x}
                  y={height - 8}
                  textAnchor="middle"
                  fontSize="11"
                  fontWeight={isHovered ? '700' : '500'}
                  fill={isHovered ? '#15803d' : '#8c9e94'}
                >
                  {pt.date}
                </text>

                {/* Vertical hover line */}
                {isHovered && (
                  <line
                    x1={pt.x}
                    y1={padding.top}
                    x2={pt.x}
                    y2={padding.top + graphHeight}
                    stroke="#22864c"
                    strokeWidth="1.5"
                    strokeDasharray="4 3"
                    opacity="0.6"
                  />
                )}

                {/* Visible Data Point Node */}
                <circle
                  cx={pt.x}
                  cy={pt.y}
                  r={isHovered ? 6 : 4.5}
                  fill="#22864c"
                  stroke="#ffffff"
                  strokeWidth="2.5"
                  style={{
                    cursor: 'pointer',
                    transition: 'all 0.2s ease',
                  }}
                />

                {/* Hit area for mouse hover */}
                <circle
                  cx={pt.x}
                  cy={pt.y}
                  r="20"
                  fill="transparent"
                  style={{ cursor: 'pointer' }}
                  onMouseEnter={() => setActivePoint(pt)}
                  onMouseLeave={() => setActivePoint(null)}
                />
              </g>
            );
          })}
        </svg>

        {/* Floating Tooltip */}
        {activePoint && (
          <div
            style={{
              position: 'absolute',
              top: `${Math.max(10, activePoint.y - 65)}px`,
              left: `${Math.min(width - 160, Math.max(50, activePoint.x - 60))}px`,
              backgroundColor: '#14291e',
              color: '#ffffff',
              padding: '6px 12px',
              borderRadius: '8px',
              fontSize: '11.5px',
              pointerEvents: 'none',
              boxShadow: '0 6px 16px rgba(0,0,0,0.2)',
              zIndex: 20,
              animation: 'fadeIn 0.15s ease',
              lineHeight: 1.3,
            }}
          >
            <div style={{ fontWeight: '700', color: '#86efac' }}>{activePoint.date}</div>
            <div style={{ fontWeight: '600', marginTop: '2px' }}>
              {activePoint.bookings.toLocaleString()} Bookings
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
