import React from 'react';
import { statsData } from '../data/mockData';
import StatCard from '../components/StatCard';
import BookingsChart from '../components/BookingsChart';
import TopServicesCard from '../components/TopServicesCard';
import RecentBookingsTable from '../components/RecentBookingsTable';
import WorkersMapCard from '../components/WorkersMapCard';

export default function DashboardView({
  onOpenMapModal,
  onSelectBooking,
  onSelectService,
}) {
  return (
    <div
      style={{
        display: 'flex',
        flexDirection: 'column',
        gap: '24px',
        padding: '0 32px 32px 32px',
        animation: 'fadeIn 0.25s ease',
      }}
    >
      {/* 1. Top Row: 4 Metric Cards */}
      <div
        className="stats-grid"
        style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(4, minmax(0, 1fr))',
          gap: '18px',
        }}
      >
        {statsData.map((stat) => (
          <StatCard key={stat.id} item={stat} />
        ))}
      </div>

      {/* 2. Middle Row: Bookings Overview (62%) + Top Services (38%) */}
      <div
        className="middle-grid"
        style={{
          display: 'grid',
          gridTemplateColumns: '1.65fr 1fr',
          gap: '20px',
          alignItems: 'stretch',
        }}
      >
        <div style={{ minHeight: '310px' }}>
          <BookingsChart />
        </div>
        <div style={{ minHeight: '310px' }}>
          <TopServicesCard onSelectService={onSelectService} />
        </div>
      </div>

      {/* 3. Bottom Row: Recent Bookings (62%) + Workers on Duty Live on Map (38%) */}
      <div
        className="bottom-grid"
        style={{
          display: 'grid',
          gridTemplateColumns: '1.65fr 1fr',
          gap: '20px',
          alignItems: 'stretch',
        }}
      >
        <div style={{ minHeight: '230px' }}>
          <RecentBookingsTable onSelectBooking={onSelectBooking} />
        </div>
        <div style={{ minHeight: '230px' }}>
          <WorkersMapCard onOpenMapModal={onOpenMapModal} />
        </div>
      </div>
    </div>
  );
}
