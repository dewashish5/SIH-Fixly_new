import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';

/**
 * Bootstrap federation session in a new tab without touching parent tab sessionStorage.
 * Payload arrives in location.hash as base64 JSON { token, user }.
 */
export default function ImpersonatePage() {
  const navigate = useNavigate();
  const [error, setError] = useState('');

  useEffect(() => {
    try {
      const raw = window.location.hash.replace(/^#/, '');
      if (!raw) {
        setError('Missing login payload');
        return;
      }
      const decoded = JSON.parse(atob(decodeURIComponent(raw)));
      if (!decoded?.token || !decoded?.user) {
        setError('Invalid login payload');
        return;
      }
      sessionStorage.setItem('adminToken', decoded.token);
      sessionStorage.setItem('adminUser', JSON.stringify(decoded.user));
      // Avoid localStorage so super-admin tab stays intact
      window.history.replaceState(null, '', '/impersonate');
      window.location.replace('/dashboard');
    } catch (err) {
      setError(err.message || 'Failed to open federation session');
    }
  }, [navigate]);

  if (error) {
    return (
      <div style={{ minHeight: '100vh', display: 'grid', placeItems: 'center', padding: 24 }}>
        <div style={{ textAlign: 'center' }}>
          <h2 style={{ marginBottom: 8 }}>Federation login failed</h2>
          <p style={{ color: '#64748b', marginBottom: 16 }}>{error}</p>
          <a href="/federations" style={{ color: '#2563EB', fontWeight: 700 }}>Back to Federations</a>
        </div>
      </div>
    );
  }

  return (
    <div style={{ minHeight: '100vh', display: 'grid', placeItems: 'center', color: '#64748b' }}>
      Opening federation panel…
    </div>
  );
}
