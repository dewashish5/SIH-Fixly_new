import React from 'react';
import { MapPin, Navigation } from 'lucide-react';

export default function WorkersMapCard({ onOpenMapModal }) {
  return (
    <div
      style={{
        backgroundColor: 'var(--bg-card)',
        borderRadius: 'var(--radius-lg)',
        border: '1px solid var(--border-light)',
        padding: '20px 24px',
        boxShadow: 'var(--shadow-card)',
        position: 'relative',
        overflow: 'hidden',
        display: 'flex',
        flexDirection: 'column',
        justifyContent: 'space-between',
        height: '100%',
        minHeight: '190px',
      }}
    >
      {/* Title & Live Status */}
      <div style={{ position: 'relative', zIndex: 2, maxWidth: '200px' }}>
        <h2
          style={{
            fontSize: '16px',
            fontWeight: '700',
            color: '#12251a',
            lineHeight: '1.3',
          }}
        >
          Workers on Duty Live on Map
        </h2>
        <div
          style={{
            display: 'inline-flex',
            alignItems: 'center',
            gap: '6px',
            marginTop: '6px',
            fontSize: '11px',
            color: '#15803d',
            fontWeight: '600',
            backgroundColor: '#eaf8ef',
            padding: '2px 8px',
            borderRadius: '999px',
          }}
        >
          <span
            style={{
              width: '6px',
              height: '6px',
              borderRadius: '50%',
              backgroundColor: '#15803d',
              boxShadow: '0 0 0 2px #bbf7d0',
            }}
          />
          <span>12,458 Online</span>
        </div>
      </div>

      {/* Background & Illustration container */}
      <div
        style={{
          position: 'absolute',
          right: '-10px',
          bottom: '-15px',
          top: '0',
          width: '60%',
          pointerEvents: 'none',
          zIndex: 1,
          display: 'flex',
          alignItems: 'flex-end',
          justifyContent: 'flex-end',
        }}
      >
        <img
          src="/worker-illustration.svg"
          alt="Workers on Duty Live Map Illustration"
          style={{
            width: '100%',
            height: '100%',
            objectFit: 'contain',
            objectPosition: 'bottom right',
          }}
        />
      </div>

      {/* Button: View Map */}
      <div style={{ position: 'relative', zIndex: 2, marginTop: '20px' }}>
        <button
          onClick={onOpenMapModal}
          style={{
            display: 'inline-flex',
            alignItems: 'center',
            gap: '8px',
            backgroundColor: 'var(--primary-brand)',
            color: '#ffffff',
            padding: '9px 18px',
            borderRadius: 'var(--radius-pill)',
            fontSize: '13px',
            fontWeight: '600',
            boxShadow: 'var(--shadow-pill)',
            transition: 'all 0.18s ease',
          }}
          onMouseEnter={(e) => {
            e.currentTarget.style.backgroundColor = 'var(--primary-brand-hover)';
            e.currentTarget.style.transform = 'translateY(-1px)';
          }}
          onMouseLeave={(e) => {
            e.currentTarget.style.backgroundColor = 'var(--primary-brand)';
            e.currentTarget.style.transform = 'translateY(0)';
          }}
        >
          <span>View Map</span>
          <Navigation size={13} strokeWidth={2.4} />
        </button>
      </div>
    </div>
  );
}
