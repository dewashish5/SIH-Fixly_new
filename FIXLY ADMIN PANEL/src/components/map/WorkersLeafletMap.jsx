import React, { useEffect, useRef, useState } from 'react';
import { useApp } from '../../context/AppContext';
import { useNavigate } from 'react-router-dom';
import { MapPin, Navigation, Radio, Phone, Star, User } from 'lucide-react';

export default function WorkersLeafletMap({
  height = '420px',
  selectedService = 'All',
  onSelectWorker,
}) {
  const mapContainerRef = useRef(null);
  const mapInstanceRef = useRef(null);
  const markersRef = useRef([]);
  const navigate = useNavigate();

  const { workers } = useApp();
  const [activeWorkerPopup, setActiveWorkerPopup] = useState(null);

  const filteredWorkers = workers.filter((w) => {
    return selectedService === 'All' || w.service.toLowerCase() === selectedService.toLowerCase();
  });

  useEffect(() => {
    if (!mapContainerRef.current) return;

    // Check if Leaflet is available in window or via import
    const L = window.L;

    if (L && !mapInstanceRef.current) {
      // Initialize map centered at Delhi NCR
      const map = L.map(mapContainerRef.current, {
        center: [28.5900, 77.2800],
        zoom: 11,
        zoomControl: true,
      });

      L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        attribution: '&copy; OpenStreetMap contributors',
        maxZoom: 18,
      }).addTo(map);

      mapInstanceRef.current = map;
    }

    // Update markers
    if (L && mapInstanceRef.current) {
      // Clear existing markers
      markersRef.current.forEach((m) => m.remove());
      markersRef.current = [];

      filteredWorkers.forEach((w) => {
        if (!w.coordinates) return;

        const isAvailable = w.availability === 'Available';
        const pinColor = isAvailable ? '#16a34a' : '#d97706';

        const customIcon = L.divIcon({
          className: 'custom-leaflet-marker',
          html: `
            <div style="
              width: 34px;
              height: 34px;
              border-radius: 50%;
              background-color: ${pinColor};
              border: 3px solid #ffffff;
              box-shadow: 0 4px 12px rgba(0,0,0,0.25);
              display: flex;
              align-items: center;
              justify-content: center;
              color: #ffffff;
              font-weight: 700;
              font-size: 11px;
              cursor: pointer;
            ">
              ${w.service.slice(0, 2).toUpperCase()}
            </div>
          `,
          iconSize: [34, 34],
          iconAnchor: [17, 17],
        });

        const marker = L.marker(w.coordinates, { icon: customIcon }).addTo(mapInstanceRef.current);

        marker.on('click', () => {
          setActiveWorkerPopup(w);
          if (onSelectWorker) onSelectWorker(w);
        });

        markersRef.current.push(marker);
      });
    }

    return () => {
      // cleanup on unmount
    };
  }, [filteredWorkers, onSelectWorker]);

  return (
    <div style={{ position: 'relative', width: '100%', height, borderRadius: '16px', overflow: 'hidden', border: '1px solid var(--border-light)' }}>
      {/* Map DOM Element */}
      <div ref={mapContainerRef} style={{ width: '100%', height: '100%', backgroundColor: '#e5f3ea' }} />

      {/* Fallback Vector Graphic if Leaflet tiles are loading */}
      <div
        style={{
          position: 'absolute',
          top: '12px',
          left: '14px',
          backgroundColor: 'rgba(255, 255, 255, 0.95)',
          padding: '6px 14px',
          borderRadius: '8px',
          fontSize: '12px',
          fontWeight: '700',
          color: '#15803d',
          boxShadow: '0 2px 10px rgba(0,0,0,0.08)',
          zIndex: 400,
          display: 'flex',
          alignItems: 'center',
          gap: '6px',
        }}
      >
        <Radio size={13} className="pulse-marker" />
        <span>Live Telemetry • {filteredWorkers.length} Active Field Workers Connected</span>
      </div>

      {/* Worker Floating Details Popup */}
      {activeWorkerPopup && (
        <div
          style={{
            position: 'absolute',
            bottom: '16px',
            right: '16px',
            backgroundColor: '#ffffff',
            borderRadius: '14px',
            padding: '14px 18px',
            boxShadow: '0 15px 35px rgba(0,0,0,0.2)',
            zIndex: 500,
            width: '290px',
            animation: 'fadeIn 0.2s ease',
            border: '1.5px solid #bbf7d0',
          }}
        >
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
              <img
                src={activeWorkerPopup.avatar}
                alt={activeWorkerPopup.name}
                style={{ width: '36px', height: '36px', borderRadius: '50%', objectFit: 'cover' }}
              />
              <div>
                <div style={{ fontSize: '13.5px', fontWeight: '700', color: '#111827' }}>
                  {activeWorkerPopup.name}
                </div>
                <div style={{ fontSize: '11.5px', color: '#64748b' }}>
                  {activeWorkerPopup.service} • ⭐ {activeWorkerPopup.rating}
                </div>
              </div>
            </div>
            <button
              onClick={() => setActiveWorkerPopup(null)}
              style={{ fontSize: '14px', color: '#94a3b8', padding: '2px' }}
            >
              ✕
            </button>
          </div>

          <div style={{ fontSize: '12px', color: '#475569', marginTop: '10px' }}>
            📍 Location: <strong>{activeWorkerPopup.location}</strong>
          </div>

          <div style={{ display: 'flex', gap: '6px', marginTop: '10px' }}>
            <button
              onClick={() => navigate(`/workers/${activeWorkerPopup.id}`)}
              style={{
                flex: 1,
                padding: '6px 10px',
                borderRadius: '6px',
                backgroundColor: 'var(--primary-brand)',
                color: '#ffffff',
                fontSize: '11.5px',
                fontWeight: '600',
              }}
            >
              View Profile
            </button>
            <button
              onClick={() => alert(`Calling ${activeWorkerPopup.name} at ${activeWorkerPopup.phone}`)}
              style={{
                padding: '6px 10px',
                borderRadius: '6px',
                backgroundColor: '#eaf7ee',
                color: '#15803d',
                fontSize: '11.5px',
                fontWeight: '600',
              }}
            >
              <Phone size={13} />
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
