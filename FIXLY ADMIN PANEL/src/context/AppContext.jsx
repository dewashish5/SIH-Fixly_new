import React, { createContext, useContext, useState, useEffect, useCallback } from 'react';
import { api } from '../services/api';
import { useToast } from './ToastContext';

const AppContext = createContext(null);

export function AppProvider({ children }) {
  const { showToast } = useToast();

  // Auth State
  const [token, setToken] = useState(() => sessionStorage.getItem('adminToken') || null);
  const [adminUser, setAdminUser] = useState(() => {
    const savedSession = sessionStorage.getItem('adminUser');
    if (savedSession) {
      try { return JSON.parse(savedSession); } catch (_) {}
    }
    const savedLocal = localStorage.getItem('adminUser');
    if (savedLocal) {
      try { return JSON.parse(savedLocal); } catch (_) {}
    }
    return null;
  });

  // Entity Data States
  const [dashboardStats, setDashboardStats] = useState(null);
  const [recentBookings, setRecentBookings] = useState([]);
  const [topServices, setTopServices] = useState([]);

  const [customers, setCustomers] = useState([]);
  const [customersPagination, setCustomersPagination] = useState({ page: 1, limit: 10, total: 0, totalPages: 1 });

  const [workers, setWorkers] = useState([]);
  const [workersPagination, setWorkersPagination] = useState({ page: 1, limit: 10, total: 0, totalPages: 1 });

  const [bookings, setBookings] = useState([]);
  const [bookingsPagination, setBookingsPagination] = useState({ page: 1, limit: 10, total: 0, totalPages: 1 });

  const [services, setServices] = useState([]);
  const [servicesPagination, setServicesPagination] = useState({ page: 1, limit: 10, total: 0, totalPages: 1 });

  const [payments, setPayments] = useState([]);
  const [paymentsPagination, setPaymentsPagination] = useState({ page: 1, limit: 10, total: 0, totalPages: 1 });
  const [paymentStats, setPaymentStats] = useState(null);

  const [reviews, setReviews] = useState([]);
  const [reviewsPagination, setReviewsPagination] = useState({ page: 1, limit: 10, total: 0, totalPages: 1 });
  const [ratingStats, setRatingStats] = useState(null);

  const [insurancePolicies, setInsurancePolicies] = useState([]);
  const [welfareClaims, setWelfareClaims] = useState([]);

  const [notifications, setNotifications] = useState([]);
  const [settings, setSettings] = useState({
    platformCommissionPercent: 5,
    cooperativeWelfarePercent: 5,
    autoDispatchEnabled: true,
    emergencyHotline: '+91 98765 43210',
    emailNotifications: true,
    smsAlerts: true,
    payoutSchedule: 'Instant Automated UPI',
    twoFactorAuth: false
  });
  const [analytics, setAnalytics] = useState(null);
  const [aiInsights, setAiInsights] = useState([]);

  const [loading, setLoading] = useState(false);
  const [selectedDateRange, setSelectedDateRange] = useState('Today');

  // --- AUTH ACTIONS ---
  const loginAdmin = async (email, password) => {
    try {
      const res = await api.login(email, password);
      if (res && res.success) {
        setToken(res.token);
        setAdminUser(res.user);
        sessionStorage.setItem('adminToken', res.token);
        sessionStorage.setItem('adminUser', JSON.stringify(res.user));
        localStorage.setItem('adminUser', JSON.stringify(res.user));
        return res;
      }
      return res;
    } catch (error) {
      throw error;
    }
  };

  const logoutAdmin = () => {
    setToken(null);
    setAdminUser(null);
    sessionStorage.removeItem('adminToken');
    sessionStorage.removeItem('adminUser');
    localStorage.removeItem('adminUser');
    showToast('info', 'Logged out successfully');
    window.location.href = '/login';
  };

  const updateAdminProfile = async (profileData) => {
    try {
      const res = await api.updateProfile(profileData);
      if (res && res.success && res.user) {
        setAdminUser(res.user);
        sessionStorage.setItem('adminUser', JSON.stringify(res.user));
        localStorage.setItem('adminUser', JSON.stringify(res.user));
        showToast('success', res.message || 'Profile updated successfully!');
        return res;
      }
    } catch (err) {
      console.warn('Backend updateProfile failed, saving locally:', err);
    }
    const updatedUser = { ...(adminUser || {}), ...profileData };
    setAdminUser(updatedUser);
    sessionStorage.setItem('adminUser', JSON.stringify(updatedUser));
    localStorage.setItem('adminUser', JSON.stringify(updatedUser));
    showToast('success', 'Profile updated successfully');
    return { success: true, user: updatedUser };
  };

  // --- DASHBOARD ACTIONS ---
  const fetchDashboardStats = useCallback(async () => {
    try {
      setLoading(true);
      const res = await api.getDashboardStats();
      if (res.success) {
        setDashboardStats(res.stats);
        setRecentBookings(res.recentBookings || []);
        setTopServices(res.topServices || []);
      }
    } catch (err) {
      console.error('Error fetching dashboard stats:', err);
    } finally {
      setLoading(false);
    }
  }, []);

  // --- CUSTOMERS ACTIONS ---
  const fetchCustomers = useCallback(async (params = {}) => {
    try {
      setLoading(true);
      const res = await api.getCustomers(params);
      if (res.success) {
        const formatted = res.data.map(c => ({
          id: c._id,
          name: c.name,
          email: c.email,
          phone: c.phone || 'N/A',
          address: c.savedAddresses?.[0]?.addressLine || 'No address provided',
          totalBookings: c.totalBookings || 0,
          totalSpent: `₹${c.totalSpent || 0}`,
          rawSpent: c.totalSpent || 0,
          rating: 4.8,
          status: c.isVerified ? 'Active' : 'Blocked',
          isVerified: c.isVerified,
          memberSince: new Date(c.createdAt).toLocaleDateString('en-IN', { month: 'short', year: 'numeric' })
        }));
        setCustomers(formatted);
        setCustomersPagination(res.pagination || { page: 1, limit: 10, total: formatted.length, totalPages: 1 });
      }
    } catch (err) {
      console.error('Error fetching customers:', err);
    } finally {
      setLoading(false);
    }
  }, []);

  const toggleCustomerBlock = async (customerId, currentVerifiedState) => {
    try {
      const newStatus = !currentVerifiedState;
      const res = await api.toggleCustomerStatus(customerId, newStatus);
      if (res.success) {
        showToast('success', `Customer status updated to ${newStatus ? 'Active' : 'Blocked'}`);
        fetchCustomers({ page: customersPagination.page, limit: customersPagination.limit });
      }
    } catch (err) {
      showToast('error', err.response?.data?.message || 'Failed to update customer status');
    }
  };

  // --- WORKERS ACTIONS ---
  const fetchWorkers = useCallback(async (params = {}) => {
    try {
      setLoading(true);
      const res = await api.getWorkers(params);
      if (res.success) {
        const formatted = res.data.map(w => ({
          id: w._id,
          name: w.name,
          email: w.email,
          phone: w.phone || 'N/A',
          avatar: w.avatar || '',
          category: w.workerProfile?.category || 'General',
          service: w.workerProfile?.category || 'General',
          skills: Array.isArray(w.workerProfile?.skills) && w.workerProfile.skills.length > 0 
            ? w.workerProfile.skills 
            : [w.workerProfile?.category || 'General Service'],
          location: w.savedAddresses?.[0]?.addressLine || 'Sector 62, Noida',
          city: w.savedAddresses?.[0]?.city || 'Noida',
          hourlyRate: `₹${w.workerProfile?.hourlyRate || 50}/hr`,
          verification: w.isVerified ? 'Verified' : 'Pending',
          isVerified: w.isVerified,
          rating: w.workerProfile?.rating || 5.0,
          totalReviews: w.workerProfile?.totalJobs || 0,
          completedJobs: w.workerProfile?.totalJobs || 0,
          todayEarnings: '₹0',
          availability: 'Available',
          badges: w.workerProfile?.badges || ['Verified Worker'],
          joinedDate: new Date(w.createdAt).toLocaleDateString('en-IN', { month: 'short', year: 'numeric' })
        }));
        setWorkers(formatted);
        setWorkersPagination(res.pagination || { page: 1, limit: 10, total: formatted.length, totalPages: 1 });
      }
    } catch (err) {
      console.error('Error fetching workers:', err);
    } finally {
      setLoading(false);
    }
  }, []);

  const verifyWorker = async (workerId) => {
    try {
      const res = await api.updateWorkerStatus(workerId, { isVerified: true, badges: ['Background Checked', 'Verified Worker'] });
      if (res.success) {
        showToast('success', 'Worker application verified successfully');
        fetchWorkers({ page: workersPagination.page, limit: workersPagination.limit });
      }
    } catch (err) {
      showToast('error', err.response?.data?.message || 'Failed to verify worker');
    }
  };

  const rejectWorker = async (workerId) => {
    try {
      const res = await api.updateWorkerStatus(workerId, { isVerified: false });
      if (res.success) {
        showToast('error', 'Worker application rejected/suspended');
        fetchWorkers({ page: workersPagination.page, limit: workersPagination.limit });
      }
    } catch (err) {
      showToast('error', err.response?.data?.message || 'Failed to update worker status');
    }
  };

  const addWorker = async (workerData) => {
    try {
      const res = await api.addWorker(workerData);
      if (res.success) {
        showToast('success', `Worker ${res.worker.name} onboarded successfully!`);
        fetchWorkers({ page: 1, limit: workersPagination.limit });
        return res;
      }
    } catch (err) {
      showToast('error', err.response?.data?.message || 'Failed to add worker');
      throw err;
    }
  };

  const updateWorker = async (workerId, workerData) => {
    try {
      const res = await api.updateWorker(workerId, workerData);
      if (res.success) {
        showToast('success', res.message || 'Worker profile updated successfully!');
        fetchWorkers({ page: workersPagination.page, limit: workersPagination.limit });
        return res;
      }
    } catch (err) {
      showToast('error', err.response?.data?.message || 'Failed to update worker profile');
      throw err;
    }
  };

  // --- BOOKINGS ACTIONS ---
  const fetchBookings = useCallback(async (params = {}) => {
    try {
      setLoading(true);
      const res = await api.getBookings(params);
      if (res.success) {
        const formatted = res.data.map(b => ({
          id: b._id,
          bookingId: b.bookingId,
          customer: b.customer?.name || 'Customer',
          customerId: b.customer?._id,
          customerPhone: b.customer?.phone || 'N/A',
          worker: b.worker?.name || 'Unassigned',
          workerId: b.worker?._id,
          workerPhone: b.worker?.phone || 'N/A',
          service: b.service?.title || 'Home Service',
          serviceCategory: b.service?.category || 'General',
          amount: `₹${b.invoice?.totalAmount || b.service?.basePrice || 0}`,
          rawAmount: b.invoice?.totalAmount || b.service?.basePrice || 0,
          status: b.status,
          date: new Date(b.createdAt).toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' }),
          scheduledSlot: b.scheduledTime ? new Date(b.scheduledTime).toLocaleString('en-IN') : 'Standard Slot',
          address: b.serviceAddress?.addressLine || 'Client Location'
        }));
        setBookings(formatted);
        setBookingsPagination(res.pagination || { page: 1, limit: 10, total: formatted.length, totalPages: 1 });
      }
    } catch (err) {
      console.error('Error fetching bookings:', err);
    } finally {
      setLoading(false);
    }
  }, []);

  const assignWorkerToBooking = async (bookingId, workerId) => {
    try {
      const res = await api.assignWorkerToBooking(bookingId, workerId);
      if (res.success) {
        showToast('success', `Worker assigned successfully to booking!`);
        fetchBookings({ page: bookingsPagination.page, limit: bookingsPagination.limit });
      }
    } catch (err) {
      showToast('error', err.response?.data?.message || 'Failed to assign worker');
    }
  };

  const updateBookingStatus = async (bookingId, status) => {
    try {
      const res = await api.updateBookingStatus(bookingId, { status });
      if (res.success) {
        showToast('success', `Booking status changed to ${status}`);
        fetchBookings({ page: bookingsPagination.page, limit: bookingsPagination.limit });
      }
    } catch (err) {
      showToast('error', err.response?.data?.message || 'Failed to update booking status');
    }
  };

  // --- SERVICES ACTIONS ---
  const fetchServices = useCallback(async (params = {}) => {
    try {
      setLoading(true);
      const res = await api.getServices(params);
      if (res.success) {
        const formatted = res.data.map(s => ({
          id: s._id,
          name: s.title,
          category: s.category,
          basePrice: `₹${s.basePrice}`,
          rawPrice: s.basePrice,
          estimatedTime: s.estimatedTime || '1 Hour',
          whatsIncluded: s.whatsIncluded || [],
          isActive: s.isActive,
          icon: 'Layers'
        }));
        setServices(formatted);
        setServicesPagination(res.pagination || { page: 1, limit: 10, total: formatted.length, totalPages: 1 });
      }
    } catch (err) {
      console.error('Error fetching services:', err);
    } finally {
      setLoading(false);
    }
  }, []);

  const addService = async (serviceData) => {
    try {
      const res = await api.createService(serviceData);
      if (res.success) {
        showToast('success', `Service "${serviceData.title}" created successfully!`);
        fetchServices({ page: 1, limit: servicesPagination.limit });
      }
    } catch (err) {
      showToast('error', err.response?.data?.message || 'Failed to create service');
    }
  };

  const updateService = async (id, serviceData) => {
    try {
      const res = await api.updateService(id, serviceData);
      if (res.success) {
        showToast('success', `Service updated successfully!`);
        fetchServices({ page: servicesPagination.page, limit: servicesPagination.limit });
      }
    } catch (err) {
      showToast('error', err.response?.data?.message || 'Failed to update service');
    }
  };

  const deleteService = async (id) => {
    try {
      const res = await api.deleteService(id);
      if (res.success) {
        showToast('error', `Service deleted successfully`);
        fetchServices({ page: servicesPagination.page, limit: servicesPagination.limit });
      }
    } catch (err) {
      showToast('error', err.response?.data?.message || 'Failed to delete service');
    }
  };

  // --- PAYMENTS ACTIONS ---
  const fetchPayments = useCallback(async (params = {}) => {
    try {
      setLoading(true);
      const res = await api.getPayments(params);
      if (res.success) {
        const formatted = res.data.map(p => ({
          id: p.paymentId || p.orderId || p._id,
          rawId: p._id,
          orderId: p.orderId,
          paymentId: p.paymentId || 'N/A',
          customer: p.customerId?.name || 'Customer',
          worker: p.workerId?.name || 'Worker',
          bookingId: p.bookingId?.bookingId || p.bookingId?._id || 'Booking',
          amount: `₹${p.amount}`,
          rawAmount: p.amount,
          welfareCut: `₹${Math.round(p.amount * 0.05)}`,
          workerPayout: `₹${Math.round(p.amount * 0.95)}`,
          status: p.status === 'success' ? 'Completed' : (p.status === 'failed' ? 'Failed' : 'Pending'),
          paymentMethod: p.paymentMethod || 'Razorpay',
          date: new Date(p.createdAt).toLocaleDateString('en-IN')
        }));
        setPayments(formatted);
        setPaymentsPagination(res.pagination || { page: 1, limit: 10, total: formatted.length, totalPages: 1 });
      }

      const statsRes = await api.getPaymentStats();
      if (statsRes.success) {
        setPaymentStats(statsRes.stats);
      }
    } catch (err) {
      console.error('Error fetching payments:', err);
    } finally {
      setLoading(false);
    }
  }, []);

  // --- REVIEWS ACTIONS ---
  const fetchReviews = useCallback(async (params = {}) => {
    try {
      setLoading(true);
      const res = await api.getReviews(params);
      if (res.success) {
        const formatted = res.data.map(r => ({
          id: r._id,
          customer: r.customer?.name || 'Customer',
          customerName: r.customer?.name || 'Customer',
          worker: r.worker?.name || 'Worker',
          workerName: r.worker?.name || 'Worker',
          service: r.booking?.service?.title || 'Gig Service',
          bookingId: r.booking?.bookingId || 'Booking',
          rating: r.rating || 5,
          comment: r.feedback || 'Great service experience',
          feedback: r.feedback || 'Great service experience',
          status: 'Published',
          date: new Date(r.createdAt).toLocaleDateString('en-IN')
        }));
        setReviews(formatted);
        if (res.ratingStats) {
          setRatingStats(res.ratingStats);
        }
        setReviewsPagination(res.pagination || { page: 1, limit: 10, total: formatted.length, totalPages: 1 });
      }
    } catch (err) {
      console.error('Error fetching reviews:', err);
    } finally {
      setLoading(false);
    }
  }, []);

  const deleteReview = async (id) => {
    try {
      const res = await api.deleteReview(id);
      if (res.success) {
        showToast('info', `Review deleted successfully`);
        fetchReviews({ page: reviewsPagination.page, limit: reviewsPagination.limit });
      }
    } catch (err) {
      showToast('error', err.response?.data?.message || 'Failed to delete review');
    }
  };

  // --- NOTIFICATIONS & BROADCAST ---
  const fetchNotifications = useCallback(async () => {
    try {
      const res = await api.getNotifications();
      if (res.success) {
        const formatted = res.notifications.map(n => ({
          id: n._id,
          title: n.title,
          message: n.message,
          category: n.category || 'System',
          targetAudience: n.targetAudience || 'All Users',
          recipientEmail: n.recipientEmail,
          priority: n.priority || 'Normal',
          unread: n.unread,
          time: new Date(n.createdAt).toLocaleTimeString('en-IN', { hour: '2-digit', minute: '2-digit' }),
          date: new Date(n.createdAt).toLocaleDateString('en-IN')
        }));
        setNotifications(formatted);
      }
    } catch (err) {
      console.error('Error fetching notifications:', err);
    }
  }, []);

  const markAllNotificationsRead = async () => {
    try {
      const res = await api.markAllNotificationsRead();
      if (res.success) {
        showToast('success', 'All notifications marked as read');
        fetchNotifications();
      }
    } catch (err) {
      showToast('error', 'Failed to mark notifications read');
    }
  };

  const deleteNotification = async (id) => {
    try {
      const res = await api.deleteNotification(id);
      if (res.success) {
        showToast('info', 'Notification deleted');
        fetchNotifications();
      }
    } catch (err) {
      showToast('error', 'Failed to delete notification');
    }
  };

  const addNotification = async (notifData) => {
    try {
      const res = await api.sendNotification(notifData);
      if (res.success) {
        showToast('success', res.message || `Notification broadcasted successfully!`);
        fetchNotifications();
      }
    } catch (err) {
      showToast('error', err.response?.data?.message || 'Failed to send notification');
    }
  };

  // --- GOVERNANCE SETTINGS ---
  const fetchSettings = useCallback(async () => {
    try {
      const res = await api.getSettings();
      if (res.success && res.settings) {
        setSettings(res.settings);
      }
    } catch (err) {
      console.error('Error fetching settings:', err);
    }
  }, []);

  const updateSettings = async (settingsData) => {
    try {
      const res = await api.updateSettings(settingsData);
      if (res.success) {
        setSettings(res.settings);
        showToast('success', res.message || 'Platform settings updated successfully!');
      }
    } catch (err) {
      showToast('error', err.response?.data?.message || 'Failed to update settings');
    }
  };

  // Initial Data Load on Auth
  useEffect(() => {
    if (token) {
      api.getProfile()
        .then((res) => {
          if (res && res.success && res.user) {
            setAdminUser(res.user);
            sessionStorage.setItem('adminUser', JSON.stringify(res.user));
            localStorage.setItem('adminUser', JSON.stringify(res.user));
          }
        })
        .catch((err) => console.warn('Failed to refresh admin profile:', err));
      fetchDashboardStats();
      fetchSettings();
    }
  }, [token, fetchDashboardStats, fetchSettings]);

  return (
    <AppContext.Provider
      value={{
        token,
        adminUser,
        setAdminUser,
        updateAdminProfile,
        isAuthenticated: !!token,
        loginAdmin,
        logoutAdmin,

        dashboardStats,
        recentBookings,
        topServices,
        fetchDashboardStats,

        customers,
        customersPagination,
        fetchCustomers,
        toggleCustomerBlock,

        workers,
        workersPagination,
        fetchWorkers,
        verifyWorker,
        rejectWorker,
        addWorker,
        updateWorker,

        bookings,
        bookingsPagination,
        fetchBookings,
        assignWorkerToBooking,
        updateBookingStatus,

        services,
        servicesPagination,
        fetchServices,
        addService,
        updateService,
        deleteService,

        payments,
        paymentsPagination,
        paymentStats,
        fetchPayments,

        reviews,
        reviewsPagination,
        ratingStats,
        fetchReviews,
        deleteReview,

        insurancePolicies,
        welfareClaims,

        notifications,
        fetchNotifications,
        addNotification,
        markAllNotificationsRead,
        deleteNotification,

        settings,
        fetchSettings,
        updateSettings,

        analytics,
        aiInsights,
        loading,
        selectedDateRange,
        setSelectedDateRange
      }}
    >
      {children}
    </AppContext.Provider>
  );
}

export function useApp() {
  const context = useContext(AppContext);
  if (!context) {
    throw new Error('useApp must be used within an AppProvider');
  }
  return context;
}
