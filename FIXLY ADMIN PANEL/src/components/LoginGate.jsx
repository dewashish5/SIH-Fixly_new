import React, { useState } from 'react';
import { login as apiLogin } from '../api/adminApi';
import { clearAuthSession } from '../api/client';

export default function LoginGate({ onSuccess }) {
  const [email, setEmail] = useState('admin@fixly.local');
  const [password, setPassword] = useState('Admin123!');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setLoading(true);
    try {
      const result = await apiLogin(email.trim(), password);
      if (result.user?.role && result.user.role !== 'admin') {
        clearAuthSession();
        setError('Admin role required. This account is not an admin.');
        return;
      }
      onSuccess?.(result);
    } catch (err) {
      clearAuthSession();
      setError(err.message || 'Login failed');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div
      style={{
        minHeight: '100vh',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        background: 'linear-gradient(145deg, #0c4a6e 0%, #01668F 45%, #0f172a 100%)',
        padding: '24px',
      }}
    >
      <form
        onSubmit={handleSubmit}
        style={{
          width: '100%',
          maxWidth: '400px',
          background: '#fff',
          borderRadius: '16px',
          padding: '32px 28px',
          boxShadow: '0 20px 50px rgba(0,0,0,0.25)',
        }}
      >
        <div style={{ marginBottom: '24px', textAlign: 'center' }}>
          <div
            style={{
              fontSize: '28px',
              fontWeight: 800,
              color: '#01668F',
              letterSpacing: '-0.02em',
            }}
          >
            Fixly
          </div>
          <p style={{ margin: '8px 0 0', color: '#64748b', fontSize: '14px' }}>
            Admin Panel — sign in to continue
          </p>
        </div>

        {error ? (
          <div
            style={{
              marginBottom: '16px',
              padding: '10px 12px',
              borderRadius: '8px',
              background: '#fef2f2',
              color: '#b91c1c',
              fontSize: '13px',
              fontWeight: 500,
            }}
          >
            {error}
          </div>
        ) : null}

        <label style={{ display: 'block', fontSize: '13px', fontWeight: 600, color: '#334155', marginBottom: '6px' }}>
          Email
        </label>
        <input
          type="email"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          required
          autoComplete="username"
          style={{
            width: '100%',
            padding: '10px 12px',
            borderRadius: '8px',
            border: '1px solid #e2e8f0',
            marginBottom: '14px',
            fontSize: '14px',
            boxSizing: 'border-box',
          }}
        />

        <label style={{ display: 'block', fontSize: '13px', fontWeight: 600, color: '#334155', marginBottom: '6px' }}>
          Password
        </label>
        <input
          type="password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          required
          autoComplete="current-password"
          style={{
            width: '100%',
            padding: '10px 12px',
            borderRadius: '8px',
            border: '1px solid #e2e8f0',
            marginBottom: '20px',
            fontSize: '14px',
            boxSizing: 'border-box',
          }}
        />

        <button
          type="submit"
          disabled={loading}
          style={{
            width: '100%',
            padding: '12px',
            borderRadius: '10px',
            border: 'none',
            background: loading ? '#64748b' : '#01668F',
            color: '#fff',
            fontWeight: 700,
            fontSize: '14px',
            cursor: loading ? 'wait' : 'pointer',
          }}
        >
          {loading ? 'Signing in…' : 'Sign in'}
        </button>
      </form>
    </div>
  );
}
