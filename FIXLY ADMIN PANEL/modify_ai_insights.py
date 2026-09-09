import re

with open('src/pages/AIInsights/AIInsightsPage.jsx', 'r') as f:
    content = f.read()

# Add activeTab state
content = content.replace(
    "  const [loading, setLoading] = useState(true);",
    "  const [loading, setLoading] = useState(true);\n  const [activeTab, setActiveTab] = useState('insights');"
)

# Add tabs UI
tabs_ui = """
      {/* Tabs */}
      <div style={{ display: 'flex', gap: '8px', borderBottom: '1px solid var(--border-light)', marginBottom: '18px' }}>
        {[
          { key: 'insights', label: 'AI Directives' },
          { key: 'heatmap', label: 'Demand Heatmap' },
        ].map((t) => (
          <button
            key={t.key}
            onClick={() => setActiveTab(t.key)}
            style={{
              padding: '10px 16px',
              fontSize: '13px',
              fontWeight: activeTab === t.key ? '700' : '500',
              color: activeTab === t.key ? 'var(--primary-brand)' : '#64748b',
              borderBottom: activeTab === t.key ? '2.5px solid var(--primary-brand)' : 'none',
              marginBottom: '-1px',
              background: 'none',
              cursor: 'pointer'
            }}
          >
            {t.label}
          </button>
        ))}
      </div>
"""

content = content.replace("      {/* Summary KPI Banner */}", tabs_ui + "\n      {/* Summary KPI Banner */}")

# Wrap existing content in Insights tab
content = content.replace("      {/* Summary KPI Banner */}", "      {activeTab === 'insights' && (\n        <>\n      {/* Summary KPI Banner */}")
# Find the end of AIInsightsPage and close the Insights tab, then add Heatmap tab
end_code = """
        </>
      )}

      {/* Demand Heatmap Tab */}
      {activeTab === 'heatmap' && (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
          <h3 style={{ fontSize: '16px', fontWeight: '700', color: '#111827' }}>Predicted Demand (Next 24h)</h3>
          <div style={{ backgroundColor: '#ffffff', borderRadius: '16px', border: '1px solid var(--border-light)', overflow: 'hidden', boxShadow: 'var(--shadow-card)' }}>
            <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left', fontSize: '13px' }}>
              <thead>
                <tr style={{ backgroundColor: '#f8faf9', borderBottom: '1px solid #e6ede8', color: '#55695e', fontSize: '12px', fontWeight: '700' }}>
                  <th style={{ padding: '12px 18px' }}>Service Area / Category</th>
                  <th style={{ padding: '12px 18px' }}>Forecast Level</th>
                  <th style={{ padding: '12px 18px' }}>Recommended Techs</th>
                  <th style={{ padding: '12px 18px' }}>Status</th>
                </tr>
              </thead>
              <tbody>
                {aiData.demandForecast && aiData.demandForecast.length > 0 ? aiData.demandForecast.map((item, idx) => (
                  <tr key={idx} style={{ borderBottom: '1px solid #f1f5f3' }}>
                    <td style={{ padding: '14px 18px', fontWeight: '700', color: '#1e293b' }}>{item.category}</td>
                    <td style={{ padding: '14px 18px' }}>
                      <span style={{ fontSize: '11px', fontWeight: '700', color: item.currentDemand === 'High' ? '#ef4444' : item.currentDemand === 'Moderate' ? '#f59e0b' : '#10b981', backgroundColor: item.currentDemand === 'High' ? '#fef2f2' : item.currentDemand === 'Moderate' ? '#fffbeb' : '#ecfdf5', padding: '3px 8px', borderRadius: '6px' }}>
                        {item.currentDemand.toUpperCase()}
                      </span>
                    </td>
                    <td style={{ padding: '14px 18px', fontWeight: '600', color: '#0f172a' }}>{Math.max(2, item.expectedBookingsToday * 2)} required</td>
                    <td style={{ padding: '14px 18px', color: '#64748b' }}>{item.predictedTrend}</td>
                  </tr>
                )) : (
                  <tr>
                    <td colSpan="4" style={{ padding: '30px', textAlign: 'center', color: '#64748b', fontSize: '13px' }}>
                      No forecast data available.
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
          
          <div style={{ backgroundColor: '#e5f3ea', height: '400px', borderRadius: '16px', display: 'flex', alignItems: 'center', justifyContent: 'center', border: '1px solid var(--border-light)', flexDirection: 'column', gap: '10px' }}>
            <MapPin size={40} color="#15803d" />
            <div style={{ fontWeight: '600', color: '#15803d' }}>Heatmap visualization initialized.</div>
            <div style={{ fontSize: '12px', color: '#166534' }}>Render map with D3.js or Leaflet to show hot zones.</div>
          </div>
        </div>
      )}
    </div>
  );
}
"""

content = re.sub(r"    </div>\n  \);\n}\n?$", end_code, content)

with open('src/pages/AIInsights/AIInsightsPage.jsx', 'w') as f:
    f.write(content)

