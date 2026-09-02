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
    recipientEmail: '',
    sendEmail: false,
    priority: 'Normal',
    category: 'System',
  });

  const [errors, setErrors] = useState({});

  const validate = () => {
    const errs = {};
    if (!formData.title.trim()) errs.title = 'Notification title is required';
    if (!formData.message.trim()) errs.message = 'Notification message is required';
    if (formData.targetAudience === 'Specific Email' && !formData.recipientEmail.trim()) {
      errs.recipientEmail = 'Recipient email address is required';
    }
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
      subtitle="Broadcast announcements, emergency alerts, or custom personal emails"
      maxWidth="540px"
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
              backgroundColor: '#15803d',
              color: '#ffffff',
              fontSize: '13px',
              fontWeight: '600',
              border: 'none',
              cursor: 'pointer',
              boxShadow: '0 2px 4px rgba(21, 128, 61, 0.2)',
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
              <option value="Workers Only">Verified Workers Only</option>
              <option value="Customers Only">Active Customers Only</option>
              <option value="Specific Email">✉️ Specific Personal Email</option>
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

        {formData.targetAudience === 'Specific Email' && (
          <div>
            <label style={{ fontSize: '12px', fontWeight: '600', color: '#334155', display: 'block', marginBottom: '4px' }}>
              Target Personal Email Address *
            </label>
            <input
              type="email"
              placeholder="e.g. user@gmail.com"
              value={formData.recipientEmail}
              onChange={(e) => setFormData({ ...formData, recipientEmail: e.target.value })}
              style={{
                width: '100%',
                padding: '8px 12px',
                borderRadius: '8px',
                border: `1px solid ${errors.recipientEmail ? '#ef4444' : '#cbd5e1'}`,
                fontSize: '13px',
              }}
            />
            {errors.recipientEmail && <span style={{ fontSize: '11px', color: '#ef4444' }}>{errors.recipientEmail}</span>}
          </div>
        )}

        <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginTop: '2px' }}>
          <input
            type="checkbox"
            id="sendEmail"
            checked={formData.sendEmail}
            onChange={(e) => setFormData({ ...formData, sendEmail: e.target.checked })}
            style={{ width: '16px', height: '16px', cursor: 'pointer' }}
          />
          <label htmlFor="sendEmail" style={{ fontSize: '12.5px', color: '#334155', fontWeight: '600', cursor: 'pointer' }}>
            Dispatch direct Email notification message
          </label>
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
