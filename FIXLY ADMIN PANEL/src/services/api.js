import axios from 'axios';

const API_BASE_URL = import.meta.env.VITE_API_URL;

const adminApi = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json'
  }
});

// Request Interceptor: Attach JWT Token
adminApi.interceptors.request.use(
  (config) => {
    const token = sessionStorage.getItem('adminToken');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => Promise.reject(error)
);

// Response Interceptor: Handle 401 Unauthorized
adminApi.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response && error.response.status === 401) {
      // If unauthorized and not on login request, clear token and redirect
      if (!error.config.url.includes('/login')) {
        sessionStorage.removeItem('adminToken');
        sessionStorage.removeItem('adminUser');
        if (window.location.pathname !== '/login') {
          window.location.href = '/login';
        }
      }
    }
    return Promise.reject(error);
  }
);

export const api = {
  // Auth
  login: async (email, password) => {
    const res = await adminApi.post('/login', { email, password });
    return res.data;
  },
  getProfile: async () => {
    const res = await adminApi.get('/me');
    return res.data;
  },
  updateProfile: async (data) => {
    const res = await adminApi.put('/me', data);
    return res.data;
  },

  // Dashboard
  getDashboardStats: async () => {
    const res = await adminApi.get('/dashboard');
    return res.data;
  },

  // Customers
  getCustomers: async (params = {}) => {
    const res = await adminApi.get('/customers', { params });
    return res.data;
  },
  getCustomerById: async (id) => {
    const res = await adminApi.get(`/customers/${id}`);
    return res.data;
  },
  toggleCustomerStatus: async (id, isVerified) => {
    const res = await adminApi.patch(`/customers/${id}/status`, { isVerified });
    return res.data;
  },

  // Workers
  getWorkers: async (params = {}) => {
    const res = await adminApi.get('/workers', { params });
    return res.data;
  },
  getWorkerById: async (id) => {
    const res = await adminApi.get(`/workers/${id}`);
    return res.data;
  },
  updateWorker: async (id, data) => {
    const res = await adminApi.put(`/workers/${id}`, data);
    return res.data;
  },
  updateWorkerStatus: async (id, data) => {
    const res = await adminApi.patch(`/workers/${id}/status`, data);
    return res.data;
  },
  addWorker: async (workerData) => {
    const res = await adminApi.post('/workers', workerData);
    return res.data;
  },

  // Bookings
  getBookings: async (params = {}) => {
    const res = await adminApi.get('/bookings', { params });
    return res.data;
  },
  getBookingById: async (id) => {
    const res = await adminApi.get(`/bookings/${id}`);
    return res.data;
  },
  assignWorkerToBooking: async (bookingId, workerId) => {
    const res = await adminApi.patch(`/bookings/${bookingId}/assign`, { workerId });
    return res.data;
  },
  updateBookingStatus: async (bookingId, data) => {
    const res = await adminApi.patch(`/bookings/${bookingId}/status`, data);
    return res.data;
  },

  // Services
  getServices: async (params = {}) => {
    const res = await adminApi.get('/services', { params });
    return res.data;
  },
  createService: async (serviceData) => {
    const res = await adminApi.post('/services', serviceData);
    return res.data;
  },
  updateService: async (id, serviceData) => {
    const res = await adminApi.put(`/services/${id}`, serviceData);
    return res.data;
  },
  deleteService: async (id) => {
    const res = await adminApi.delete(`/services/${id}`);
    return res.data;
  },

  // Payments
  getPayments: async (params = {}) => {
    const res = await adminApi.get('/payments', { params });
    return res.data;
  },
  getPaymentStats: async () => {
    const res = await adminApi.get('/payments/stats');
    return res.data;
  },

  // Reviews
  getReviews: async (params = {}) => {
    const res = await adminApi.get('/reviews', { params });
    return res.data;
  },
  deleteReview: async (id) => {
    const res = await adminApi.delete(`/reviews/${id}`);
    return res.data;
  },

  // Notifications & Broadcast
  sendAdminNotification: async (notifData) => {
    const res = await adminApi.post('/notifications/broadcast', notifData);
    return res.data;
  },

  // Notifications
  getNotifications: async () => {
    const res = await adminApi.get('/notifications');
    return res.data;
  },
  sendNotification: async (data) => {
    const res = await adminApi.post('/notifications/broadcast', data);
    return res.data;
  },
  markAllNotificationsRead: async () => {
    const res = await adminApi.put('/notifications/mark-read');
    return res.data;
  },
  deleteNotification: async (id) => {
    const res = await adminApi.delete(`/notifications/${id}`);
    return res.data;
  },

  // Analytics & AI Insights
  getAnalytics: async () => {
    const res = await adminApi.get('/analytics');
    return res.data;
  },
  getAIInsights: async () => {
    const res = await adminApi.get('/ai-insights');
    return res.data;
  },
  getReportsData: async () => {
    const res = await adminApi.get('/reports');
    return res.data;
  },

  // Governance Settings
  getSettings: async () => {
    const res = await adminApi.get('/settings');
    return res.data;
  },
  updateSettings: async (settingsData) => {
    const res = await adminApi.put('/settings', settingsData);
    return res.data;
  },

  // Image Upload (Cloudinary / File)
  uploadImage: async (file) => {
    const formData = new FormData();
    formData.append('file', file);
    const res = await adminApi.post('/upload', formData, {
      headers: {
        'Content-Type': 'multipart/form-data'
      }
    });
    return res.data;
  }
};

export default adminApi;
