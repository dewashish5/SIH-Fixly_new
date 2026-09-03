import React, { useEffect, useMemo, useState } from 'react';
import { useApp } from '../context/AppContext';
import { MapPin, Radio, Search, X } from 'lucide-react';
import Avatar from './common/Avatar';
import WorkersLeafletMap, { workerLatLng } from './map/WorkersLeafletMap';

/**
 * Shared live-workers map (Dashboard "View Map" + Workers "Map" button).
 */
export default function LiveMapModal({ isOpen, onClose }) {
  const { workers, fetchWorkers } = useApp();
  const [filterTrade, setFilterTrade] = useState('All');
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedWorker, setSelectedWorker] = useState(null);

  useEffect(() => {
    if (!isOpen) return;
    fetchWorkers({ page: 1, limit: 100, isVerified: 'true' });
  }, [isOpen, fetchWorkers]);

  useEffect(() => {
    if (!isOpen) return undefined;
    const onKey = (e) => {
      if (e.key === 'Escape') onClose?.();
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [isOpen, onClose]);

  const trades = useMemo(() => {
    const set = new Set(
      workers.map((w) => w.category || w.service).filter((t) => t && t !== '—')
    );
    return ['All', ...Array.from(set)];
  }, [workers]);

  const filteredWorkers = useMemo(() => {
    const q = searchQuery.toLowerCase().trim();
    return workers.filter((w) => {
      const trade = w.category || w.service || '';
      const matchesTrade = filterTrade === 'All' || trade === filterTrade;
      const matchesSearch =
        !q ||
        (w.name || '').toLowerCase().includes(q) ||
        trade.toLowerCase().includes(q);
      return matchesTrade && matchesSearch;
    });
  }, [workers, filterTrade, searchQuery]);

  const gpsCount = filteredWorkers.filter((w) => workerLatLng(w)).length;

  if (!isOpen) return null;

  return (
    <div
      style={{
        position: 'fixed',
        inset: 0,
        backgroundColor: 'rgba(15, 23, 42, 0.65)',
        backdropFilter: 'blur(4px)',
        zIndex: 70,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        padding: 20,
      }}
      onClick={onClose}
    >
      <div
        style={{
          backgroundColor: '#fff',
          borderRadius: 20,
          width: '100%',
          maxWidth: 1100,
          height: '88vh',
          maxHeight: 820,
          boxShadow: '0 25px 50px -12px rgba(0,0,0,0.25)',
          display: 'flex',
          flexDirection: 'column',
          overflow: 'hidden',
        }}
        onClick={(e) => e.stopPropagation()}
      >
        <div
          style={{
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
            padding: '16px 20px',
            borderBottom: '1px solid var(--border-light)',
          }}
        >
          <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
            <Radio size={18} color="#15803d" />
            <div>
              <div style={{ fontWeight: 700, fontSize: 15 }}>Workers live map</div>
              <div style={{ fontSize: 12, color: '#64748b' }}>
                Verified members · {gpsCount} with live GPS · {filteredWorkers.length} total
              </div>
            </div>
          </div>
          <button
            type="button"
            onClick={onClose}
            style={{
              padding: 8,
              borderRadius: 8,
              border: 'none',
              background: '#f1f5f9',
              cursor: 'pointer',
            }}
          >
            <X size={18} />
          </button>
        </div>

        <div
          style={{
            display: 'flex',
            gap: 8,
            padding: '10px 20px',
            borderBottom: '1px solid #f1f5f9',
            flexWrap: 'wrap',
          }}
        >
          <div
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: 8,
              background: '#f8fafc',
              border: '1px solid #e2e8f0',
              borderRadius: 8,
              padding: '6px 10px',
              flex: 1,
              minWidth: 180,
            }}
          >
            <Search size={14} color="#94a3b8" />
            <input
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="Search worker…"
              style={{
                border: 'none',
                outline: 'none',
                background: 'transparent',
                width: '100%',
                fontSize: 13,
              }}
            />
          </div>
          <select
            value={filterTrade}
            onChange={(e) => setFilterTrade(e.target.value)}
            style={{
              padding: '6px 10px',
              borderRadius: 8,
              border: '1px solid #cbd5e1',
              fontSize: 12.5,
              fontWeight: 600,
            }}
          >
            {trades.map((t) => (
              <option key={t} value={t}>
                {t}
              </option>
            ))}
          </select>
        </div>

        <div
          style={{
            display: 'grid',
            gridTemplateColumns: '280px 1fr',
            flex: 1,
            minHeight: 0,
          }}
        >
          <div style={{ overflowY: 'auto', borderRight: '1px solid #f1f5f9' }}>
            {filteredWorkers.length === 0 ? (
              <div style={{ padding: 28, textAlign: 'center', color: '#64748b', fontSize: 13 }}>
                No verified workers yet.
              </div>
            ) : (
              filteredWorkers.map((w) => {
                const hasGps = !!workerLatLng(w);
                return (
                  <button
                    key={w.id}
                    type="button"
                    onClick={() => setSelectedWorker(w)}
                    style={{
                      width: '100%',
                      textAlign: 'left',
                      display: 'flex',
                      gap: 10,
                      padding: '12px 14px',
                      border: 'none',
                      borderBottom: '1px solid #f8fafc',
                      background: selectedWorker?.id === w.id ? '#f0fdf4' : '#fff',
                      cursor: 'pointer',
                    }}
                  >
                    <Avatar name={w.name} src={w.avatar} size={36} />
                    <div style={{ flex: 1, minWidth: 0 }}>
                      <div style={{ fontWeight: 700, fontSize: 13 }}>{w.name}</div>
                      <div style={{ fontSize: 12, color: '#64748b' }}>
                        {w.category || w.service || '—'}
                      </div>
                      <div
                        style={{
                          fontSize: 11,
                          color: hasGps ? '#15803d' : '#94a3b8',
                          marginTop: 2,
                          display: 'flex',
                          alignItems: 'center',
                          gap: 4,
                        }}
                      >
                        <MapPin size={11} />
                        {hasGps ? 'Live GPS' : 'No GPS yet'}
                      </div>
                    </div>
                  </button>
                );
              })
            )}
          </div>

          <div style={{ padding: 12, minHeight: 0 }}>
            <WorkersLeafletMap
              key={isOpen ? 'open' : 'closed'}
              workers={filteredWorkers}
              height="100%"
              selectedService="All"
              onSelectWorker={setSelectedWorker}
            />
          </div>
        </div>
      </div>
    </div>
  );
}
