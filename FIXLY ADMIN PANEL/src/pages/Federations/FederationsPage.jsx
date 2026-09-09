import React, { useState, useEffect } from 'react';
import { useApp } from '../../context/AppContext';
import { api } from '../../services/api';
import { useToast } from '../../context/ToastContext';
import { Building2, Search, Eye, CheckCircle, XCircle } from 'lucide-react';
import { Link } from 'react-router-dom';

export default function FederationsPage() {
  const { adminRole } = useApp();
  const { showToast } = useToast();
  const [federations, setFederations] = useState([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');

  const fetchFederations = async () => {
    try {
      setLoading(true);
      const res = await api.getAllFederations();
      if (res.success) {
        setFederations(res.data);
      }
    } catch (err) {
      showToast('error', 'Failed to fetch federations');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchFederations();
  }, []);

  const handleApprove = async (id) => {
    try {
      const res = await api.approveFederation(id);
      if (res.success) {
        showToast('success', 'Federation approved successfully');
        fetchFederations();
      }
    } catch (err) {
      showToast('error', 'Failed to approve federation');
    }
  };

  const handleSuspend = async (id) => {
    try {
      const res = await api.suspendFederation(id);
      if (res.success) {
        showToast('success', 'Federation suspended successfully');
        fetchFederations();
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

  const filtered = federations.filter((f) => 
    (f.name || '').toLowerCase().includes(search.toLowerCase()) ||
    (f.registrationNumber || '').toLowerCase().includes(search.toLowerCase())
  );

  return (
    <div style={{ padding: '0 32px 32px', animation: 'fadeIn 0.2s ease' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 24 }}>
        <div>
          <h2 style={{ fontSize: 24, fontWeight: 700, color: '#111827', display: 'flex', alignItems: 'center', gap: 10 }}>
            <Building2 size={26} color="var(--primary-brand)" /> Federation Management
          </h2>
          <p style={{ fontSize: 14, color: '#64748b', marginTop: 4 }}>
            Manage and oversee all registered cooperative federations.
          </p>
        </div>
      </div>

      <div style={{ background: '#fff', borderRadius: 16, padding: '20px', border: '1px solid var(--border-light)' }}>
        <div style={{ display: 'flex', gap: 12, marginBottom: 20 }}>
          <div style={{ position: 'relative', flex: 1, maxWidth: 300 }}>
            <Search size={18} color="#94a3b8" style={{ position: 'absolute', left: 12, top: '50%', transform: 'translateY(-50%)' }} />
            <input
              type="text"
              placeholder="Search federations..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              style={{
                width: '100%',
                padding: '10px 10px 10px 38px',
                borderRadius: 10,
                border: '1px solid #e2e8f0',
                outline: 'none',
                fontSize: 14
              }}
            />
          </div>
        </div>

        <div style={{ overflowX: 'auto' }}>
          <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: 14 }}>
            <thead>
              <tr style={{ borderBottom: '1px solid #e2e8f0', color: '#64748b', textAlign: 'left' }}>
                <th style={{ padding: '12px 16px', fontWeight: 600 }}>Name</th>
                <th style={{ padding: '12px 16px', fontWeight: 600 }}>Reg. No.</th>
                <th style={{ padding: '12px 16px', fontWeight: 600 }}>State / District</th>
                <th style={{ padding: '12px 16px', fontWeight: 600 }}>Email</th>
                <th style={{ padding: '12px 16px', fontWeight: 600 }}>Status</th>
                <th style={{ padding: '12px 16px', fontWeight: 600, textAlign: 'right' }}>Actions</th>
              </tr>
            </thead>
            <tbody>
              {loading ? (
                <tr>
                  <td colSpan={6} style={{ textAlign: 'center', padding: '30px', color: '#64748b' }}>
                    Loading...
                  </td>
                </tr>
              ) : filtered.length === 0 ? (
                <tr>
                  <td colSpan={6} style={{ textAlign: 'center', padding: '30px', color: '#64748b' }}>
                    No federations found.
                  </td>
                </tr>
              ) : (
                filtered.map((f) => (
                  <tr key={f._id} style={{ borderBottom: '1px solid #f1f5f9' }}>
                    <td style={{ padding: '14px 16px', fontWeight: 500, color: '#1e293b' }}>{f.name}</td>
                    <td style={{ padding: '14px 16px', color: '#64748b' }}>{f.registrationNumber}</td>
                    <td style={{ padding: '14px 16px', color: '#64748b' }}>{f.state} / {f.district}</td>
                    <td style={{ padding: '14px 16px', color: '#64748b' }}>{f.ownerEmail}</td>
                    <td style={{ padding: '14px 16px' }}>
                      <span style={{
                        padding: '4px 10px',
                        borderRadius: 999,
                        fontSize: 12,
                        fontWeight: 600,
                        backgroundColor: f.status === 'approved' ? '#dcfce7' : f.status === 'suspended' ? '#fee2e2' : '#fef9c3',
                        color: f.status === 'approved' ? '#166534' : f.status === 'suspended' ? '#991b1b' : '#854d0e',
                      }}>
                        {(f.status || 'pending').toUpperCase()}
                      </span>
                    </td>
                    <td style={{ padding: '14px 16px', textAlign: 'right' }}>
                      <div style={{ display: 'flex', gap: 8, justifyContent: 'flex-end' }}>
                        {f.status !== 'approved' && (
                          <button
                            onClick={() => handleApprove(f._id)}
                            style={{ padding: '6px', borderRadius: 6, background: '#dcfce7', color: '#166534', border: 'none', cursor: 'pointer' }}
                            title="Approve"
                          >
                            <CheckCircle size={16} />
                          </button>
                        )}
                        {f.status !== 'suspended' && (
                          <button
                            onClick={() => handleSuspend(f._id)}
                            style={{ padding: '6px', borderRadius: 6, background: '#fee2e2', color: '#991b1b', border: 'none', cursor: 'pointer' }}
                            title="Suspend"
                          >
                            <XCircle size={16} />
                          </button>
                        )}
                        <Link
                          to={`/federations/${f._id}`}
                          style={{ padding: '6px', borderRadius: 6, background: '#f1f5f9', color: '#475569', border: 'none', cursor: 'pointer', display: 'inline-flex' }}
                          title="View Details"
                        >
                          <Eye size={16} />
                        </Link>
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
