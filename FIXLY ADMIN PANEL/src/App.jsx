import React from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { ToastProvider } from './context/ToastContext';
import { LanguageProvider } from './context/LanguageContext';
import { AppProvider, useApp } from './context/AppContext';

import Layout from './components/layout/Layout';
import LoginPage from './pages/Auth/LoginPage';
import DashboardPage from './pages/Dashboard/DashboardPage';
import BookingsPage from './pages/Bookings/BookingsPage';
import WorkersPage from './pages/Workers/WorkersPage';
import WorkerDetailPage from './pages/Workers/WorkerDetailPage';
import ApprovalsPage from './pages/Approvals/ApprovalsPage';
import CustomersPage from './pages/Customers/CustomersPage';
import CustomerDetailPage from './pages/Customers/CustomerDetailPage';
import ServicesPage from './pages/Services/ServicesPage';
import PaymentsPage from './pages/Payments/PaymentsPage';
import InsurancePage from './pages/Insurance/InsurancePage';
import ReviewsPage from './pages/Reviews/ReviewsPage';
import ReportsPage from './pages/Reports/ReportsPage';
import AnalyticsPage from './pages/Analytics/AnalyticsPage';
import AIInsightsPage from './pages/AIInsights/AIInsightsPage';
import NotificationsPage from './pages/Notifications/NotificationsPage';
import SupportPage from './pages/Support/SupportPage';
import SettingsPage from './pages/Settings/SettingsPage';
import FederationsPage from './pages/Federations/FederationsPage';
import FederationDetailPage from './pages/Federations/FederationDetailPage';
import LanguageControlPage from './pages/LanguageControl/LanguageControlPage';
import NotFoundPage from './pages/NotFound/NotFoundPage';
import ThemeShowcase from './pages/ThemeShowcase/ThemeShowcase';

function ProtectedRoute({ children }) {
  const { isAuthenticated } = useApp();
  if (!isAuthenticated) {
    return <Navigate to="/login" replace />;
  }
  return children;
}

export default function App() {
  return (
    <ToastProvider>
      <LanguageProvider>
        <AppProvider>
          <BrowserRouter>
            <Routes>
              {/* Public Login Route */}
              <Route path="/login" element={<LoginPage />} />

              {/* Protected Admin Routes */}
              <Route
                path="/"
                element={
                  <ProtectedRoute>
                    <Layout />
                  </ProtectedRoute>
                }
              >
                <Route index element={<Navigate to="/dashboard" replace />} />
                <Route path="dashboard" element={<DashboardPage />} />
                <Route path="bookings" element={<BookingsPage />} />
                <Route path="workers" element={<WorkersPage />} />
                <Route path="workers/:id" element={<WorkerDetailPage />} />
                <Route path="approvals" element={<ApprovalsPage />} />
                <Route path="customers" element={<CustomersPage />} />
                <Route path="customers/:id" element={<CustomerDetailPage />} />
                <Route path="services" element={<ServicesPage />} />
                <Route path="payments" element={<PaymentsPage />} />
                <Route path="insurance" element={<InsurancePage />} />
                <Route path="reviews" element={<ReviewsPage />} />
                <Route path="reports" element={<ReportsPage />} />
                <Route path="analytics" element={<AnalyticsPage />} />
                <Route path="ai-insights" element={<AIInsightsPage />} />
                <Route path="notifications" element={<NotificationsPage />} />
                <Route path="support" element={<SupportPage />} />
                <Route path="settings" element={<SettingsPage />} />
                <Route path="federations" element={<FederationsPage />} />
                <Route path="federations/:id" element={<FederationDetailPage />} />
                <Route path="language-control" element={<LanguageControlPage />} />
                <Route path="theme" element={<ThemeShowcase />} />
                <Route path="*" element={<NotFoundPage />} />
              </Route>
            </Routes>
          </BrowserRouter>
        </AppProvider>
      </LanguageProvider>
    </ToastProvider>
  );
}
