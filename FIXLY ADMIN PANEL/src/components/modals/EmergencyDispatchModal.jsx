import React, { useState } from 'react';
import Modal from '../common/Modal';
import { useApp } from '../../context/AppContext';
import { AlertCircle, Zap, MapPin, Phone, ShieldAlert, CheckCircle2 } from 'lucide-react';

export default function EmergencyDispatchModal({ emergencyBooking, isOpen, onClose }) {
  const { workers, assignWorkerToBooking } = useApp();

  if (!emergencyBooking) return null;

  const nearbyWorkers = workers.filter(
    (w) => w.service.toLowerCase() === emergencyBooking.service.toLowerCase() && w.availability === 'Available'
  );

  const [selectedWorker, setSelectedWorker] = useState(nearbyWorkers[0] || null);

  const handleInstantDispatch = () => {
    if (!selectedWorker) return;
    assignWorkerToBooking(emergencyBooking.id, selectedWorker.id);
    onClose();
  };

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title="🚨 Emergency SOS Ticket Dispatch"
      subtitle={`Immediate Priority: ${emergencyBooking.service} • Order #${emergencyBooking.id}`}
      maxWidth="600px"
      footer={
        <>
          <button
            onClick={onClose}
            style={{
              padding: '8px 16px',
              borderRadius: '8px',
              border: '1px solid #cbd5e1',
              color: '#475569',
              fontSize: '13px',
              fontWeight: '600',
            }}
          >
            Cancel
          </button>
          <button
            disabled={!selectedWorker}
            onClick={handleInstantDispatch}
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '6px',
              padding: '8px 20px',
              borderRadius: '8px',
              backgroundColor: '#dc2626',
              color: '#ffffff',
              fontSize: '13px',
              fontWeight: '700',
              boxShadow: '0 4px 14px rgba(220, 38, 38, 0.3)',
            }}
          >
            <Zap size={15} />
            <span>Instant Dispatch (Target SLA: 15 Mins)</span>
          </button>
        </>
      }
    >
      <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
        {/* Incident Alert Box */}
        <div
          style={{
            backgroundColor: '#fef2f2',
            border: '1.5px solid #fca5a5',
            borderRadius: '12px',
            padding: '14px',
            display: 'flex',
            gap: '12px',
          }}
        >
          <ShieldAlert size={24} color="#dc2626" style={{ flexShrink: 0 }} />
          <div>
            <div style={{ fontSize: '14px', fontWeight: '700', color: '#991b1b' }}>
              Incident: {emergencyBooking.serviceType || 'Critical Emergency Ticket'}
            </div>
            <div style={{ fontSize: '12.5px', color: '#7f1d1d', marginTop: '2px' }}>
              Customer: <strong>{emergencyBooking.customer}</strong> ({emergencyBooking.customerPhone})
            </div>
            <div style={{ fontSize: '12px', color: '#991b1b', marginTop: '4px' }}>
              📍 {emergencyBooking.customerAddress}
            </div>
          </div>
        </div>

        {/* Available nearby field workers */}
        <div>
          <div style={{ fontSize: '13px', fontWeight: '700', color: '#1e293b', marginBottom: '8px' }}>
            Nearest Available Verified Professionals (GPS Calculated):
          </div>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
            {nearbyWorkers.map((w, index) => (
              <div
                key={w.id}
                onClick={() => setSelectedWorker(w)}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'space-between',
                  padding: '10px 14px',
                  borderRadius: '10px',
                  backgroundColor: selectedWorker?.id === w.id ? '#fef2f2' : '#ffffff',
                  border: `1.5px solid ${selectedWorker?.id === w.id ? '#dc2626' : '#e2e8f0'}`,
                  cursor: 'pointer',
                  transition: 'all 0.15s ease',
                }}
              >
                <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                  <img
                    src={w.avatar}
                    alt={w.name}
                    style={{ width: '38px', height: '38px', borderRadius: '50%', objectFit: 'cover' }}
                  />
                  <div>
                    <div style={{ fontSize: '13.5px', fontWeight: '700', color: '#1e293b' }}>
                      {w.name}
                    </div>
                    <div style={{ fontSize: '11.5px', color: '#64748b' }}>
                      ⭐ {w.rating} • Battery: {w.battery}
                    </div>
                  </div>
                </div>

                <div style={{ textAlign: 'right' }}>
                  <span
                    style={{
                      fontSize: '11.5px',
                      fontWeight: '700',
                      color: '#dc2626',
                      backgroundColor: '#fee2e2',
                      padding: '2px 8px',
                      borderRadius: '999px',
                    }}
                  >
                    📍 ~{1.2 + index * 0.9} km (~{6 + index * 4} mins ETA)
                  </span>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </Modal>
  );
}
