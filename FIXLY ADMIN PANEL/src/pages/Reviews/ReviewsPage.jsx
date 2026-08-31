import React, { useState } from 'react';
import { useApp } from '../../context/AppContext';
import {
  Star,
  Search,
  Trash2,
  Filter,
  Eye,
  CheckCircle,
  ThumbsUp,
  MessageSquare
} from 'lucide-react';
import Badge from '../../components/common/Badge';
import ConfirmDialog from '../../components/common/ConfirmDialog';
import { reviewSummary } from '../../data/reviews';

export default function ReviewsPage() {
  const { reviews, deleteReview } = useApp();

  const [search, setSearch] = useState('');
  const [starFilter, setStarFilter] = useState('All');
  const [reviewToDelete, setReviewToDelete] = useState(null);

  const filtered = reviews.filter((r) => {
    const matchStar = starFilter === 'All' || r.rating === Number(starFilter);
    const matchSearch =
      r.customer.toLowerCase().includes(search.toLowerCase()) ||
      r.worker.toLowerCase().includes(search.toLowerCase()) ||
      r.service.toLowerCase().includes(search.toLowerCase()) ||
      r.comment.toLowerCase().includes(search.toLowerCase());
    return matchStar && matchSearch;
  });

  return (
    <div style={{ padding: '0 32px 32px 32px', animation: 'fadeIn 0.2s ease' }}>
      {/* Header */}
      <div style={{ marginBottom: '20px' }}>
        <h2 style={{ fontSize: '20px', fontWeight: '700', color: '#111827' }}>
          Customer Reviews & Satisfaction Index
        </h2>
        <p style={{ fontSize: '13px', color: '#64748b' }}>
          Real feedback from completed on-demand tasks, worker ratings, and community standards monitoring
        </p>
      </div>

      {/* Star Rating Breakdown Card */}
      <div
        style={{
          backgroundColor: '#ffffff',
          borderRadius: '16px',
          border: '1px solid var(--border-light)',
          padding: '24px',
          boxShadow: 'var(--shadow-card)',
          display: 'grid',
          gridTemplateColumns: '1fr 2fr',
          gap: '24px',
          alignItems: 'center',
          marginBottom: '20px',
        }}
      >
        {/* Left: Big Score */}
        <div style={{ textAlign: 'center', borderRight: '1px solid var(--border-light)', paddingRight: '20px' }}>
          <div style={{ fontSize: '48px', fontWeight: '800', color: '#15803d', lineHeight: '1' }}>
            {reviewSummary.averageRating}
          </div>
          <div style={{ display: 'flex', justifyContent: 'center', gap: '4px', margin: '8px 0' }}>
            {[1, 2, 3, 4, 5].map((s) => (
              <Star key={s} size={18} fill="#ca8a04" color="#ca8a04" />
            ))}
          </div>
          <div style={{ fontSize: '12.5px', color: '#64748b' }}>
            Based on <strong>{reviewSummary.totalReviews.toLocaleString()}</strong> verified ratings
          </div>
        </div>

        {/* Right: Star percentage bars */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '6px' }}>
          {[5, 4, 3, 2, 1].map((stars) => {
            const count = reviewSummary.stars[stars];
            const pct = Math.round((count / reviewSummary.totalReviews) * 100);
            return (
              <div key={stars} style={{ display: 'flex', alignItems: 'center', gap: '10px', fontSize: '12.5px' }}>
                <span style={{ width: '50px', fontWeight: '600', color: '#475569' }}>{stars} Stars</span>
                <div style={{ flex: 1, height: '8px', backgroundColor: '#e2ece5', borderRadius: '999px', overflow: 'hidden' }}>
                  <div style={{ width: `${pct}%`, height: '100%', backgroundColor: '#22864c', borderRadius: '999px' }} />
                </div>
                <span style={{ width: '40px', textAlign: 'right', fontWeight: '600', color: '#334155' }}>{pct}%</span>
              </div>
            );
          })}
        </div>
      </div>

      {/* Filter and Search Bar */}
      <div
        style={{
          backgroundColor: '#ffffff',
          padding: '12px 18px',
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
        <div style={{ display: 'flex', alignItems: 'center', gap: '8px', width: '280px' }}>
          <Search size={15} color="#94a3b8" />
          <input
            type="text"
            placeholder="Search review comment, customer, worker..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            style={{ border: 'none', outline: 'none', width: '100%', fontSize: '13px' }}
          />
        </div>

        <div style={{ display: 'flex', gap: '6px' }}>
          {['All', '5', '4', '3', '2', '1'].map((st) => (
            <button
              key={st}
              onClick={() => setStarFilter(st)}
              style={{
                padding: '6px 12px',
                borderRadius: '8px',
                fontSize: '12.5px',
                fontWeight: '600',
                backgroundColor: starFilter === st ? '#eaf7ee' : 'transparent',
                color: starFilter === st ? '#15803d' : '#64748b',
                border: `1px solid ${starFilter === st ? '#86efac' : 'transparent'}`,
              }}
            >
              {st === 'All' ? 'All Ratings' : `★ ${st}`}
            </button>
          ))}
        </div>
      </div>

      {/* Reviews Table */}
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
              <th style={{ padding: '14px 18px' }}>Customer</th>
              <th style={{ padding: '14px 18px' }}>Worker & Service</th>
              <th style={{ padding: '14px 18px' }}>Rating</th>
              <th style={{ padding: '14px 18px' }}>Customer Feedback Comment</th>
              <th style={{ padding: '14px 18px' }}>Date</th>
              <th style={{ padding: '14px 18px' }}>Status</th>
              <th style={{ padding: '14px 18px', textAlign: 'right' }}>Action</th>
            </tr>
          </thead>
          <tbody>
            {filtered.map((r) => (
              <tr key={r.id} style={{ borderBottom: '1px solid #f1f5f3', fontSize: '13px' }}>
                <td style={{ padding: '14px 18px', fontWeight: '700', color: '#1e293b' }}>
                  {r.customer}
                  <div style={{ fontSize: '11px', color: '#94a3b8' }}>Order: {r.bookingId}</div>
                </td>

                <td style={{ padding: '14px 18px' }}>
                  <div style={{ fontWeight: '600', color: '#1e293b' }}>{r.worker}</div>
                  <div style={{ fontSize: '11.5px', color: '#64748b' }}>{r.service}</div>
                </td>

                <td style={{ padding: '14px 18px', fontWeight: '700', color: '#ca8a04' }}>
                  ★ {r.rating} / 5
                </td>

                <td style={{ padding: '14px 18px', color: '#334155', maxWidth: '340px', lineHeight: '1.4' }}>
                  "{r.comment}"
                </td>

                <td style={{ padding: '14px 18px', color: '#64748b' }}>
                  {r.date}
                </td>

                <td style={{ padding: '14px 18px' }}>
                  <Badge status={r.status} />
                </td>

                <td style={{ padding: '14px 18px', textAlign: 'right' }}>
                  <button
                    onClick={() => setReviewToDelete(r)}
                    title="Delete Inappropriate Review"
                    style={{
                      padding: '6px 8px',
                      borderRadius: '6px',
                      backgroundColor: '#fef2f2',
                      color: '#dc2626',
                    }}
                  >
                    <Trash2 size={14} />
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* Delete Confirmation */}
      <ConfirmDialog
        isOpen={!!reviewToDelete}
        onClose={() => setReviewToDelete(null)}
        onConfirm={() => deleteReview(reviewToDelete.id)}
        title="Delete this Feedback?"
        message={`Are you sure you want to remove review #${reviewToDelete?.id} by ${reviewToDelete?.customer}?`}
        confirmText="Delete Review"
        isDestructive={true}
      />
    </div>
  );
}
