import re
with open('FIXLY ADMIN PANEL/src/pages/Settings/SettingsPage.jsx', 'r') as f:
    content = f.read()

# Add to platformForm state
content = re.sub(
    r'(emergencyHotline: \'\+91 98765 43210\')',
    r"\1,\n    apiKeys: {\n      groqApiKey: '',\n      geminiApiKey: '',\n      cloudinaryUrl: '',\n      fixlySupportNumber: '1800-123-4567'\n    }",
    content
)

# Also update the useEffect block for settings
content = re.sub(
    r'(emergencyHotline: settings\.emergencyHotline \|\| \'\+91 98765 43210\')',
    r"\1,\n        apiKeys: settings.apiKeys || { groqApiKey: '', geminiApiKey: '', cloudinaryUrl: '', fixlySupportNumber: '1800-123-4567' }",
    content
)

# Add to the tabs array
content = re.sub(
    r"(\{ key: 'profile', label: 'Admin Identity', icon: User \},)",
    r"{ key: 'api_keys', label: 'API Keys', icon: LinkIcon },\n          \1",
    content
)

# Add the UI for the tab right before TAB 6: ADMIN IDENTITY
ui_code = """
      {/* ========================================================= */}
      {/* TAB: API KEYS & INTEGRATIONS */}
      {/* ========================================================= */}
      {activeTab === 'api_keys' && (
        <form onSubmit={handleSavePlatform} style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
          <div style={{ backgroundColor: '#fff', padding: '24px', borderRadius: '16px', border: '1px solid #e2e8f0' }}>
            <h3 style={{ fontSize: '18px', fontWeight: '700', marginBottom: '8px' }}>API Keys & Third-Party Integrations</h3>
            <div style={{ backgroundColor: '#fef2f2', border: '1px solid #fecaca', padding: '12px', borderRadius: '8px', marginBottom: '20px' }}>
              <p style={{ color: '#b91c1c', fontSize: '13px', margin: 0 }}>
                <strong>Note:</strong> Changes to API keys may require a server restart to take full effect in backend AI services.
              </p>
            </div>
            
            <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
              <div>
                <label style={{ display: 'block', fontSize: '13px', fontWeight: '600', marginBottom: '4px' }}>Groq API Key (Llama 3)</label>
                <input
                  type="password"
                  value={platformForm.apiKeys?.groqApiKey || ''}
                  onChange={(e) => setPlatformForm({ ...platformForm, apiKeys: { ...platformForm.apiKeys, groqApiKey: e.target.value } })}
                  placeholder="gsk_..."
                  style={{ width: '100%', padding: '10px', borderRadius: '8px', border: '1px solid #cbd5e1' }}
                />
              </div>
              
              <div>
                <label style={{ display: 'block', fontSize: '13px', fontWeight: '600', marginBottom: '4px' }}>Gemini API Key (Vision)</label>
                <input
                  type="password"
                  value={platformForm.apiKeys?.geminiApiKey || ''}
                  onChange={(e) => setPlatformForm({ ...platformForm, apiKeys: { ...platformForm.apiKeys, geminiApiKey: e.target.value } })}
                  placeholder="AIza..."
                  style={{ width: '100%', padding: '10px', borderRadius: '8px', border: '1px solid #cbd5e1' }}
                />
              </div>
              
              <div>
                <label style={{ display: 'block', fontSize: '13px', fontWeight: '600', marginBottom: '4px' }}>Cloudinary URL</label>
                <input
                  type="text"
                  value={platformForm.apiKeys?.cloudinaryUrl || ''}
                  onChange={(e) => setPlatformForm({ ...platformForm, apiKeys: { ...platformForm.apiKeys, cloudinaryUrl: e.target.value } })}
                  placeholder="cloudinary://..."
                  style={{ width: '100%', padding: '10px', borderRadius: '8px', border: '1px solid #cbd5e1' }}
                />
              </div>
              
              <div>
                <label style={{ display: 'block', fontSize: '13px', fontWeight: '600', marginBottom: '4px' }}>Fixly Support Number</label>
                <input
                  type="text"
                  value={platformForm.apiKeys?.fixlySupportNumber || ''}
                  onChange={(e) => setPlatformForm({ ...platformForm, apiKeys: { ...platformForm.apiKeys, fixlySupportNumber: e.target.value } })}
                  placeholder="1800-..."
                  style={{ width: '100%', padding: '10px', borderRadius: '8px', border: '1px solid #cbd5e1' }}
                />
              </div>
            </div>
            
            <div style={{ marginTop: '20px', display: 'flex', justifyContent: 'flex-end' }}>
              <button
                type="submit"
                disabled={savingPlatform}
                style={{
                  padding: '10px 20px', backgroundColor: '#15803d', color: 'white', borderRadius: '8px', fontWeight: '600', border: 'none', cursor: 'pointer'
                }}
              >
                {savingPlatform ? 'Saving...' : 'Save API Keys'}
              </button>
            </div>
          </div>
        </form>
      )}
      
"""
content = re.sub(
    r"({\/\* TAB 6: ADMIN IDENTITY & PROFILE \*\/})",
    ui_code.replace('\\', '\\\\') + r"\1",
    content
)

with open('FIXLY ADMIN PANEL/src/pages/Settings/SettingsPage.jsx', 'w') as f:
    f.write(content)

