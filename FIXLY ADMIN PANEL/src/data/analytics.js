export const analyticsData = {
  // Chart 1: Bookings Growth (Filtered by range)
  bookingsByRange: {
    Today: [
      { time: '06:00', bookings: 45, completed: 40, revenue: 18000 },
      { time: '09:00', bookings: 120, completed: 110, revenue: 48000 },
      { time: '12:00', bookings: 190, completed: 175, revenue: 82000 },
      { time: '15:00', bookings: 160, completed: 145, revenue: 69000 },
      { time: '18:00', bookings: 240, completed: 210, revenue: 105000 },
      { time: '21:00', bookings: 110, completed: 95, revenue: 44000 },
    ],
    'This Week': [
      { date: '20 May', bookings: 520, completed: 490, revenue: 210000 },
      { date: '21 May', bookings: 1040, completed: 980, revenue: 425000 },
      { date: '22 May', bookings: 680, completed: 640, revenue: 290000 },
      { date: '23 May', bookings: 1280, completed: 1210, revenue: 540000 },
      { date: '24 May', bookings: 1620, completed: 1540, revenue: 690000 },
      { date: '25 May', bookings: 1080, completed: 1020, revenue: 460000 },
      { date: '26 May', bookings: 1940, completed: 1830, revenue: 840000 },
    ],
    'This Month': [
      { date: 'Week 1', bookings: 4200, completed: 3980, revenue: 1780000 },
      { date: 'Week 2', bookings: 5600, completed: 5320, revenue: 2380000 },
      { date: 'Week 3', bookings: 6800, completed: 6490, revenue: 2910000 },
      { date: 'Week 4', bookings: 8789, completed: 8350, revenue: 3740000 },
    ],
    'This Year': [
      { month: 'Jan', bookings: 18200, revenue: 7800000 },
      { month: 'Feb', bookings: 21400, revenue: 9200000 },
      { month: 'Mar', bookings: 26800, revenue: 11400000 },
      { month: 'Apr', bookings: 31200, revenue: 13300000 },
      { month: 'May', bookings: 38900, revenue: 16800000 },
    ]
  },

  // Chart 2: Revenue vs Worker Payouts vs Welfare Fund
  revenueBreakdown: [
    { name: 'Direct Worker Earnings (95%)', value: 23339496, color: '#1e7e45' },
    { name: 'Cooperative Welfare Reserve (5%)', value: 1228394, color: '#22c55e' },
  ],

  // Chart 3: City Demand Share
  cityDemand: [
    { city: 'Delhi NCR', bookings: 4620, workers: 6450, growth: '+22%' },
    { city: 'Mumbai MMR', bookings: 2840, workers: 3820, growth: '+18%' },
    { city: 'Pune', bookings: 1329, workers: 2188, growth: '+14%' },
  ],

  // KPIs
  kpis: {
    avgResponseTime: '18 mins',
    responseTimeTrend: '-12% faster',
    workerRetention: '94.2%',
    customerRetention: '88.6%',
    cancellationRate: '2.4%',
    npsScore: '78 / 100',
  }
};
