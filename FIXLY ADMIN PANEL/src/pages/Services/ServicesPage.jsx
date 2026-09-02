import React, { useState } from 'react';
import { useApp } from '../../context/AppContext';
import {
  Wrench,
  Zap,
  Sparkles,
  Hammer,
  Wind,
  HeartHandshake,
  Paintbrush,
  Car,
  Trees,
  Layers,
  Plus,
  Search,
  Trash2,
  Edit,
  ShieldCheck,
  CheckCircle
} from 'lucide-react';
import AddServiceModal from '../../components/modals/AddServiceModal';
import ConfirmDialog from '../../components/common/ConfirmDialog';
import Badge from '../../components/common/Badge';
import Pagination from '../../components/common/Pagination';

export default function ServicesPage() {
  const { services, servicesPagination, fetchServices, deleteService, updateService } = useApp();

  const [search, setSearch] = useState('');
  const [currentPage, setCurrentPage] = useState(1);
  const [isAddModalOpen, setIsAddModalOpen] = useState(false);
  const [serviceToDelete, setServiceToDelete] = useState(null);
  const [serviceToEdit, setServiceToEdit] = useState(null);
  const pageSize = 10;

  React.useEffect(() => {
    fetchServices({
      page: currentPage,
      limit: pageSize,
      search
    });
  }, [fetchServices, currentPage, search]);

  let filtered = [...services];
  if (search && search.trim() !== '') {
    const q = search.toLowerCase().trim();
    filtered = filtered.filter(s => 
      (s.title || s.name || '').toLowerCase().includes(q) || 
      (s.category || s.categoryName || '').toLowerCase().includes(q) ||
      (s.description || '').toLowerCase().includes(q)
    );
  }

  const getServiceIcon = (iconName, color) => {
    switch (iconName) {
      case 'Wrench': return <Wrench size={22} color={color || '#1e40af'} strokeWidth={2.2} />;
      case 'Zap': return <Zap size={22} color={color || '#ca8a04'} strokeWidth={2.2} />;
      case 'Sparkles': return <Sparkles size={22} color={color || '#16a34a'} strokeWidth={2.2} />;
      case 'Hammer': return <Hammer size={22} color={color || '#ea580c'} strokeWidth={2.2} />;
      case 'Wind': return <Wind size={22} color={color || '#0284c7'} strokeWidth={2.2} />;
      case 'HeartHandshake': return <HeartHandshake size={22} color={color || '#db2777'} strokeWidth={2.2} />;
      case 'Paintbrush': return <Paintbrush size={22} color={color || '#9333ea'} strokeWidth={2.2} />;
      case 'Car': return <Car size={22} color={color || '#0d9488'} strokeWidth={2.2} />;
      case 'Trees': return <Trees size={22} color={color || '#65a30d'} strokeWidth={2.2} />;
      default: return <Layers size={22} color={color || '#1e7e45'} strokeWidth={2.2} />;
    }
  };

  return (
    <div style={{ padding: '0 32px 32px 32px', animation: 'fadeIn 0.2s ease' }}>
      {/* Header */}
      <div
        style={{
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          marginBottom: '20px',
          flexWrap: 'wrap',
          gap: '12px',
        }}
      >
        <div>
          <h2 style={{ fontSize: '20px', fontWeight: '700', color: '#111827' }}>
            Service Catalog & Rate Cards ({services.length})
          </h2>
          <p style={{ fontSize: '13px', color: '#64748b' }}>
            Household & community gig services, benchmark rates, required certifications, and welfare allocation
          </p>
        </div>

        <button
          onClick={() => setIsAddModalOpen(true)}
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: '6px',
            padding: '9px 16px',
            backgroundColor: 'var(--primary-brand)',
            color: '#ffffff',
            borderRadius: '8px',
            fontSize: '13px',
            fontWeight: '600',
            boxShadow: 'var(--shadow-pill)',
          }}
        >
          <Plus size={16} />
          <span>Add New Service</span>
        </button>
      </div>

      {/* Search Bar */}
      <div
        style={{
          backgroundColor: '#ffffff',
          padding: '12px 18px',
          borderRadius: '12px',
          border: '1px solid var(--border-light)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          marginBottom: '20px',
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: '8px', width: '320px' }}>
          <Search size={15} color="#94a3b8" />
          <input
            type="text"
            placeholder="Search service title, trade, description..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            style={{ border: 'none', outline: 'none', width: '100%', fontSize: '13px' }}
          />
        </div>
        <div style={{ fontSize: '12px', color: '#64748b' }}>
          Showing {filtered.length} categories
        </div>
      </div>

      {/* Service Cards Grid */}
      <div
        style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fill, minmax(320px, 1fr))',
          gap: '20px',
        }}
      >
        {filtered.map((s) => (
          <div
            key={s.id}
            style={{
              backgroundColor: '#ffffff',
              borderRadius: '16px',
              border: '1px solid var(--border-light)',
              padding: '22px',
              boxShadow: 'var(--shadow-card)',
              display: 'flex',
              flexDirection: 'column',
              justifyContent: 'space-between',
              position: 'relative',
            }}
          >
            <div>
              {/* Card Header */}
              <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                  {s.image ? (
                    <img
                      src={s.image}
                      alt={s.name}
                      onError={(e) => { e.target.style.display = 'none'; }}
                      style={{
                        width: '46px',
                        height: '46px',
                        borderRadius: '12px',
                        objectFit: 'cover',
                        border: '1px solid #e2e8f0',
                        flexShrink: 0,
                      }}
                    />
                  ) : (
                    <div
                      style={{
                        width: '46px',
                        height: '46px',
                        borderRadius: '12px',
                        backgroundColor: s.bg || '#f0fdf4',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        flexShrink: 0,
                      }}
                    >
                      {getServiceIcon(s.icon, s.iconColor)}
                    </div>
                  )}
                  <div>
                    <h3 style={{ fontSize: '16px', fontWeight: '700', color: '#111827' }}>
                      {s.name}
                    </h3>
                    <div style={{ fontSize: '12px', color: '#64748b' }}>
                      Category: <strong>{s.category}</strong>
                    </div>
                  </div>
                </div>

                <Badge status={s.status} />
              </div>

              {/* Description */}
              <p style={{ fontSize: '12.5px', color: '#475569', marginTop: '14px', lineHeight: '1.4' }}>
                {s.description}
              </p>

              {/* Details Metrics */}
              <div
                style={{
                  display: 'grid',
                  gridTemplateColumns: '1fr 1fr',
                  gap: '8px',
                  backgroundColor: '#f8faf9',
                  padding: '12px',
                  borderRadius: '10px',
                  marginTop: '14px',
                  fontSize: '12px',
                }}
              >
                <div>
                  <div style={{ color: '#64748b' }}>Standard Base Rate</div>
                  <div style={{ fontWeight: '800', color: '#0f172a', fontSize: '14px' }}>
                    {s.basePrice}
                  </div>
                </div>
                <div>
                  <div style={{ color: '#64748b' }}>Cooperative Welfare Pool</div>
                  <div style={{ fontWeight: '700', color: '#15803d', fontSize: '14px' }}>
                    5% Reserved
                  </div>
                </div>
              </div>

              {/* Skills */}
              <div style={{ marginTop: '12px', fontSize: '11.5px', color: '#64748b' }}>
                <strong>Prerequisites:</strong> {s.requiredSkills}
              </div>

              {s.emergencyAvailable && (
                <div style={{ marginTop: '8px', fontSize: '11.5px', color: '#dc2626', fontWeight: '600', display: 'flex', alignItems: 'center', gap: '4px' }}>
                  <span>⚡ 24/7 Emergency Dispatch Enabled</span>
                </div>
              )}
            </div>

            {/* Actions */}
            <div style={{ display: 'flex', gap: '8px', marginTop: '16px', borderTop: '1px solid #f1f5f9', paddingTop: '14px' }}>
              <button
                onClick={() => {
                  const newRate = prompt('Enter new benchmark rate:', s.basePrice);
                  if (newRate) updateService(s.id, { basePrice: newRate });
                }}
                style={{
                  flex: 1,
                  padding: '7px',
                  borderRadius: '8px',
                  backgroundColor: '#f1f5f9',
                  color: '#334155',
                  fontSize: '12px',
                  fontWeight: '600',
                }}
              >
                Edit Rate Card
              </button>

              <button
                onClick={() => setServiceToDelete(s)}
                style={{
                  padding: '7px 10px',
                  borderRadius: '8px',
                  backgroundColor: '#fef2f2',
                  color: '#dc2626',
                  fontSize: '12px',
                }}
                title="Delete Service"
              >
                <Trash2 size={15} />
              </button>
            </div>
          </div>
        ))}
      </div>

      <div style={{ marginTop: '20px' }}>
        <Pagination
          currentPage={currentPage}
          totalItems={servicesPagination?.total || filtered.length}
          pageSize={pageSize}
          onPageChange={(p) => setCurrentPage(p)}
        />
      </div>

      <AddServiceModal isOpen={isAddModalOpen} onClose={() => setIsAddModalOpen(false)} />

      {/* Delete confirmation */}
      <ConfirmDialog
        isOpen={!!serviceToDelete}
        onClose={() => setServiceToDelete(null)}
        onConfirm={() => deleteService(serviceToDelete.id)}
        title="Remove Service from Catalog?"
        message={`Are you sure you want to remove "${serviceToDelete?.name}"? Existing active bookings will remain unaffected.`}
        confirmText="Remove Service"
        isDestructive={true}
      />
    </div>
  );
}
