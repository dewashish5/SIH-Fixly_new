export const aiInsightsData = {
  summary: {
    predictedSurgeCategory: 'Plumbing & AC Repair',
    peakDemandWindow: '11:00 AM - 02:00 PM & 06:00 PM - 09:00 PM',
    workforceDeficitRisk: 'Moderate in Mumbai Bandra Sector',
    confidenceScore: '94.8%',
  },

  demandForecasts: [
    {
      service: 'Plumbing',
      currentDemand: 'High',
      predictedTrend: '+18% Surge',
      expectedBookingsToday: 2450,
      riskLevel: 'Low Deficit',
      recommendedAction: 'Pre-allocate 25 on-standby plumbers in Noida & East Delhi zones.',
      peakHours: '08:00 AM - 11:30 AM',
    },
    {
      service: 'Electrical',
      currentDemand: 'Moderate',
      predictedTrend: '+12% Increase',
      expectedBookingsToday: 1980,
      riskLevel: 'Optimal',
      recommendedAction: 'Shift 10 electricians towards Indirapuram & Ghaziabad clusters.',
      peakHours: '06:00 PM - 09:30 PM',
    },
    {
      service: 'Cleaning',
      currentDemand: 'High',
      predictedTrend: '+8% Increase',
      expectedBookingsToday: 1420,
      riskLevel: 'Optimal',
      recommendedAction: 'Ensure bulk inventory for chemical sanitizers in Gurgaon depots.',
      peakHours: '07:30 AM - 12:00 PM',
    },
    {
      service: 'AC Repair',
      currentDemand: 'Extreme High',
      predictedTrend: '+28% Spike',
      expectedBookingsToday: 1250,
      riskLevel: 'High Deficit Risk',
      recommendedAction: 'Activate 35 certified partner technicians from adjacent sectors.',
      peakHours: '12:00 PM - 05:00 PM',
    },
    {
      service: 'Carpentry',
      currentDemand: 'Moderate',
      predictedTrend: '+6% Steady',
      expectedBookingsToday: 950,
      riskLevel: 'Optimal',
      recommendedAction: 'Standard queue routing sufficient.',
      peakHours: '10:00 AM - 03:00 PM',
    },
  ],

  recommendations: [
    {
      id: 'REC-01',
      title: 'Dynamic Surge Dispatch in East Delhi',
      detail: 'AI model detects a 3.4x uptick in plumbing calls due to municipal water line maintenance in Sector 18 & Mayur Vihar.',
      actionLabel: 'Deploy 15 Standby Workers',
      urgency: 'Immediate',
      impact: 'Prevents 45+ min wait time delays',
    },
    {
      id: 'REC-02',
      title: 'Weekend HVAC Technician Balancing in Pune',
      detail: 'Predicted 38°C weekend temperature forecast likely to increase AC breakdown tickets by +34%.',
      actionLabel: 'Pre-Schedule 20 Tech Shifts',
      urgency: 'Medium',
      impact: 'Guarantees SLA completion rate above 98%',
    },
    {
      id: 'REC-03',
      title: 'Fair Gig Allocation Equalizer Alert',
      detail: 'Algorithm detected 8 newly onboarded carpentry members with 0 assignments in past 48h.',
      actionLabel: 'Trigger Priority Fair Rotation',
      urgency: 'Low',
      impact: 'Enhances worker retention and earnings parity',
    }
  ]
};
