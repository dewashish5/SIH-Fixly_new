import React, { useState } from 'react';
import Modal from '../common/Modal';
import { useApp } from '../../context/AppContext';
import { api } from '../../services/api';
import { Upload, CheckCircle2 } from 'lucide-react';

export default function AddServiceModal({ isOpen, onClose }) {
  const { addService } = useApp();

  const [formData, setFormData] = useState({
    name: '',
    category: 'Plumbing',
    description: '',
    basePrice: '₹350',
    image: '',
    requiredSkills: '',
    availability: '24/7 Available',
    emergencyAvailable: true,
    status: 'Active',
  });

  const [uploadingImage, setUploadingImage] = useState(false);
  const [errors, setErrors] = useState({});

  const handleFileUpload = async (e) => {
    const file = e.target.files[0];
    if (!file) return;

    try {
      setUploadingImage(true);
      const res = await api.uploadImage(file);
      if (res && res.url) {
        setFormData((prev) => ({ ...prev, image: res.url }));
      }
    } catch (err) {
      console.error('File upload failed:', err);
      alert('Failed to upload image. Please try again.');
    } finally {
      setUploadingImage(false);
    }
  };

  const validate = () => {
    const errs = {};
    if (!formData.name.trim()) errs.name = 'Service name is required';
    if (!formData.description.trim()) errs.description = 'Description is required';
    if (!formData.basePrice.trim()) errs.basePrice = 'Base price is required';
    setErrors(errs);
    return Object.keys(errs).length === 0;
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!validate()) return;

    try {
      await addService({
        title: formData.name,
        category: formData.category || 'Plumbing',
        image: formData.image || '',
        basePrice: parseInt(formData.basePrice.replace(/\D/g, ''), 10) || 100,
        estimatedTime: '1 Hour',
        whatsIncluded: formData.description ? [formData.description] : ['Professional Service'],
        isActive: formData.status === 'Active'
      });
      onClose();
    } catch (err) {
      console.error('Failed to add service modal:', err);
    }
  };

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title="Add New Cooperative Service"
      subtitle="Define rate cards, skill prerequisites, and emergency availability"
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
            onClick={handleSubmit}
            style={{
              padding: '8px 20px',
              borderRadius: '8px',
              backgroundColor: 'var(--primary-brand)',
              color: '#ffffff',
              fontSize: '13px',
              fontWeight: '600',
            }}
          >
            Publish to Catalog
          </button>
        </>
      }
    >
      <form onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
        <div>
          <label style={{ fontSize: '12px', fontWeight: '600', color: '#334155', display: 'block', marginBottom: '4px' }}>
            Service Title *
          </label>
          <input
            type="text"
            placeholder="e.g. Geyser Repair & Thermostat Installation"
            value={formData.name}
            onChange={(e) => setFormData({ ...formData, name: e.target.value })}
            style={{
              width: '100%',
              padding: '8px 12px',
              borderRadius: '8px',
              border: `1px solid ${errors.name ? '#ef4444' : '#cbd5e1'}`,
              fontSize: '13px',
            }}
          />
          {errors.name && <span style={{ fontSize: '11px', color: '#ef4444' }}>{errors.name}</span>}
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
          <div>
            <label style={{ fontSize: '12px', fontWeight: '600', color: '#334155', display: 'block', marginBottom: '4px' }}>
              Service Category *
            </label>
            <select
              value={formData.category}
              onChange={(e) => setFormData({ ...formData, category: e.target.value })}
              style={{
                width: '100%',
                padding: '8px 12px',
                borderRadius: '8px',
                border: '1px solid #cbd5e1',
                fontSize: '13px',
                backgroundColor: '#ffffff',
              }}
            >
              <option value="Plumbing">Plumbing</option>
              <option value="Electrical">Electrical</option>
              <option value="Carpentry">Carpentry</option>
              <option value="Cleaning">Cleaning</option>
              <option value="AC Repair">AC Repair</option>
              <option value="Painting">Painting</option>
              <option value="Caregiving">Caregiving</option>
              <option value="Driving">Driving</option>
              <option value="Domestic Help">Domestic Help</option>
              <option value="Technician">Technician</option>
            </select>
          </div>

          <div>
            <label style={{ fontSize: '12px', fontWeight: '600', color: '#334155', display: 'block', marginBottom: '4px' }}>
              Base Standard Rate *
            </label>
            <input
              type="text"
              placeholder="₹350"
              value={formData.basePrice}
              onChange={(e) => setFormData({ ...formData, basePrice: e.target.value })}
              style={{
                width: '100%',
                padding: '8px 12px',
                borderRadius: '8px',
                border: `1px solid ${errors.basePrice ? '#ef4444' : '#cbd5e1'}`,
                fontSize: '13px',
              }}
            />
            {errors.basePrice && <span style={{ fontSize: '11px', color: '#ef4444' }}>{errors.basePrice}</span>}
          </div>
        </div>

        <div>
          <label style={{ fontSize: '12px', fontWeight: '600', color: '#334155', display: 'block', marginBottom: '6px' }}>
            Service Banner / Icon Image Upload *
          </label>
          <div
            style={{
              border: '2px dashed #cbd5e1',
              borderRadius: '10px',
              padding: '16px',
              textAlign: 'center',
              backgroundColor: '#f8fafc',
              position: 'relative',
              cursor: 'pointer'
            }}
          >
            {formData.image ? (
              <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                <img
                  src={formData.image}
                  alt="Preview"
                  style={{ width: '54px', height: '54px', borderRadius: '8px', objectFit: 'cover', border: '1px solid #cbd5e1' }}
                />
                <div style={{ textAlign: 'left', flex: 1 }}>
                  <div style={{ fontSize: '12.5px', fontWeight: '700', color: '#15803d', display: 'flex', alignItems: 'center', gap: '4px' }}>
                    <CheckCircle2 size={14} /> Image Uploaded Successfully!
                  </div>
                  <div style={{ fontSize: '11px', color: '#64748b', textOverflow: 'ellipsis', overflow: 'hidden', whiteSpace: 'nowrap', maxWidth: '240px' }}>
                    {formData.image.startsWith('data:') ? 'Image selected from desktop' : formData.image}
                  </div>
                </div>
                <button
                  type="button"
                  onClick={() => setFormData({ ...formData, image: '' })}
                  style={{ fontSize: '12px', color: '#ef4444', border: 'none', background: 'none', cursor: 'pointer', fontWeight: '600' }}
                >
                  Change
                </button>
              </div>
            ) : (
              <div>
                <Upload size={22} color="#64748b" style={{ marginBottom: '4px' }} />
                <div style={{ fontSize: '13px', fontWeight: '600', color: '#334155' }}>
                  {uploadingImage ? 'Uploading image from desktop...' : 'Click to select image file from Desktop'}
                </div>
                <div style={{ fontSize: '11px', color: '#94a3b8', marginTop: '2px' }}>
                  Supports PNG, JPG, WEBP up to 5MB
                </div>
                <input
                  type="file"
                  accept="image/*"
                  onChange={handleFileUpload}
                  disabled={uploadingImage}
                  style={{
                    position: 'absolute',
                    top: 0,
                    left: 0,
                    width: '100%',
                    height: '100%',
                    opacity: 0,
                    cursor: 'pointer'
                  }}
                />
              </div>
            )}
          </div>
        </div>

        <div>
          <label style={{ fontSize: '12px', fontWeight: '600', color: '#334155', display: 'block', marginBottom: '4px' }}>
            Service Description *
          </label>
          <textarea
            rows="3"
            placeholder="Detailed scope of service, warranty terms, and standard tools required..."
            value={formData.description}
            onChange={(e) => setFormData({ ...formData, description: e.target.value })}
            style={{
              width: '100%',
              padding: '8px 12px',
              borderRadius: '8px',
              border: `1px solid ${errors.description ? '#ef4444' : '#cbd5e1'}`,
              fontSize: '13px',
              fontFamily: 'inherit',
            }}
          />
          {errors.description && <span style={{ fontSize: '11px', color: '#ef4444' }}>{errors.description}</span>}
        </div>

        <div>
          <label style={{ fontSize: '12px', fontWeight: '600', color: '#334155', display: 'block', marginBottom: '4px' }}>
            Mandatory Skill Certifications
          </label>
          <input
            type="text"
            placeholder="e.g. Electrical Safety License, High-Voltage Certification"
            value={formData.requiredSkills}
            onChange={(e) => setFormData({ ...formData, requiredSkills: e.target.value })}
            style={{
              width: '100%',
              padding: '8px 12px',
              borderRadius: '8px',
              border: '1px solid #cbd5e1',
              fontSize: '13px',
            }}
          />
        </div>

        <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginTop: '4px' }}>
          <input
            type="checkbox"
            id="emergency"
            checked={formData.emergencyAvailable}
            onChange={(e) => setFormData({ ...formData, emergencyAvailable: e.target.checked })}
            style={{ width: '18px', height: '18px', accentColor: '#1e7e45' }}
          />
          <label htmlFor="emergency" style={{ fontSize: '13px', color: '#1e293b', fontWeight: '500', cursor: 'pointer' }}>
            Enable 24/7 Emergency Instant Dispatch for this service
          </label>
        </div>
      </form>
    </Modal>
  );
}
