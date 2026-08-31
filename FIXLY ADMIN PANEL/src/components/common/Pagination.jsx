import React from 'react';
import { ChevronLeft, ChevronRight } from 'lucide-react';

export default function Pagination({
  currentPage = 1,
  totalItems = 0,
  pageSize = 10,
  onPageChange,
}) {
  const totalPages = Math.max(1, Math.ceil(totalItems / pageSize));
  const startItem = totalItems === 0 ? 0 : (currentPage - 1) * pageSize + 1;
  const endItem = Math.min(totalItems, currentPage * pageSize);

  const pageNumbers = [];
  for (let i = 1; i <= totalPages; i++) {
    pageNumbers.push(i);
  }

  return (
    <div
      style={{
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
        padding: '14px 20px',
        borderTop: '1px solid var(--border-light)',
        backgroundColor: '#ffffff',
        flexWrap: 'wrap',
        gap: '10px',
      }}
    >
      <div style={{ fontSize: '12.5px', color: '#64748b' }}>
        Showing <strong>{startItem}</strong> to <strong>{endItem}</strong> of{' '}
        <strong>{totalItems}</strong> entries
      </div>

      <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
        <button
          disabled={currentPage <= 1}
          onClick={() => onPageChange(currentPage - 1)}
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: '4px',
            padding: '6px 10px',
            borderRadius: '6px',
            border: '1px solid #e2e8f0',
            backgroundColor: currentPage <= 1 ? '#f8fafc' : '#ffffff',
            color: currentPage <= 1 ? '#cbd5e1' : '#334155',
            fontSize: '12px',
            fontWeight: '600',
            cursor: currentPage <= 1 ? 'not-allowed' : 'pointer',
          }}
        >
          <ChevronLeft size={14} />
          <span>Previous</span>
        </button>

        {pageNumbers.map((page) => (
          <button
            key={page}
            onClick={() => onPageChange(page)}
            style={{
              width: '32px',
              height: '32px',
              borderRadius: '6px',
              fontSize: '12px',
              fontWeight: page === currentPage ? '700' : '500',
              backgroundColor: page === currentPage ? 'var(--primary-brand)' : '#ffffff',
              color: page === currentPage ? '#ffffff' : '#334155',
              border: page === currentPage ? 'none' : '1px solid #e2e8f0',
            }}
          >
            {page}
          </button>
        ))}

        <button
          disabled={currentPage >= totalPages}
          onClick={() => onPageChange(currentPage + 1)}
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: '4px',
            padding: '6px 10px',
            borderRadius: '6px',
            border: '1px solid #e2e8f0',
            backgroundColor: currentPage >= totalPages ? '#f8fafc' : '#ffffff',
            color: currentPage >= totalPages ? '#cbd5e1' : '#334155',
            fontSize: '12px',
            fontWeight: '600',
            cursor: currentPage >= totalPages ? 'not-allowed' : 'pointer',
          }}
        >
          <span>Next</span>
          <ChevronRight size={14} />
        </button>
      </div>
    </div>
  );
}
