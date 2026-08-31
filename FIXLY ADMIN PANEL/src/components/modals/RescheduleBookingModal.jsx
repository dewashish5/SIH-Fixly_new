import React, { useState } from 'react';
import Modal from '../common/Modal';
import { useApp } from '../../context/AppContext';
import { Calendar, Clock } from 'lucide-react';

export default function RescheduleBookingModal({ booking, isOpen, onClose }) {
  const { rescheduleBooking } = useApp();

  const [date, setDate] = useState('2025-05-27');
  const [timeSlot, setTimeSlot] = useState('10:00 AM - 12:00 PM');

  if (!booking) return null;

  const handleReschedule = () => {
    const formattedDate = new Date(date).toLocaleDateString('en-GB', {
      day: 'numeric',
      month: 'short',
      year: 'numeric',
    });
    const newSlot = `${formattedDate}, ${timeSlot}`;
    rescheduleBooking(booking.id, newSlot);
    onClose();
  };

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title={`Reschedule Booking ${booking.id}`}
      subtitle={`Customer: ${booking.customer} • Current: ${booking.scheduledSlot || booking.date}`}
      maxWidth="480px"
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
            onClick={handleReschedule}
            style={{
              padding: '8px 20px',
              borderRadius: '8px',
              backgroundColor: 'var(--primary-brand)',
              color: '#ffffff',
              fontSize: '13px',
              fontWeight: '600',
            }}
          >
            Confirm Reschedule
          </button>
        </>
      }
    >
      <div style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
        <div>
          <label style={{ fontSize: '12px', fontWeight: '600', color: '#334155', display: 'block', marginBottom: '4px' }}>
            Select New Service Date
          </label>
          <input
            type="date"
            value={date}
            onChange={(e) => setDate(e.target.value)}
            style={{
              width: '100%',
              padding: '8px 12px',
              borderRadius: '8px',
              border: '1px solid #cbd5e1',
              fontSize: '13px',
            }}
          />
        </div>

        <div>
          <label style={{ fontSize: '12px', fontWeight: '600', color: '#334155', display: 'block', marginBottom: '4px' }}>
            Select Preferred Time Slot
          </label>
          <select
            value={timeSlot}
            onChange={(e) => setTimeSlot(e.target.value)}
            style={{
              width: '100%',
              padding: '8px 12px',
              borderRadius: '8px',
              border: '1px solid #cbd5e1',
              fontSize: '13px',
              backgroundColor: '#ffffff',
            }}
          >
            <option value="08:00 AM - 10:00 AM">08:00 AM - 10:00 AM (Morning)</option>
            <option value="10:00 AM - 12:00 PM">10:00 AM - 12:00 PM (Midday)</option>
            <option value="02:00 PM - 04:00 PM">02:00 PM - 04:00 PM (Afternoon)</option>
            <option value="04:00 PM - 06:00 PM">04:00 PM - 06:00 PM (Evening)</option>
            <option value="06:00 PM - 08:00 PM">06:00 PM - 08:00 PM (Night)</option>
          </select>
        </div>
      </div>
    </Modal>
  );
}
