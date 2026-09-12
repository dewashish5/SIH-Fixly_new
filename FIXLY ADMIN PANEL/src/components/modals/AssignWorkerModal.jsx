import React, { useState } from 'react';
import Modal from '../common/Modal';
import Avatar from '../common/Avatar';
import { useApp } from '../../context/AppContext';
import { MapPin, Star, UserCheck, Phone } from 'lucide-react';

export default function AssignWorkerModal({ booking, isOpen, onClose }) {
  const { workers, assignWorkerToBooking } = useApp();
  const [selectedWorkerId, setSelectedWorkerId] = useState('');

  if (!booking) return null;

  // Available verified workers
  const matchingWorkers = workers.filter(
    (w) => w.isVerified || w.verification === 'Verified'
  );

  const handleAssign = () => {
    if (!selectedWorkerId) return;
    assignWorkerToBooking(booking.id, selectedWorkerId);
    onClose();
  };

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title={`Assign Worker to Booking ${booking.id}`}
      subtitle={`Service: ${booking.service} • Location: ${booking.customerAddress}`}
      maxWidth="560px"
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
            disabled={!selectedWorkerId}
            onClick={handleAssign}
            style={{
              padding: '8px 20px',
              borderRadius: '8px',
              backgroundColor: selectedWorkerId ? 'var(--primary-brand)' : '#94a3b8',
              color: '#ffffff',
              fontSize: '13px',
              fontWeight: '600',
              cursor: selectedWorkerId ? 'pointer' : 'not-allowed',
            }}
          >
            Confirm Assignment & Dispatch
          </button>
        </>
      }
    >
      <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
        <div style={{ fontSize: '12.5px', fontWeight: '700', color: '#64748b' }}>
          Available Verified {booking.service} Professionals ({matchingWorkers.length}):
        </div>

        {matchingWorkers.map((w) => (
          <div
            key={w.id}
            onClick={() => setSelectedWorkerId(w.id)}
            style={{
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'space-between',
              padding: '12px 14px',
              borderRadius: '12px',
              backgroundColor: selectedWorkerId === w.id ? '#f1f8f3' : '#ffffff',
              border: `1.5px solid ${selectedWorkerId === w.id ? '#22864c' : '#e2e8f0'}`,
              cursor: 'pointer',
              transition: 'all 0.15s ease',
            }}
          >
            <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
              <Avatar
                src={w.avatar}
                name={w.name}
                size={42}
              />
              <div>
                <div style={{ fontSize: '13.5px', fontWeight: '700', color: '#1e293b' }}>
                  {w.name}
                </div>
                <div style={{ fontSize: '12px', color: '#64748b', display: 'flex', alignItems: 'center', gap: '8px' }}>
                  <span>⭐ {w.rating} ({w.totalReviews} reviews)</span>
                  <span>•</span>
                  <span>📍 ~2.4 km away</span>
                </div>
              </div>
            </div>

            <div style={{ textAlign: 'right' }}>
              <span
                style={{
                  fontSize: '11px',
                  fontWeight: '600',
                  padding: '3px 8px',
                  borderRadius: '999px',
                  backgroundColor: w.availability === 'Available' ? '#eaf8ef' : '#fef8e7',
                  color: w.availability === 'Available' ? '#15803d' : '#d97706',
                }}
              >
                {w.availability}
              </span>
              <div style={{ fontSize: '11.5px', color: '#64748b', marginTop: '4px' }}>
                {w.hourlyRate}
              </div>
            </div>
          </div>
        ))}
      </div>
    </Modal>
  );
}
