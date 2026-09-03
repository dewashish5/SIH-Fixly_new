import React, { useState } from 'react';
import { User } from 'lucide-react';

const DUMMY_SUBSTRINGS = [
  'images.unsplash.com',
  'photo-1534528741775-53994a69daeb',
  'photo-1540569014015-19a7be504e3a',
  'dicebear.com',
  'placeholder'
];

function isDummyOrEmpty(url) {
  if (!url || typeof url !== 'string' || url.trim() === '') return true;
  const lower = url.toLowerCase();
  return DUMMY_SUBSTRINGS.some((sub) => lower.includes(sub));
}

function getInitials(name) {
  if (!name || typeof name !== 'string') return '';
  const parts = name.trim().split(/\s+/).filter(Boolean);
  if (parts.length === 0) return '';
  if (parts.length === 1) return parts[0].slice(0, 2).toUpperCase();
  return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
}

const BG_PALETTES = [
  { bg: '#eaf7ee', text: '#15803d', border: '#86efac' },
  { bg: '#eff6ff', text: '#1d4ed8', border: '#93c5fd' },
  { bg: '#fef3c7', text: '#b45309', border: '#fcd34d' },
  { bg: '#f3e8ff', text: '#7e22ce', border: '#d8b4fe' },
  { bg: '#fce7f3', text: '#be185d', border: '#fbcfe8' },
  { bg: '#f1f5f9', text: '#334155', border: '#cbd5e1' },
];

function getPalette(name) {
  if (!name) return BG_PALETTES[0];
  let hash = 0;
  for (let i = 0; i < name.length; i++) {
    hash = name.charCodeAt(i) + ((hash << 5) - hash);
  }
  const idx = Math.abs(hash) % BG_PALETTES.length;
  return BG_PALETTES[idx];
}

export default function Avatar({
  src,
  name = '',
  size = 38,
  alt = 'Avatar',
  border,
  style = {},
  className = '',
  iconSize
}) {
  const [imgError, setImgError] = useState(false);

  const hasCustomValidSrc = !isDummyOrEmpty(src) && !imgError;
  const initials = getInitials(name);
  const palette = getPalette(name);

  const effectiveBorder = border || (hasCustomValidSrc ? '1.5px solid #22c55e' : `1.5px solid ${palette.border}`);

  if (hasCustomValidSrc) {
    return (
      <img
        src={src}
        alt={alt || name || 'User Avatar'}
        onError={() => setImgError(true)}
        className={className}
        style={{
          width: `${size}px`,
          height: `${size}px`,
          borderRadius: '50%',
          objectFit: 'cover',
          border: effectiveBorder,
          flexShrink: 0,
          ...style,
        }}
      />
    );
  }

  // Fallback: initials or User icon
  return (
    <div
      className={className}
      style={{
        width: `${size}px`,
        height: `${size}px`,
        borderRadius: '50%',
        backgroundColor: palette.bg,
        color: palette.text,
        border: effectiveBorder,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        fontWeight: '700',
        fontSize: `${Math.max(10, Math.round(size * 0.36))}px`,
        letterSpacing: '-0.2px',
        userSelect: 'none',
        flexShrink: 0,
        ...style,
      }}
      title={name || alt}
    >
      {initials ? initials : <User size={iconSize || Math.round(size * 0.5)} />}
    </div>
  );
}
