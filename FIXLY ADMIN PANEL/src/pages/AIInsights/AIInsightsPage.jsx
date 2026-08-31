import React from 'react';
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
import { aiInsightsData } from '../../data/aiInsights';
import { useToast } from '../../context/ToastContext';

export default function AIInsightsPage() {
  const { showToast } = useToast();

  const handleExecuteRecommendation = (rec) => {
    showToast('success', `AI Directive Executed: ${rec.actionLabel}`);
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
          🧠 Predictive Accuracy: <strong>{aiInsightsData.summary.confidenceScore}</strong>
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
            {aiInsightsData.summary.predictedSurgeCategory}
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
            {aiInsightsData.summary.peakDemandWindow}
          </div>
          <div style={{ fontSize: '12px', color: '#15803d', fontWeight: '600', marginTop: '3px' }}>
            Recommendation: Stage 45 standby workers
          </div>
        </div>

        <div style={{ backgroundColor: '#ffffff', padding: '20px', borderRadius: '16px', border: '1px solid var(--border-light)' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px', color: '#d97706', fontWeight: '700', fontSize: '13px' }}>
            <AlertTriangle size={16} />
            <span>Workforce Deficit Risk</span>
          </div>
          <div style={{ fontSize: '18px', fontWeight: '800', color: '#111827', marginTop: '6px' }}>
            {aiInsightsData.summary.workforceDeficitRisk}
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
          {aiInsightsData.recommendations.map((rec) => (
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
                        backgroundColor: rec.urgency === 'Immediate' ? '#fee2e2' : '#fef3c7',
                        color: rec.urgency === 'Immediate' ? '#dc2626' : '#b45309',
                      }}
                    >
                      {rec.urgency}
                    </span>
                  </div>
                  <p style={{ fontSize: '13px', color: '#475569', marginTop: '3px' }}>
                    {rec.detail}
                  </p>
                  <div style={{ fontSize: '12px', color: '#15803d', fontWeight: '600', marginTop: '4px' }}>
                    Impact: {rec.impact}
                  </div>
                </div>
              </div>

              <button
                onClick={() => handleExecuteRecommendation(rec)}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: '6px',
                  padding: '9px 18px',
                  backgroundColor: 'var(--primary-brand)',
                  color: '#ffffff',
                  borderRadius: '8px',
                  fontSize: '13px',
                  fontWeight: '600',
                  boxShadow: 'var(--shadow-pill)',
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
            {aiInsightsData.demandForecasts.map((fc, i) => (
              <tr key={i} style={{ borderBottom: '1px solid #f1f5f3', fontSize: '13px' }}>
                <td style={{ padding: '14px 18px', fontWeight: '700', color: '#111827' }}>
                  {fc.service}
                </td>
                <td style={{ padding: '14px 18px' }}>
                  <span
                    style={{
                      padding: '3px 8px',
                      borderRadius: '4px',
                      fontSize: '11.5px',
                      fontWeight: '700',
                      backgroundColor: fc.currentDemand.includes('High') ? '#fee2e2' : '#fef3c7',
                      color: fc.currentDemand.includes('High') ? '#dc2626' : '#b45309',
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
                  {fc.recommendedAction}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
