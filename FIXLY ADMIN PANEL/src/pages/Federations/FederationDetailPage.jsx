import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useApp } from '../../context/AppContext';
import { api } from '../../services/api';
import { useToast } from '../../context/ToastContext';
import { Building2, ArrowLeft, CheckCircle, XCircle } from 'lucide-react';

export default function FederationDetailPage() {
  const { id } = useParams();
  const navigate = useNavigate();
  const { adminRole } = useApp();
  const { showToast } = useToast();
  const [federation, setFederation] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchFederation = async () => {
      try {
        setLoading(true);
        const res = await api.getFederationDetails(id);
        if (res.success) {
          setFederation(res.data);
        }
      } catch (err) {
        showToast('error', 'Failed to fetch federation details');
      } finally {
        setLoading(false);
      }
    };
    fetchFederation();
  }, [id]);

  const handleApprove = async () => {
    try {
      const res = await api.approveFederation(id);
      if (res.success) {
        showToast('success', 'Federation approved successfully');
        setFederation({ ...federation, status: 'approved' });
      }
    } catch (err) {
      showToast('error', 'Failed to approve federation');
    }
  };

  const handleSuspend = async () => {
    try {
      const res = await api.suspendFederation(id);
      if (res.success) {
        showToast('success', 'Federation suspended successfully');
        setFederation({ ...federation, status: 'suspended' });
      }
    } catch (err) {
      showToast('error', 'Failed to suspend federation');
    }
  };

  if (adminRole !== 'super_admin') {
    return (
      <div style={{ padding: '32px', textAlign: 'center' }}>
        <h2>Unauthorized</h2>
        <p>You do not have permission to view this page.</p>
      </div>
    );
  }

  if (loading) {
    return <div style={{ padding: '32px', textAlign: 'center' }}>Loading...</div>;
  }

  if (!federation) {
    return <div style={{ padding: '32px', textAlign: 'center' }}>Federation not found.</div>;
  }

  return (
    <div style={{ padding: '0 32px 32px', animation: 'fadeIn 0.2s ease' }}>
      <button
        onClick={() => navigate('/federations')}
        style={{ display: 'inline-flex', alignItems: 'center', gap: 6, padding: '8px 0', border: 'none', background: 'transparent', color: '#64748b', cursor: 'pointer', marginBottom: 16 }}
      >
        <ArrowLeft size={16} /> Back to Federations
      </button>

      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 24 }}>
        <div>
          <h2 style={{ fontSize: 24, fontWeight: 700, color: '#111827', display: 'flex', alignItems: 'center', gap: 10 }}>
            <Building2 size={26} color="var(--primary-brand)" /> {federation.name}
          </h2>
          <p style={{ fontSize: 14, color: '#64748b', marginTop: 4 }}>
            Registration: {federation.registrationNumber}
          </p>
        </div>
        <div style={{ display: 'flex', gap: 12 }}>
          {federation.status !== 'approved' && (
            <button
              onClick={handleApprove}
              style={{ padding: '8px 16px', borderRadius: 8, background: '#166534', color: '#fff', border: 'none', cursor: 'pointer', display: 'flex', gap: 6, alignItems: 'center' }}
            >
              <CheckCircle size={16} /> Approve
            </button>
          )}
          {federation.status !== 'suspended' && (
            <button
              onClick={handleSuspend}
              style={{ padding: '8px 16px', borderRadius: 8, background: '#dc2626', color: '#fff', border: 'none', cursor: 'pointer', display: 'flex', gap: 6, alignItems: 'center' }}
            >
              <XCircle size={16} /> Suspend
            </button>
          )}
        </div>
      </div>

      <div style={{ background: '#fff', borderRadius: 16, padding: '24px', border: '1px solid var(--border-light)' }}>
        <h3 style={{ fontSize: 16, fontWeight: 600, marginBottom: 16, borderBottom: '1px solid #f1f5f9', paddingBottom: 8 }}>Details</h3>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16, fontSize: 14 }}>
          <div>
            <div style={{ color: '#64748b', marginBottom: 4 }}>State</div>
            <div style={{ fontWeight: 500, color: '#1e293b' }}>{federation.state || 'N/A'}</div>
          </div>
          <div>
            <div style={{ color: '#64748b', marginBottom: 4 }}>District</div>
            <div style={{ fontWeight: 500, color: '#1e293b' }}>{federation.district || 'N/A'}</div>
          </div>
          <div>
            <div style={{ color: '#64748b', marginBottom: 4 }}>Owner Email</div>
            <div style={{ fontWeight: 500, color: '#1e293b' }}>{federation.ownerEmail || 'N/A'}</div>
          </div>
          <div>
            <div style={{ color: '#64748b', marginBottom: 4 }}>Status</div>
            <div style={{ fontWeight: 500, color: '#1e293b', textTransform: 'capitalize' }}>{federation.status || 'N/A'}</div>
          </div>
        </div>
      </div>
    </div>
  );
}
