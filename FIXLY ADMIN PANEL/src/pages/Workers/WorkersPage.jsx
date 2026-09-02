import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useApp } from '../../context/AppContext';
import {
  Users,
  Search,
  Plus,
  Filter,
  ShieldCheck,
  Star,
  MapPin,
  CheckCircle,
  XCircle,
  Ban,
  Eye,
  ArrowUpDown,
  Phone,
  Battery
} from 'lucide-react';
import Badge from '../../components/common/Badge';
import Pagination from '../../components/common/Pagination';
import AddWorkerModal from '../../components/modals/AddWorkerModal';
import WorkersLeafletMap from '../../components/map/WorkersLeafletMap';

export default function WorkersPage() {
  const navigate = useNavigate();
  const { workers, workersPagination, fetchWorkers, verifyWorker, rejectWorker, suspendWorker } = useApp();

  // Search & Filter states
  const [search, setSearch] = useState('');
  const [serviceFilter, setServiceFilter] = useState('All');
  const [verificationFilter, setVerificationFilter] = useState('All');
  const [availabilityFilter, setAvailabilityFilter] = useState('All');
  const [cityFilter, setCityFilter] = useState('All');
  const [sortField, setSortField] = useState('rating');
  const [sortAsc, setSortAsc] = useState(false);
  const [currentPage, setCurrentPage] = useState(1);
  const [showMapRadar, setShowMapRadar] = useState(false);
  const [isAddWorkerOpen, setIsAddWorkerOpen] = useState(false);
  const pageSize = 10;

  React.useEffect(() => {
    fetchWorkers({
      page: currentPage,
      limit: pageSize,
      search,
      category: serviceFilter !== 'All' ? serviceFilter : '',
      isVerified: verificationFilter === 'Verified' ? 'true' : (verificationFilter === 'Pending' ? 'false' : '')
    });
  }, [fetchWorkers, currentPage, search, serviceFilter, verificationFilter]);

  let filtered = [...workers];

  // Category / Skill Filter
  if (serviceFilter && serviceFilter !== 'All' && serviceFilter !== 'All Services') {
    const sTerm = serviceFilter.toLowerCase();
    filtered = filtered.filter((w) => {
      const skills = Array.isArray(w.skills) ? w.skills.join(' ').toLowerCase() : '';
      const cat = (w.category || w.primarySkill || '').toLowerCase();
      return skills.includes(sTerm) || cat.includes(sTerm);
    });
  }

  // Search Filter
  if (search && search.trim() !== '') {
    const q = search.toLowerCase().trim();
    filtered = filtered.filter((w) => {
      const name = (w.name || w.fullName || '').toLowerCase();
      const phone = (w.phone || w.phoneNumber || '').toLowerCase();
      const cat = (w.category || w.primarySkill || '').toLowerCase();
      return name.includes(q) || phone.includes(q) || cat.includes(q);
    });
  }

  // Verification Filter
  if (verificationFilter && verificationFilter !== 'All') {
    filtered = filtered.filter((w) => {
      if (verificationFilter === 'Verified') return w.isVerified || w.status === 'VERIFIED';
      if (verificationFilter === 'Pending') return !w.isVerified && w.status !== 'REJECTED' && w.status !== 'SUSPENDED';
      if (verificationFilter === 'Rejected') return w.status === 'REJECTED';
      if (verificationFilter === 'Suspended') return w.status === 'SUSPENDED';
      return true;
    });
  }

  // City Filter
  if (cityFilter && cityFilter !== 'All' && cityFilter !== 'All Cities') {
    const cTerm = cityFilter.toLowerCase();
    filtered = filtered.filter((w) => {
      const city = (w.city || w.location?.city || w.locationName || w.address?.city || '').toLowerCase();
      const locStr = (typeof w.location === 'string' ? w.location : JSON.stringify(w.location || {})).toLowerCase();
      return city.includes(cTerm) || locStr.includes(cTerm);
    });
  }

  // Availability Filter
  if (availabilityFilter && availabilityFilter !== 'All') {
    filtered = filtered.filter((w) => {
      if (availabilityFilter === 'Active') return w.isAvailable || w.status === 'ACTIVE';
      if (availabilityFilter === 'On Job') return w.status === 'ON_JOB';
      if (availabilityFilter === 'Offline') return !w.isAvailable || w.status === 'OFFLINE';
      return true;
    });
  }

  // Sort logic
  filtered.sort((a, b) => {
    let valA = a[sortField] || '';
    let valB = b[sortField] || '';
    if (valA < valB) return sortAsc ? -1 : 1;
    if (valA > valB) return sortAsc ? 1 : -1;
    return 0;
  });

  const paginated = filtered;

  const toggleSort = (field) => {
    if (sortField === field) {
      setSortAsc(!sortAsc);
    } else {
      setSortField(field);
      setSortAsc(false);
    }
  };

  return (
    <div style={{ padding: '0 32px 32px 32px', animation: 'fadeIn 0.2s ease' }}>
      {/* Page Header */}
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
            Gig Workers & Cooperative Members ({workers.length})
          </h2>
          <p style={{ fontSize: '13px', color: '#64748b' }}>
            Member verification, skill profiling, telemetry tracking, and welfare status
          </p>
        </div>

        <div style={{ display: 'flex', gap: '10px' }}>
          <button
            onClick={() => setShowMapRadar(!showMapRadar)}
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '6px',
              padding: '9px 14px',
              backgroundColor: showMapRadar ? '#eaf7ee' : '#ffffff',
              color: showMapRadar ? '#15803d' : '#334155',
              border: `1px solid ${showMapRadar ? '#86efac' : 'var(--border-light)'}`,
              borderRadius: '8px',
              fontSize: '13px',
              fontWeight: '600',
            }}
          >
            <MapPin size={15} />
            <span>{showMapRadar ? 'Hide GPS Map Radar' : 'Live GPS Map Radar'}</span>
          </button>

          <button
            onClick={() => setIsAddWorkerOpen(true)}
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
            <span>Onboard Member</span>
          </button>
        </div>
      </div>

      {/* Map Radar collapsible section */}
      {showMapRadar && (
        <div style={{ marginBottom: '20px', animation: 'fadeIn 0.2s ease' }}>
          <WorkersLeafletMap height="360px" selectedService={serviceFilter} />
        </div>
      )}

      {/* Filters Bar */}
      <div
        style={{
          backgroundColor: '#ffffff',
          padding: '14px 18px',
          borderRadius: '12px',
          border: '1px solid var(--border-light)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          marginBottom: '16px',
          gap: '12px',
          flexWrap: 'wrap',
        }}
      >
        {/* Search */}
        <div
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: '8px',
            backgroundColor: '#f8fafc',
            border: '1px solid #e2e8f0',
            borderRadius: '8px',
            padding: '7px 12px',
            width: '260px',
          }}
        >
          <Search size={15} color="#94a3b8" />
          <input
            type="text"
            placeholder="Search worker, skill, trade..."
            value={search}
            onChange={(e) => {
              setSearch(e.target.value);
              setCurrentPage(1);
            }}
            style={{ border: 'none', outline: 'none', backgroundColor: 'transparent', width: '100%', fontSize: '13px' }}
          />
        </div>

        {/* Dropdown Filters */}
        <div style={{ display: 'flex', gap: '8px', flexWrap: 'wrap' }}>
          {/* Service filter */}
          <select
            value={serviceFilter}
            onChange={(e) => {
              setServiceFilter(e.target.value);
              setCurrentPage(1);
            }}
            style={{
              padding: '7px 10px',
              borderRadius: '8px',
              border: '1px solid #cbd5e1',
              fontSize: '12.5px',
              fontWeight: '600',
              backgroundColor: '#ffffff',
            }}
          >
            <option value="All">All Trades</option>
            <option value="Plumbing">Plumbing</option>
            <option value="Electrical">Electrical</option>
            <option value="Carpentry">Carpentry</option>
            <option value="Cleaning">Cleaning</option>
            <option value="AC Repair">AC Repair</option>
            <option value="Caregiving">Caregiving</option>
            <option value="Painting">Painting</option>
            <option value="Driving">Driving</option>
          </select>

          {/* Verification filter */}
          <select
            value={verificationFilter}
            onChange={(e) => {
              setVerificationFilter(e.target.value);
              setCurrentPage(1);
            }}
            style={{
              padding: '7px 10px',
              borderRadius: '8px',
              border: '1px solid #cbd5e1',
              fontSize: '12.5px',
              fontWeight: '600',
              backgroundColor: '#ffffff',
            }}
          >
            <option value="All">All Verification</option>
            <option value="Verified">Verified</option>
            <option value="Pending">Pending Review</option>
            <option value="Rejected">Rejected</option>
            <option value="Suspended">Suspended</option>
          </select>

          {/* City filter */}
          <select
            value={cityFilter}
            onChange={(e) => {
              setCityFilter(e.target.value);
              setCurrentPage(1);
            }}
            style={{
              padding: '7px 10px',
              borderRadius: '8px',
              border: '1px solid #cbd5e1',
              fontSize: '12.5px',
              fontWeight: '600',
              backgroundColor: '#ffffff',
            }}
          >
            <option value="All">All Cities</option>
            <option value="Noida">Noida</option>
            <option value="New Delhi">New Delhi</option>
            <option value="Gurgaon">Gurgaon</option>
            <option value="Ghaziabad">Ghaziabad</option>
            <option value="Mumbai">Mumbai</option>
            <option value="Pune">Pune</option>
          </select>
        </div>
      </div>

      {/* Workers Table */}
      <div
        style={{
          backgroundColor: '#ffffff',
          borderRadius: '14px',
          border: '1px solid var(--border-light)',
          overflow: 'hidden',
          boxShadow: 'var(--shadow-card)',
        }}
      >
        <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left' }}>
          <thead>
            <tr style={{ backgroundColor: '#f8faf9', borderBottom: '1px solid #e6ede8', color: '#55695e', fontSize: '12px', fontWeight: '700' }}>
              <th style={{ padding: '14px 18px' }}>Profile & Name</th>
              <th style={{ padding: '14px 18px' }}>Trade & Skills</th>
              <th style={{ padding: '14px 18px' }}>Location</th>
              <th onClick={() => toggleSort('rating')} style={{ padding: '14px 18px', cursor: 'pointer' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '4px' }}>
                  <span>Rating</span>
                  <ArrowUpDown size={12} />
                </div>
              </th>
              <th onClick={() => toggleSort('completedJobs')} style={{ padding: '14px 18px', cursor: 'pointer' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '4px' }}>
                  <span>Jobs Completed</span>
                  <ArrowUpDown size={12} />
                </div>
              </th>
              <th style={{ padding: '14px 18px' }}>Availability</th>
              <th style={{ padding: '14px 18px' }}>Verification</th>
              <th style={{ padding: '14px 18px', textAlign: 'right' }}>Actions</th>
            </tr>
          </thead>
          <tbody>
            {paginated.map((w) => (
              <tr key={w.id} style={{ borderBottom: '1px solid #f1f5f3', fontSize: '13px' }}>
                {/* Profile & Name */}
                <td style={{ padding: '14px 18px' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                    <img
                      src={w.avatar || 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=120&auto=format&fit=crop&q=80'}
                      alt={w.name}
                      style={{ width: '38px', height: '38px', borderRadius: '50%', objectFit: 'cover', border: '1.5px solid #22c55e' }}
                    />
                    <div>
                      <div
                        onClick={() => navigate(`/workers/${w.id}`)}
                        style={{ fontWeight: '700', color: 'var(--text-link)', cursor: 'pointer' }}
                      >
                        {w.name}
                      </div>
                      <div style={{ fontSize: '11px', color: '#64748b' }}>{w.id} • {w.phone}</div>
                    </div>
                  </div>
                </td>

                {/* Trade & Skills */}
                <td style={{ padding: '14px 18px' }}>
                  <div style={{ fontWeight: '700', color: '#1e293b' }}>{w.service || w.category}</div>
                  <div style={{ fontSize: '11.5px', color: '#64748b', maxWidth: '180px', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                    {Array.isArray(w.skills) ? w.skills.join(', ') : (w.category || 'General')}
                  </div>
                </td>

                {/* Location */}
                <td style={{ padding: '14px 18px', color: '#475569' }}>
                  <div>{w.location || 'Sector 62'}</div>
                  <div style={{ fontSize: '11px', color: '#94a3b8' }}>City: {w.city || 'Noida'}</div>
                </td>

                {/* Rating */}
                <td style={{ padding: '14px 18px', fontWeight: '700', color: '#15803d' }}>
                  ★ {w.rating}
                  <div style={{ fontSize: '11px', color: '#64748b', fontWeight: '400' }}>({w.totalReviews} revs)</div>
                </td>

                {/* Completed Jobs */}
                <td style={{ padding: '14px 18px', fontWeight: '700', color: '#0f172a' }}>
                  {w.completedJobs} tasks
                  <div style={{ fontSize: '11px', color: '#15803d' }}>{w.todayEarnings} today</div>
                </td>

                {/* Availability */}
                <td style={{ padding: '14px 18px' }}>
                  <Badge status={w.availability} />
                </td>

                {/* Verification */}
                <td style={{ padding: '14px 18px' }}>
                  <Badge status={w.verification} />
                </td>

                {/* Actions */}
                <td style={{ padding: '14px 18px', textAlign: 'right' }}>
                  <div style={{ display: 'flex', gap: '6px', justifyContent: 'flex-end' }}>
                    <button
                      onClick={() => navigate(`/workers/${w.rawId || w._id || w.id}`)}
                      title="View & Edit Worker Profile"
                      style={{
                        padding: '6px 8px',
                        backgroundColor: '#f1f8f3',
                        color: '#15803d',
                        borderRadius: '6px',
                        fontSize: '12px',
                      }}
                    >
                      <Eye size={14} />
                    </button>

                    {w.verification !== 'Verified' && (
                      <button
                        onClick={() => verifyWorker(w.id)}
                        title="Approve & Verify Member"
                        style={{
                          padding: '6px 8px',
                          backgroundColor: '#eaf8ef',
                          color: '#15803d',
                          borderRadius: '6px',
                          fontSize: '12px',
                        }}
                      >
                        <CheckCircle size={14} />
                      </button>
                    )}

                    {w.verification === 'Pending' && (
                      <button
                        onClick={() => rejectWorker(w.id)}
                        title="Reject Verification"
                        style={{
                          padding: '6px 8px',
                          backgroundColor: '#fef2f2',
                          color: '#dc2626',
                          borderRadius: '6px',
                          fontSize: '12px',
                        }}
                      >
                        <XCircle size={14} />
                      </button>
                    )}

                    {w.verification === 'Verified' && (
                      <button
                        onClick={() => suspendWorker(w.id)}
                        title="Suspend Account"
                        style={{
                          padding: '6px 8px',
                          backgroundColor: '#fef2f2',
                          color: '#dc2626',
                          borderRadius: '6px',
                          fontSize: '12px',
                        }}
                      >
                        <Ban size={14} />
                      </button>
                    )}
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>

        {/* Pagination */}
        <Pagination
          currentPage={currentPage}
          totalItems={workersPagination?.total || filtered.length}
          pageSize={pageSize}
          onPageChange={(p) => setCurrentPage(p)}
        />
      </div>

      <AddWorkerModal isOpen={isAddWorkerOpen} onClose={() => setIsAddWorkerOpen(false)} />
    </div>
  );
}
