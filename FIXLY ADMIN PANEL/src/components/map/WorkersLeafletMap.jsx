import React, { useEffect, useMemo, useRef, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import { MapPin, Phone, Radio, X } from 'lucide-react';
import Avatar from '../common/Avatar';

/** GeoJSON Point is [lng, lat]; Leaflet wants [lat, lng]. */
export function workerLatLng(worker) {
  const c = worker?.coordinates;
  if (Array.isArray(c) && c.length === 2 && Number.isFinite(c[0]) && Number.isFinite(c[1])) {
    return c;
  }
  const geo = worker?.geoCoordinates || worker?.location?.coordinates;
  if (Array.isArray(geo) && geo.length === 2 && Number.isFinite(geo[0]) && Number.isFinite(geo[1])) {
    // stored as GeoJSON [lng, lat]
    return [geo[1], geo[0]];
  }
  return null;
}

export default function WorkersLeafletMap({
  workers = [],
  height = '100%',
  selectedService = 'All',
  onSelectWorker,
}) {
  const mapContainerRef = useRef(null);
  const mapInstanceRef = useRef(null);
  const markersRef = useRef([]);
  const navigate = useNavigate();
  const [activeWorkerPopup, setActiveWorkerPopup] = useState(null);

  const filteredWorkers = useMemo(
    () =>
      workers.filter((w) => {
        if (selectedService === 'All') return true;
        const trade = (w.service || w.category || '').toLowerCase();
        return trade === selectedService.toLowerCase();
      }),
    [workers, selectedService]
  );

  const withGps = useMemo(
    () => filteredWorkers.filter((w) => workerLatLng(w)),
    [filteredWorkers]
  );

  useEffect(() => {
    if (!mapContainerRef.current) return undefined;

    if (!mapInstanceRef.current) {
      const map = L.map(mapContainerRef.current, {
        center: [28.6139, 77.209],
        zoom: 11,
        zoomControl: true,
      });
      L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        attribution: '&copy; OpenStreetMap',
        maxZoom: 18,
      }).addTo(map);
      mapInstanceRef.current = map;
      // Modal / late layout: force size recalc
      setTimeout(() => map.invalidateSize(), 80);
      setTimeout(() => map.invalidateSize(), 300);
    }

    const map = mapInstanceRef.current;
    markersRef.current.forEach((m) => m.remove());
    markersRef.current = [];

    const bounds = [];
    withGps.forEach((w) => {
      const latlng = workerLatLng(w);
      if (!latlng) return;
      bounds.push(latlng);

      const label = String(w.service || w.category || 'WK')
        .replace(/[^a-zA-Z0-9]/g, '')
        .slice(0, 2)
        .toUpperCase() || 'WK';
      const pinColor = '#16a34a';

      const customIcon = L.divIcon({
        className: 'custom-leaflet-marker',
        html: `<div style="
          width:34px;height:34px;border-radius:50%;background:${pinColor};
          border:3px solid #fff;box-shadow:0 4px 12px rgba(0,0,0,.25);
          display:flex;align-items:center;justify-content:center;
          color:#fff;font-weight:700;font-size:11px;cursor:pointer;
        ">${label}</div>`,
        iconSize: [34, 34],
        iconAnchor: [17, 17],
      });

      const marker = L.marker(latlng, { icon: customIcon }).addTo(map);
      marker.on('click', () => {
        setActiveWorkerPopup(w);
        onSelectWorker?.(w);
      });
      markersRef.current.push(marker);
    });

    if (bounds.length === 1) {
      map.setView(bounds[0], 14);
    } else if (bounds.length > 1) {
      map.fitBounds(bounds, { padding: [40, 40], maxZoom: 14 });
    }

    map.invalidateSize();

    return () => {
      // keep map instance across filter changes; destroy only on unmount
    };
  }, [withGps, onSelectWorker]);

  useEffect(() => {
    return () => {
      if (mapInstanceRef.current) {
        mapInstanceRef.current.remove();
        mapInstanceRef.current = null;
      }
    };
  }, []);

  return (
    <div
      style={{
        position: 'relative',
        width: '100%',
        height,
        borderRadius: '16px',
        overflow: 'hidden',
        border: '1px solid var(--border-light)',
        background: '#e5f3ea',
      }}
    >
      <div ref={mapContainerRef} style={{ width: '100%', height: '100%' }} />

      <div
        style={{
          position: 'absolute',
          top: 12,
          left: 14,
          backgroundColor: 'rgba(255,255,255,0.95)',
          padding: '6px 14px',
          borderRadius: 8,
          fontSize: 12,
          fontWeight: 700,
          color: '#15803d',
          boxShadow: '0 2px 10px rgba(0,0,0,0.08)',
          zIndex: 400,
          display: 'flex',
          alignItems: 'center',
          gap: 6,
        }}
      >
        <Radio size={13} />
        <span>
          Live GPS · {withGps.length}/{filteredWorkers.length} workers
        </span>
      </div>

      {withGps.length === 0 && (
        <div
          style={{
            position: 'absolute',
            inset: 0,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            pointerEvents: 'none',
            zIndex: 350,
            background: 'rgba(255,255,255,0.35)',
          }}
        >
          <div
            style={{
              background: '#fff',
              padding: '14px 18px',
              borderRadius: 12,
              fontSize: 13,
              color: '#64748b',
              boxShadow: '0 8px 24px rgba(0,0,0,0.08)',
              display: 'flex',
              alignItems: 'center',
              gap: 8,
            }}
          >
            <MapPin size={16} color="#15803d" />
            No live coordinates yet. Workers appear when the app sends GPS.
          </div>
        </div>
      )}

      {activeWorkerPopup && (
        <div
          style={{
            position: 'absolute',
            bottom: 16,
            right: 16,
            backgroundColor: '#fff',
            borderRadius: 14,
            padding: '14px 18px',
            boxShadow: '0 15px 35px rgba(0,0,0,0.2)',
            zIndex: 500,
            width: 290,
            border: '1.5px solid #bbf7d0',
          }}
        >
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
              <Avatar src={activeWorkerPopup.avatar} name={activeWorkerPopup.name} size={36} />
              <div>
                <div style={{ fontSize: 13.5, fontWeight: 700 }}>{activeWorkerPopup.name}</div>
                <div style={{ fontSize: 11.5, color: '#64748b' }}>
                  {activeWorkerPopup.service || activeWorkerPopup.category || '—'}
                  {activeWorkerPopup.rating != null ? ` · ⭐ ${activeWorkerPopup.rating}` : ''}
                </div>
              </div>
            </div>
            <button
              type="button"
              onClick={() => setActiveWorkerPopup(null)}
              style={{ border: 'none', background: 'transparent', cursor: 'pointer', color: '#94a3b8' }}
            >
              <X size={16} />
            </button>
          </div>
          <div style={{ fontSize: 12, color: '#475569', marginTop: 10 }}>
            📍 {activeWorkerPopup.location || activeWorkerPopup.city || 'Live pin'}
          </div>
          <div style={{ display: 'flex', gap: 6, marginTop: 10 }}>
            <button
              type="button"
              onClick={() => navigate(`/workers/${activeWorkerPopup.id}`)}
              style={{
                flex: 1,
                padding: '6px 10px',
                borderRadius: 6,
                backgroundColor: 'var(--primary-brand)',
                color: '#fff',
                fontSize: 11.5,
                fontWeight: 600,
                border: 'none',
                cursor: 'pointer',
              }}
            >
              View Profile
            </button>
            {activeWorkerPopup.phone && activeWorkerPopup.phone !== '—' && (
              <a
                href={`tel:${activeWorkerPopup.phone}`}
                style={{
                  padding: '6px 10px',
                  borderRadius: 6,
                  backgroundColor: '#eaf7ee',
                  color: '#15803d',
                  display: 'inline-flex',
                  alignItems: 'center',
                }}
              >
                <Phone size={13} />
              </a>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
