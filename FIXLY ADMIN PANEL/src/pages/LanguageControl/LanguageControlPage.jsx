import React, { useState, useEffect } from 'react';
import { useApp } from '../../context/AppContext';
import { api } from '../../services/api';
import { useToast } from '../../context/ToastContext';
import { Globe, Save } from 'lucide-react';

const allLanguages = [
  { code: 'en', name: 'English' },
  { code: 'hi', name: 'Hindi' },
  { code: 'ta', name: 'Tamil' },
  { code: 'te', name: 'Telugu' },
  { code: 'kn', name: 'Kannada' },
  { code: 'bn', name: 'Bengali' },
  { code: 'mr', name: 'Marathi' },
  { code: 'gu', name: 'Gujarati' }
];

export default function LanguageControlPage() {
  const { adminRole } = useApp();
  const { showToast } = useToast();
  const [enabledLanguages, setEnabledLanguages] = useState([]);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    const fetchLanguages = async () => {
      try {
        setLoading(true);
        const res = await api.getEnabledLanguages();
        if (res.success) {
          setEnabledLanguages(res.languages || ['en']);
        }
      } catch (err) {
        // Fallback or ignore
        setEnabledLanguages(['en']);
      } finally {
        setLoading(false);
      }
    };
    fetchLanguages();
  }, []);

  const handleToggle = (code) => {
    setEnabledLanguages((prev) => 
      prev.includes(code) ? prev.filter(c => c !== code) : [...prev, code]
    );
  };

  const handleSave = async () => {
    try {
      setSaving(true);
      const res = await api.updateEnabledLanguages(enabledLanguages);
      if (res.success) {
        showToast('success', 'Languages updated successfully');
      }
    } catch (err) {
      showToast('error', 'Failed to update languages');
    } finally {
      setSaving(false);
    }
  };

  if (adminRole !== 'super_admin') {
    return (
      <div style={{ padding: '32px', textAlign: 'center' }}>
        <h2>Unauthorized</h2>
        <p>You do not have permission to view this page.</p>
      </div>
    );
  }

  return (
    <div style={{ padding: '0 32px 32px', animation: 'fadeIn 0.2s ease' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 24 }}>
        <div>
          <h2 style={{ fontSize: 24, fontWeight: 700, color: '#111827', display: 'flex', alignItems: 'center', gap: 10 }}>
            <Globe size={26} color="var(--primary-brand)" /> Language Control
          </h2>
          <p style={{ fontSize: 14, color: '#64748b', marginTop: 4 }}>
            Toggle which languages are available on the platform.
          </p>
        </div>
        <button
          onClick={handleSave}
          disabled={saving}
          style={{ padding: '10px 20px', borderRadius: 8, background: 'var(--primary-brand)', color: '#fff', border: 'none', cursor: 'pointer', display: 'flex', gap: 8, alignItems: 'center', fontWeight: 600 }}
        >
          <Save size={18} /> {saving ? 'Saving...' : 'Save Changes'}
        </button>
      </div>

      <div style={{ background: '#fff', borderRadius: 16, padding: '24px', border: '1px solid var(--border-light)' }}>
        {loading ? (
          <div>Loading...</div>
        ) : (
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(250px, 1fr))', gap: 20 }}>
            {allLanguages.map((lang) => (
              <div key={lang.code} style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '16px', border: '1px solid #e2e8f0', borderRadius: 12 }}>
                <span style={{ fontSize: 16, fontWeight: 500, color: '#1e293b' }}>{lang.name}</span>
                <label style={{ display: 'flex', alignItems: 'center', cursor: 'pointer' }}>
                  <input
                    type="checkbox"
                    checked={enabledLanguages.includes(lang.code)}
                    onChange={() => handleToggle(lang.code)}
                    style={{
                      width: 20,
                      height: 20,
                      accentColor: 'var(--primary-brand)'
                    }}
                  />
                </label>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
