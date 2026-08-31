import React, { useState } from 'react';
import { liveWorkers } from '../data/mockData';
import {
  X,
  MapPin,
  Battery,
  Phone,
  Star,
  Search,
  Layers,
  Radio,
  Navigation,
  ShieldCheck,
  CheckCircle
} from 'lucide-react';

export default function LiveMapModal({ isOpen, onClose, onSelectBooking }) {
  const [selectedWorker, setSelectedWorker] = useState(liveWorkers[0]);
  const [filterTrade, setFilterTrade] = useState('All');
  const [searchQuery, setSearchQuery] = useState('');

  if (!isOpen) return null;

  const trades = ['All', 'Plumbing', 'Electrical', 'Carpentry', 'Cleaning', 'Appliance Repair'];

  const filteredWorkers = liveWorkers.filter((w) => {
    const matchesTrade = filterTrade === 'All' || w.service === filterTrade;
    const matchesSearch =
      w.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      w.service.toLowerCase().includes(searchQuery.toLowerCase());
    return matchesTrade && matchesSearch;
  });

  return (
    <div
      style={{
        position: 'fixed',
        inset: 0,
        backgroundColor: 'rgba(15, 23, 42, 0.65)',
        backdropFilter: 'blur(4px)',
        zIndex: 60,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        padding: '20px',
        animation: 'fadeIn 0.2s ease',
      }}
    >
      <div
        style={{
          backgroundColor: '#ffffff',
          borderRadius: '20px',
          width: '100%',
          maxWidth: '1020px',
          height: '82vh',
          maxHeight: '750px',
          boxShadow: '0 25px 50px -12px rgba(0, 0, 0, 0.25)',
          display: 'flex',
          flexDirection: 'column',
          overflow: 'hidden',
        }}
      >
        {/* Header */}
        <div
          style={{
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
            padding: '18px 24px',
            borderBottom: '1px solid var(--border-light)',
            backgroundColor: '#ffffff',
          }}
        >
          <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
            <div
              style={{
                width: '36px',
                height: '36px',
                borderRadius: '10px',
                backgroundColor: '#eaf7ee',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                color: '#15803d',
              }}
            >
              <Navigation size={18} />
            </div>
            <div>
              <h3 style={{ fontSize: '17px', fontWeight: '700', color: '#111827' }}>
                Live Field Workers Radar
              </h3>
              <p style={{ fontSize: '12px', color: '#64748b' }}>
                Real-time GPS telemetry & gig dispatch status
              </p>
            </div>
          </div>

          <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
            <div
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: '6px',
                padding: '4px 10px',
                backgroundColor: '#eaf7ee',
                borderRadius: '999px',
                fontSize: '12px',
                color: '#15803d',
                fontWeight: '600',
              }}
            >
              <Radio size={12} className="pulse-marker" />
              <span>Telemetry Live</span>
            </div>
            <button
              onClick={onClose}
              style={{
                padding: '8px',
                borderRadius: '50%',
                color: '#64748b',
                backgroundColor: '#f1f5f9',
              }}
            >
              <X size={18} />
            </button>
          </div>
        </div>

        {/* Content Layout: Left Map canvas, Right Worker list / Details */}
        <div style={{ display: 'flex', flex: 1, overflow: 'hidden' }}>
          {/* Simulated Interactive Map Area */}
          <div
            style={{
              flex: 1,
              backgroundColor: '#e9f2ec',
              position: 'relative',
              overflow: 'hidden',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
            }}
          >
            {/* Map Vector Grid & Roads */}
            <svg
              style={{
                position: 'absolute',
                inset: 0,
                width: '100%',
                height: '100%',
              }}
            >
              <defs>
                <pattern
                  id="mapGrid"
                  width="50"
                  height="50"
                  patternUnits="userSpaceOnUse"
                >
                  <path
                    d="M 50 0 L 0 0 0 50"
                    fill="none"
                    stroke="#d2e6d8"
                    strokeWidth="1.2"
                  />
                </pattern>
              </defs>
              <rect width="100%" height="100%" fill="url(#mapGrid)" />
              {/* Main Arterial Roads */}
              <path
                d="M -50 150 C 150 120, 300 350, 800 200"
                stroke="#ffffff"
                strokeWidth="14"
                fill="none"
              />
              <path
                d="M 200 -50 C 250 200, 450 400, 500 700"
                stroke="#ffffff"
                strokeWidth="12"
                fill="none"
              />
              <path
                d="M 50 450 C 350 420, 550 200, 750 350"
                stroke="#ffffff"
                strokeWidth="10"
                fill="none"
              />
              {/* Sector Zones */}
              <circle cx="280" cy="220" r="140" fill="#22864c" opacity="0.04" />
              <circle cx="520" cy="360" r="120" fill="#22864c" opacity="0.04" />
            </svg>

            {/* Zone Tag */}
            <div
              style={{
                position: 'absolute',
                top: '16px',
                left: '16px',
                backgroundColor: 'rgba(255, 255, 255, 0.92)',
                padding: '6px 12px',
                borderRadius: '8px',
                fontSize: '12px',
                fontWeight: '600',
                color: '#1e3a29',
                boxShadow: '0 2px 8px rgba(0,0,0,0.06)',
                backdropFilter: 'blur(4px)',
              }}
            >
              📍 Delhi NCR Cluster • 5 Active Sectors
            </div>

            {/* Worker Pin 1 */}
            <div
              onClick={() => setSelectedWorker(liveWorkers[0])}
              style={{
                position: 'absolute',
                top: '32%',
                left: '38%',
                cursor: 'pointer',
                transform: 'translate(-50%, -100%)',
                zIndex: selectedWorker?.id === 'W-101' ? 30 : 10,
              }}
            >
              <div
                style={{
                  display: 'flex',
                  flexDirection: 'column',
                  alignItems: 'center',
                }}
              >
                <div
                  style={{
                    backgroundColor: '#15803d',
                    color: '#ffffff',
                    padding: '3px 8px',
                    borderRadius: '6px',
                    fontSize: '11px',
                    fontWeight: '700',
                    boxShadow: '0 4px 10px rgba(0,0,0,0.15)',
                    whiteSpace: 'nowrap',
                    marginBottom: '4px',
                  }}
                >
                  Mahesh Y. (Plumbing)
                </div>
                <div
                  style={{
                    width: '32px',
                    height: '32px',
                    borderRadius: '50%',
                    backgroundColor: '#15803d',
                    border: '3px solid #ffffff',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    boxShadow: '0 4px 12px rgba(21, 128, 61, 0.4)',
                  }}
                >
                  <MapPin size={16} color="#ffffff" />
                </div>
              </div>
            </div>

            {/* Worker Pin 2 */}
            <div
              onClick={() => setSelectedWorker(liveWorkers[1])}
              style={{
                position: 'absolute',
                top: '55%',
                left: '60%',
                cursor: 'pointer',
                transform: 'translate(-50%, -100%)',
                zIndex: selectedWorker?.id === 'W-102' ? 30 : 10,
              }}
            >
              <div
                style={{
                  display: 'flex',
                  flexDirection: 'column',
                  alignItems: 'center',
                }}
              >
                <div
                  style={{
                    backgroundColor: '#ca8a04',
                    color: '#ffffff',
                    padding: '3px 8px',
                    borderRadius: '6px',
                    fontSize: '11px',
                    fontWeight: '700',
                    boxShadow: '0 4px 10px rgba(0,0,0,0.15)',
                    whiteSpace: 'nowrap',
                    marginBottom: '4px',
                  }}
                >
                  Arun K. (Electrical)
                </div>
                <div
                  style={{
                    width: '32px',
                    height: '32px',
                    borderRadius: '50%',
                    backgroundColor: '#ca8a04',
                    border: '3px solid #ffffff',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    boxShadow: '0 4px 12px rgba(202, 138, 4, 0.4)',
                  }}
                >
                  <MapPin size={16} color="#ffffff" />
                </div>
              </div>
            </div>

            {/* Worker Pin 3 */}
            <div
              onClick={() => setSelectedWorker(liveWorkers[2])}
              style={{
                position: 'absolute',
                top: '25%',
                left: '68%',
                cursor: 'pointer',
                transform: 'translate(-50%, -100%)',
                zIndex: selectedWorker?.id === 'W-103' ? 30 : 10,
              }}
            >
              <div
                style={{
                  display: 'flex',
                  flexDirection: 'column',
                  alignItems: 'center',
                }}
              >
                <div
                  style={{
                    backgroundColor: '#15803d',
                    color: '#ffffff',
                    padding: '3px 8px',
                    borderRadius: '6px',
                    fontSize: '11px',
                    fontWeight: '700',
                    boxShadow: '0 4px 10px rgba(0,0,0,0.15)',
                    whiteSpace: 'nowrap',
                    marginBottom: '4px',
                  }}
                >
                  Suresh D. (Carpentry)
                </div>
                <div
                  style={{
                    width: '32px',
                    height: '32px',
                    borderRadius: '50%',
                    backgroundColor: '#15803d',
                    border: '3px solid #ffffff',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    boxShadow: '0 4px 12px rgba(21, 128, 61, 0.4)',
                  }}
                >
                  <MapPin size={16} color="#ffffff" />
                </div>
              </div>
            </div>

            {/* Worker Pin 4 */}
            <div
              onClick={() => setSelectedWorker(liveWorkers[3])}
              style={{
                position: 'absolute',
                top: '68%',
                left: '28%',
                cursor: 'pointer',
                transform: 'translate(-50%, -100%)',
                zIndex: selectedWorker?.id === 'W-104' ? 30 : 10,
              }}
            >
              <div
                style={{
                  display: 'flex',
                  flexDirection: 'column',
                  alignItems: 'center',
                }}
              >
                <div
                  style={{
                    backgroundColor: '#15803d',
                    color: '#ffffff',
                    padding: '3px 8px',
                    borderRadius: '6px',
                    fontSize: '11px',
                    fontWeight: '700',
                    boxShadow: '0 4px 10px rgba(0,0,0,0.15)',
                    whiteSpace: 'nowrap',
                    marginBottom: '4px',
                  }}
                >
                  Sunita D. (Cleaning)
                </div>
                <div
                  style={{
                    width: '32px',
                    height: '32px',
                    borderRadius: '50%',
                    backgroundColor: '#15803d',
                    border: '3px solid #ffffff',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    boxShadow: '0 4px 12px rgba(21, 128, 61, 0.4)',
                  }}
                >
                  <MapPin size={16} color="#ffffff" />
                </div>
              </div>
            </div>
          </div>

          {/* Right Sidebar: Worker Details & Roster */}
          <div
            style={{
              width: '360px',
              backgroundColor: '#ffffff',
              borderLeft: '1px solid var(--border-light)',
              display: 'flex',
              flexDirection: 'column',
              padding: '16px',
              gap: '12px',
              overflowY: 'auto',
            }}
          >
            {/* Search */}
            <div
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: '8px',
                padding: '8px 12px',
                backgroundColor: '#f8fafc',
                borderRadius: '8px',
                border: '1px solid #e2e8f0',
              }}
            >
              <Search size={15} color="#94a3b8" />
              <input
                type="text"
                placeholder="Search worker or trade..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                style={{
                  border: 'none',
                  outline: 'none',
                  backgroundColor: 'transparent',
                  width: '100%',
                  fontSize: '13px',
                }}
              />
            </div>

            {/* Selected Worker Info Card */}
            {selectedWorker && (
              <div
                style={{
                  backgroundColor: '#f6fbf8',
                  borderRadius: '12px',
                  border: '1.5px solid #bbf7d0',
                  padding: '14px',
                  animation: 'fadeIn 0.2s ease',
                }}
              >
                <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                  <img
                    src={selectedWorker.avatar}
                    alt={selectedWorker.name}
                    style={{
                      width: '44px',
                      height: '44px',
                      borderRadius: '50%',
                      objectFit: 'cover',
                      border: '2px solid #22c55e',
                    }}
                  />
                  <div>
                    <div style={{ fontWeight: '700', fontSize: '14px', color: '#142a1d' }}>
                      {selectedWorker.name}
                    </div>
                    <div style={{ fontSize: '12px', color: '#52665b', fontWeight: '500' }}>
                      {selectedWorker.service} • ⭐ {selectedWorker.rating}
                    </div>
                  </div>
                </div>

                <div
                  style={{
                    display: 'grid',
                    gridTemplateColumns: '1fr 1fr',
                    gap: '8px',
                    marginTop: '12px',
                    fontSize: '11.5px',
                  }}
                >
                  <div
                    style={{
                      backgroundColor: '#ffffff',
                      padding: '6px 8px',
                      borderRadius: '6px',
                      border: '1px solid #e6ede8',
                    }}
                  >
                    <span style={{ color: '#64748b' }}>Status: </span>
                    <strong style={{ color: '#15803d' }}>{selectedWorker.status}</strong>
                  </div>
                  <div
                    style={{
                      backgroundColor: '#ffffff',
                      padding: '6px 8px',
                      borderRadius: '6px',
                      border: '1px solid #e6ede8',
                    }}
                  >
                    <span style={{ color: '#64748b' }}>Battery: </span>
                    <strong style={{ color: '#1e293b' }}>{selectedWorker.battery}</strong>
                  </div>
                </div>

                {selectedWorker.currentJob && (
                  <div
                    style={{
                      marginTop: '10px',
                      padding: '8px',
                      backgroundColor: '#ffffff',
                      borderRadius: '6px',
                      border: '1px solid #e6ede8',
                      fontSize: '12px',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'space-between',
                    }}
                  >
                    <span>Current Job: <strong>{selectedWorker.currentJob}</strong></span>
                    <button
                      onClick={() => onSelectBooking && onSelectBooking({ id: selectedWorker.currentJob })}
                      style={{
                        fontSize: '11px',
                        color: 'var(--text-link)',
                        fontWeight: '600',
                      }}
                    >
                      View Order
                    </button>
                  </div>
                )}

                <div style={{ display: 'flex', gap: '8px', marginTop: '12px' }}>
                  <button
                    style={{
                      flex: 1,
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      gap: '6px',
                      padding: '8px',
                      borderRadius: '8px',
                      backgroundColor: 'var(--primary-brand)',
                      color: '#ffffff',
                      fontSize: '12px',
                      fontWeight: '600',
                    }}
                  >
                    <Phone size={13} />
                    <span>Call Worker</span>
                  </button>
                  <button
                    style={{
                      padding: '8px 12px',
                      borderRadius: '8px',
                      backgroundColor: '#eaf7ee',
                      color: '#15803d',
                      fontSize: '12px',
                      fontWeight: '600',
                    }}
                  >
                    Dispatch Next
                  </button>
                </div>
              </div>
            )}

            {/* List of active workers */}
            <div style={{ fontSize: '12px', fontWeight: '700', color: '#64748b', marginTop: '4px' }}>
              All Active Field Force ({filteredWorkers.length})
            </div>

            <div style={{ display: 'flex', flexDirection: 'column', gap: '6px', flex: 1, overflowY: 'auto' }}>
              {filteredWorkers.map((w) => (
                <div
                  key={w.id}
                  onClick={() => setSelectedWorker(w)}
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'space-between',
                    padding: '8px 10px',
                    borderRadius: '8px',
                    backgroundColor: selectedWorker?.id === w.id ? '#f1f8f3' : '#f8fafc',
                    border: `1px solid ${selectedWorker?.id === w.id ? '#86efac' : '#f1f5f9'}`,
                    cursor: 'pointer',
                    transition: 'all 0.15s ease',
                  }}
                >
                  <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                    <img
                      src={w.avatar}
                      alt={w.name}
                      style={{ width: '28px', height: '28px', borderRadius: '50%', objectFit: 'cover' }}
                    />
                    <div>
                      <div style={{ fontSize: '12.5px', fontWeight: '600', color: '#1e293b' }}>
                        {w.name}
                      </div>
                      <div style={{ fontSize: '11px', color: '#64748b' }}>{w.service}</div>
                    </div>
                  </div>
                  <span
                    style={{
                      fontSize: '11px',
                      fontWeight: '600',
                      padding: '2px 6px',
                      borderRadius: '4px',
                      backgroundColor: w.status === 'Available' ? '#eaf8ef' : '#fef3c7',
                      color: w.status === 'Available' ? '#15803d' : '#b45309',
                    }}
                  >
                    {w.status}
                  </span>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
