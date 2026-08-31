import React, { useState } from 'react';
import Modal from '../common/Modal';
import { useApp } from '../../context/AppContext';
import { Send, Bell } from 'lucide-react';

export default function SendNotificationModal({ isOpen, onClose }) {
  const { addNotification } = useApp();

  const [formData, setFormData] = useState({
    title: '',
    message: '',
    targetAudience: 'All Users',
    priority: 'Normal',
    category: 'System',
  });

  const [errors, setErrors] = useState({});

  const validate = () => {
    const errs = {};
    if (!formData.title.trim()) errs.title = 'Notification title is required';
    if (!formData.message.trim()) errs.message = 'Notification message is required';
    setErrors(errs);
    return Object.keys(errs).length === 0;
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    if (!validate()) return;

    addNotification(formData);
    onClose();
  };

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title="Dispatch Platform Notification"
      subtitle="Broadcast announcements, emergency alerts, or targeted updates"
      maxWidth="520px"
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
            onClick={handleSubmit}
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '6px',
              padding: '8px 20px',
              borderRadius: '8px',
              backgroundColor: 'var(--primary-brand)',
              color: '#ffffff',
              fontSize: '13px',
              fontWeight: '600',
            }}
          >
            <Send size={14} />
            <span>Send Notification</span>
          </button>
        </>
      }
    >
      <form onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
        <div>
          <label style={{ fontSize: '12px', fontWeight: '600', color: '#334155', display: 'block', marginBottom: '4px' }}>
            Alert Title *
          </label>
          <input
            type="text"
            placeholder="e.g. Surge Demand Alert in South Delhi"
            value={formData.title}
            onChange={(e) => setFormData({ ...formData, title: e.target.value })}
            style={{
              width: '100%',
              padding: '8px 12px',
              borderRadius: '8px',
              border: `1px solid ${errors.title ? '#ef4444' : '#cbd5e1'}`,
              fontSize: '13px',
            }}
          />
          {errors.title && <span style={{ fontSize: '11px', color: '#ef4444' }}>{errors.title}</span>}
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
          <div>
            <label style={{ fontSize: '12px', fontWeight: '600', color: '#334155', display: 'block', marginBottom: '4px' }}>
              Target Audience
            </label>
            <select
              value={formData.targetAudience}
              onChange={(e) => setFormData({ ...formData, targetAudience: e.target.value })}
              style={{
                width: '100%',
                padding: '8px 12px',
                borderRadius: '8px',
                border: '1px solid #cbd5e1',
                fontSize: '13px',
                backgroundColor: '#ffffff',
              }}
            >
              <option value="All Users">All Users (Workers & Customers)</option>
              <option value="Workers">Verified Workers Only</option>
              <option value="Customers">Active Customers Only</option>
              <option value="Emergency Staff">Emergency On-Duty Field Staff</option>
            </select>
          </div>

          <div>
            <label style={{ fontSize: '12px', fontWeight: '600', color: '#334155', display: 'block', marginBottom: '4px' }}>
              Priority Level
            </label>
            <select
              value={formData.priority}
              onChange={(e) => setFormData({ ...formData, priority: e.target.value })}
              style={{
                width: '100%',
                padding: '8px 12px',
                borderRadius: '8px',
                border: '1px solid #cbd5e1',
                fontSize: '13px',
                backgroundColor: '#ffffff',
              }}
            >
              <option value="Normal">Normal Notification</option>
              <option value="High">High Priority (Push / SMS)</option>
              <option value="Emergency">🚨 Critical Emergency Flash</option>
              <option value="Low">Low (Informational)</option>
            </select>
          </div>
        </div>

        <div>
          <label style={{ fontSize: '12px', fontWeight: '600', color: '#334155', display: 'block', marginBottom: '4px' }}>
            Notification Message *
          </label>
          <textarea
            rows="3"
            placeholder="Type your broadcast message clearly..."
            value={formData.message}
            onChange={(e) => setFormData({ ...formData, message: e.target.value })}
            style={{
              width: '100%',
              padding: '8px 12px',
              borderRadius: '8px',
              border: `1px solid ${errors.message ? '#ef4444' : '#cbd5e1'}`,
              fontSize: '13px',
              fontFamily: 'inherit',
            }}
          />
          {errors.message && <span style={{ fontSize: '11px', color: '#ef4444' }}>{errors.message}</span>}
        </div>
      </form>
    </Modal>
  );
}
