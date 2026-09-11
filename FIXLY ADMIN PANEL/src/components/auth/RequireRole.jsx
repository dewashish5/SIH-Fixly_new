import { Navigate } from 'react-router-dom';
import { useApp } from '../../context/AppContext';

/** Block route unless adminRole matches (default: super_admin). */
export default function RequireRole({ role = 'super_admin', children }) {
  const { isAuthenticated, adminRole } = useApp();
  if (!isAuthenticated) return <Navigate to="/login" replace />;
  if (adminRole !== role) return <Navigate to="/dashboard" replace />;
  return children;
}

export function isSuperAdmin(adminRole) {
  return adminRole === 'super_admin';
}

export function isFederationAdmin(adminRole) {
  return adminRole === 'federation_admin';
}
