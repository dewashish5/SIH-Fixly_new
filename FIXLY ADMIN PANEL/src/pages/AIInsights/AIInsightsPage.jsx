import React, { useState, useEffect } from 'react';
import {
  BrainCircuit,
  Sparkles,
  TrendingUp,
  AlertTriangle,
  Clock,
  MapPin,
  CheckCircle,
  Zap,
  Layers,
  ArrowRight
} from 'lucide-react';
import { api } from '../../services/api';
import { useToast } from '../../context/ToastContext';

export default function AIInsightsPage() {
  const { showToast } = useToast();
  const [aiData, setAiData] = useState({
    summary: {
      confidenceScore: '94.8%',
      predictedSurgeCategory: 'Plumbing & AC Repair',
      peakDemandWindow: '11:00 AM – 02:00 PM & 06:00 PM – 09:00 PM',
      deficitRiskArea: 'Moderate in Mumbai Bandra Sector',
      recommendedStandby: 15
    },
    directives: [
      {
        id: 'dir-1',
        title: 'Dynamic Surge Dispatch in East Delhi',
        priority: 'Immediate',
        priorityColor: '#dc2626',
        description: 'AI model detects a 3.4x uptick in plumbing calls due to municipal water line maintenance in Sector 18 & Mayur Vihar.',
        impact: 'Prevents 45+ min wait time delays',
        actionLabel: 'Deploy 15 Standby Workers'
      },
      {
        id: 'dir-2',
        title: 'Weekend HVAC Technician Balancing in Pune',
        priority: 'Medium',
        priorityColor: '#d97706',
        description: 'Predicted 38°C weekend temperature forecast likely to increase AC breakdown tickets by +34%.',
        impact: 'Guarantees SLA completion rate above 98%',
        actionLabel: 'Pre-Schedule 20 Tech Shifts'
      },
      {
        id: 'dir-3',
        title: 'Fair Gig Allocation Equalizer Alert',
        priority: 'Low',
        priorityColor: '#2563eb',
        description: 'Algorithm detected 8 newly onboarded carpentry members with 0 assignments in past 48h.',
        impact: 'Enhances worker retention and earnings parity',
        actionLabel: 'Trigger Priority Fair Rotation'
      }
    ],
    demandForecast: [
      {
        category: 'Plumbing',
        currentDemand: 'High',
        predictedTrend: '+18% Surge',
        expectedBookingsToday: 25,
        peakHours: '08:00 AM - 11:30 AM',
        action: 'Pre-allocate 25 on-standby plumbers in Noida & East Delhi zones.'
      },
      {
        category: 'Electrical',
        currentDemand: 'Moderate',
        predictedTrend: '+12% Increase',
        expectedBookingsToday: 18,
        peakHours: '04:00 PM - 07:30 PM',
        action: 'Shift 18 electricians towards Indira Nagar & Gachibowli clusters.'
      },
      {
        category: 'AC Repair & Jet Service',
        currentDemand: 'Critical',
        predictedTrend: '+45% Spike',
        expectedBookingsToday: 30,
        peakHours: '12:00 PM - 04:00 PM',
        action: 'Activate emergency surge fee discount for non-peak slot bookings.'
      },
      {
        category: 'Cleaning & Sanitization',
        currentDemand: 'Normal',
        predictedTrend: 'Stable',
        expectedBookingsToday: 12,
        peakHours: '07:00 AM - 10:00 AM',
        action: 'Maintain standard dispatch queue without additional incentive bonus.'
      }
    ]
  });

  useEffect(() => {
    const fetchAI = async () => {
      try {
        const res = await api.getAIInsights();
        if (res.success && res.summary) {
          setAiData({
            summary: res.summary,
            directives: res.directives || [],
            demandForecast: res.demandForecast || []
          });
        }
      } catch (err) {
        console.error('Failed to load AI Insights:', err);
      }
    };
    fetchAI();
  }, []);

  const handleExecuteRecommendation = (actionLabel) => {
    showToast('success', `AI Directive Executed: ${actionLabel}`);
  };

  return (
    <div style={{ padding: '0 32px 32px 32px', animation: 'fadeIn 0.2s ease', display: 'flex', flexDirection: 'column', gap: '22px' }}>
      {/* Header with AI Model Status */}
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
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
            <h2 style={{ fontSize: '20px', fontWeight: '700', color: '#111827' }}>
              AI Demand Forecasting & Workforce Equalizer
            </h2>
            <span
              style={{
                fontSize: '11px',
                fontWeight: '700',
                padding: '2px 8px',
                borderRadius: '999px',
                backgroundColor: '#eaf8ef',
                color: '#15803d',
                display: 'inline-flex',
                alignItems: 'center',
                gap: '4px',
              }}
            >
              <Sparkles size={11} />
              <span>Model Active</span>
            </span>
          </div>
          <p style={{ fontSize: '13px', color: '#64748b' }}>
            Predictive demand curves, heat-cluster routing, and fair gig rotation recommendations
          </p>
        </div>

        <div style={{ fontSize: '12px', color: '#15803d', fontWeight: '600', backgroundColor: '#eaf8ef', padding: '6px 12px', borderRadius: '8px' }}>
          🧠 Predictive Accuracy: <strong>{aiData.summary.confidenceScore}</strong>
        </div>
      </div>

      {/* 3 Top AI Intelligence Summary Cards */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: '16px' }}>
        <div style={{ backgroundColor: '#ffffff', padding: '20px', borderRadius: '16px', border: '1px solid var(--border-light)' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px', color: '#dc2626', fontWeight: '700', fontSize: '13px' }}>
            <Zap size={16} />
            <span>Highest Surge Predicted</span>
          </div>
          <div style={{ fontSize: '20px', fontWeight: '800', color: '#111827', marginTop: '6px' }}>
            {aiData.summary.predictedSurgeCategory}
          </div>
          <div style={{ fontSize: '12px', color: '#64748b', marginTop: '3px' }}>
            Spike expected due to high afternoon temperatures
          </div>
        </div>

        <div style={{ backgroundColor: '#ffffff', padding: '20px', borderRadius: '16px', border: '1px solid var(--border-light)' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px', color: '#15803d', fontWeight: '700', fontSize: '13px' }}>
            <Clock size={16} />
            <span>Peak Demand Window</span>
          </div>
          <div style={{ fontSize: '18px', fontWeight: '800', color: '#111827', marginTop: '6px' }}>
            {aiData.summary.peakDemandWindow}
          </div>
          <div style={{ fontSize: '12px', color: '#15803d', fontWeight: '600', marginTop: '3px' }}>
            Recommendation: Stage {aiData.summary.recommendedStandby || 15} standby workers
          </div>
        </div>

        <div style={{ backgroundColor: '#ffffff', padding: '20px', borderRadius: '16px', border: '1px solid var(--border-light)' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px', color: '#d97706', fontWeight: '700', fontSize: '13px' }}>
            <AlertTriangle size={16} />
            <span>Workforce Deficit Risk</span>
          </div>
          <div style={{ fontSize: '18px', fontWeight: '800', color: '#111827', marginTop: '6px' }}>
            {aiData.summary.deficitRiskArea}
          </div>
          <div style={{ fontSize: '12px', color: '#64748b', marginTop: '3px' }}>
            Proactive re-routing active
          </div>
        </div>
      </div>

      {/* AI Proactive Action Recommendations */}
      <div>
        <h3 style={{ fontSize: '16px', fontWeight: '700', color: '#111827', marginBottom: '12px' }}>
          Real-Time AI Operational Directives
        </h3>

        <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
          {aiData.directives.map((rec) => (
            <div
              key={rec.id}
              style={{
                backgroundColor: '#ffffff',
                borderRadius: '14px',
                border: '1.5px solid #bbf7d0',
                padding: '18px 22px',
                boxShadow: 'var(--shadow-card)',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'space-between',
                gap: '16px',
                flexWrap: 'wrap',
              }}
            >
              <div style={{ display: 'flex', gap: '14px', alignItems: 'flex-start' }}>
                <div
                  style={{
                    width: '38px',
                    height: '38px',
                    borderRadius: '10px',
                    backgroundColor: '#eaf7ee',
                    color: '#15803d',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    flexShrink: 0,
                  }}
                >
                  <BrainCircuit size={20} />
                </div>
                <div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                    <h4 style={{ fontSize: '14.5px', fontWeight: '700', color: '#111827' }}>
                      {rec.title}
                    </h4>
                    <span
                      style={{
                        fontSize: '11px',
                        fontWeight: '700',
                        padding: '2px 8px',
                        borderRadius: '4px',
                        backgroundColor: rec.priority === 'Immediate' ? '#fee2e2' : '#fef3c7',
                        color: rec.priority === 'Immediate' ? '#dc2626' : '#b45309',
                      }}
                    >
                      {rec.priority}
                    </span>
                  </div>
                  <p style={{ fontSize: '13px', color: '#475569', marginTop: '3px' }}>
                    {rec.description}
                  </p>
                  <div style={{ fontSize: '12px', color: '#15803d', fontWeight: '600', marginTop: '4px' }}>
                    Impact: {rec.impact}
                  </div>
                </div>
              </div>

              <button
                onClick={() => handleExecuteRecommendation(rec.actionLabel)}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: '6px',
                  padding: '9px 18px',
                  backgroundColor: '#15803d',
                  color: '#ffffff',
                  borderRadius: '8px',
                  fontSize: '13px',
                  fontWeight: '600',
                  border: 'none',
                  cursor: 'pointer',
                  boxShadow: '0 2px 4px rgba(21, 128, 61, 0.2)',
                }}
              >
                <span>{rec.actionLabel}</span>
                <ArrowRight size={14} />
              </button>
            </div>
          ))}
        </div>
      </div>

      {/* Demand Forecast per Service Table */}
      <div style={{ backgroundColor: '#ffffff', borderRadius: '16px', border: '1px solid var(--border-light)', overflow: 'hidden' }}>
        <div style={{ padding: '16px 20px', borderBottom: '1px solid #f1f5f3', fontWeight: '700', fontSize: '15px' }}>
          Service-Wise 24-Hour Demand Forecast & Recommended Allocation
        </div>
        <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left' }}>
          <thead>
            <tr style={{ backgroundColor: '#f8faf9', borderBottom: '1px solid #e6ede8', color: '#55695e', fontSize: '12px', fontWeight: '700' }}>
              <th style={{ padding: '14px 18px' }}>Service Category</th>
              <th style={{ padding: '14px 18px' }}>Current Demand</th>
              <th style={{ padding: '14px 18px' }}>Predicted Trend</th>
              <th style={{ padding: '14px 18px' }}>Expected Bookings Today</th>
              <th style={{ padding: '14px 18px' }}>Peak Demand Hours</th>
              <th style={{ padding: '14px 18px' }}>AI Recommended Action</th>
            </tr>
          </thead>
          <tbody>
            {aiData.demandForecast.map((fc, i) => (
              <tr key={i} style={{ borderBottom: '1px solid #f1f5f3', fontSize: '13px' }}>
                <td style={{ padding: '14px 18px', fontWeight: '700', color: '#111827' }}>
                  {fc.category}
                </td>
                <td style={{ padding: '14px 18px' }}>
                  <span
                    style={{
                      padding: '3px 8px',
                      borderRadius: '4px',
                      fontSize: '11.5px',
                      fontWeight: '700',
                      backgroundColor: fc.currentDemand.includes('High') || fc.currentDemand.includes('Critical') ? '#fee2e2' : '#fef3c7',
                      color: fc.currentDemand.includes('High') || fc.currentDemand.includes('Critical') ? '#dc2626' : '#b45309',
                    }}
                  >
                    {fc.currentDemand}
                  </span>
                </td>
                <td style={{ padding: '14px 18px', fontWeight: '700', color: '#15803d' }}>
                  {fc.predictedTrend}
                </td>
                <td style={{ padding: '14px 18px', fontWeight: '800', color: '#0f172a' }}>
                  ~{fc.expectedBookingsToday.toLocaleString()}
                </td>
                <td style={{ padding: '14px 18px', color: '#475569' }}>
                  {fc.peakHours}
                </td>
                <td style={{ padding: '14px 18px', color: '#1e293b', fontSize: '12.5px' }}>
                  {fc.action}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
