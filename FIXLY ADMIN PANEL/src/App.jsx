import React from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { ToastProvider } from './context/ToastContext';
import { LanguageProvider } from './context/LanguageContext';
import { AppProvider } from './context/AppContext';

import Layout from './components/layout/Layout';
import DashboardPage from './pages/Dashboard/DashboardPage';
import BookingsPage from './pages/Bookings/BookingsPage';
import WorkersPage from './pages/Workers/WorkersPage';
import WorkerDetailPage from './pages/Workers/WorkerDetailPage';
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
import SettingsPage from './pages/Settings/SettingsPage';
import NotFoundPage from './pages/NotFound/NotFoundPage';
import ThemeShowcase from './pages/ThemeShowcase/ThemeShowcase';

export default function App() {
  return (
    <ToastProvider>
      <LanguageProvider>
        <AppProvider>
          <BrowserRouter>
            <Routes>
              <Route path="/" element={<Layout />}>
                <Route index element={<Navigate to="/dashboard" replace />} />
                <Route path="dashboard" element={<DashboardPage />} />
                <Route path="bookings" element={<BookingsPage />} />
                <Route path="workers" element={<WorkersPage />} />
                <Route path="workers/:id" element={<WorkerDetailPage />} />
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
                <Route path="settings" element={<SettingsPage />} />
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
