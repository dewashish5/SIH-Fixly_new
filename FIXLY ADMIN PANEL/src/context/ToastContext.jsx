import React, { createContext, useContext, useState, useCallback } from 'react';
import { CheckCircle2, AlertCircle, Info, X } from 'lucide-react';

const ToastContext = createContext(null);

export function ToastProvider({ children }) {
  const [toasts, setToasts] = useState([]);

  const showToast = useCallback((type, message, duration = 3500) => {
    const id = Date.now() + Math.random();
    const newToast = { id, type, message };
    
    setToasts((prev) => [...prev, newToast]);

    setTimeout(() => {
      setToasts((prev) => prev.filter((t) => t.id !== id));
    }, duration);
  }, []);

  const removeToast = useCallback((id) => {
    setToasts((prev) => prev.filter((t) => t.id !== id));
  }, []);

  return (
    <ToastContext.Provider value={{ showToast, removeToast }}>
      {children}
      
      {/* Toast Notification Stack */}
      <div
        style={{
          position: 'fixed',
          top: '20px',
          right: '24px',
          zIndex: 9999,
          display: 'flex',
          flexDirection: 'column',
          gap: '10px',
          pointerEvents: 'none',
        }}
      >
        {toasts.map((toast) => {
          const isSuccess = toast.type === 'success';
          const isError = toast.type === 'error';
          
          return (
            <div
              key={toast.id}
              style={{
                pointerEvents: 'auto',
                minWidth: '300px',
                maxWidth: '420px',
                backgroundColor: '#ffffff',
                borderRadius: '12px',
                padding: '12px 16px',
                boxShadow: '0 10px 30px rgba(0,0,0,0.12), 0 1px 3px rgba(0,0,0,0.06)',
                border: `1.5px solid ${isSuccess ? '#86efac' : isError ? '#fca5a5' : '#cbd5e1'}`,
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'space-between',
                gap: '12px',
                animation: 'fadeIn 0.2s ease',
              }}
            >
              <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                {isSuccess && <CheckCircle2 size={19} color="#15803d" strokeWidth={2.4} />}
                {isError && <AlertCircle size={19} color="#dc2626" strokeWidth={2.4} />}
                {!isSuccess && !isError && <Info size={19} color="#0284c7" strokeWidth={2.4} />}
                
                <span style={{ fontSize: '13px', fontWeight: '600', color: '#1e293b' }}>
                  {toast.message}
                </span>
              </div>

              <button
                onClick={() => removeToast(toast.id)}
                style={{
                  color: '#94a3b8',
                  padding: '2px',
                  borderRadius: '4px',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                }}
              >
                <X size={15} />
              </button>
            </div>
          );
        })}
      </div>
    </ToastContext.Provider>
  );
}

export function useToast() {
  const context = useContext(ToastContext);
  if (!context) {
    throw new Error('useToast must be used within a ToastProvider');
  }
  return context;
}
