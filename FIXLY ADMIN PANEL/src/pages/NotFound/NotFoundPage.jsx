import React from 'react';
import { useNavigate } from 'react-router-dom';
import { AlertCircle, Home, ArrowLeft } from 'lucide-react';

export default function NotFoundPage() {
  const navigate = useNavigate();

  return (
    <div
      style={{
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        minHeight: '60vh',
        textAlign: 'center',
        padding: '32px',
        animation: 'fadeIn 0.2s ease',
      }}
    >
      <div
        style={{
          width: '72px',
          height: '72px',
          borderRadius: '50%',
          backgroundColor: '#fee2e2',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          color: '#dc2626',
          marginBottom: '20px',
        }}
      >
        <AlertCircle size={36} />
      </div>

      <h1 style={{ fontSize: '28px', fontWeight: '800', color: '#111827' }}>
        404 — Page Not Found
      </h1>
      <p style={{ fontSize: '14px', color: '#64748b', maxWidth: '440px', marginTop: '8px', lineHeight: '1.5' }}>
        The administrative route you are looking for does not exist or has been relocated within the Cooperative Platform.
      </p>

      <div style={{ display: 'flex', gap: '12px', marginTop: '24px' }}>
        <button
          onClick={() => navigate(-1)}
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: '6px',
            padding: '10px 18px',
            borderRadius: '8px',
            border: '1px solid #cbd5e1',
            backgroundColor: '#ffffff',
            fontSize: '13px',
            fontWeight: '600',
            color: '#334155',
          }}
        >
          <ArrowLeft size={15} />
          <span>Go Back</span>
        </button>

        <button
          onClick={() => navigate('/dashboard')}
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: '6px',
            padding: '10px 20px',
            borderRadius: '8px',
            backgroundColor: 'var(--primary-brand)',
            color: '#ffffff',
            fontSize: '13px',
            fontWeight: '600',
            boxShadow: 'var(--shadow-pill)',
          }}
        >
          <Home size={15} />
          <span>Return to Dashboard</span>
        </button>
      </div>
    </div>
  );
}
