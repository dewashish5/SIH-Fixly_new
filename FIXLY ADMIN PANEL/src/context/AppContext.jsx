import React, { createContext, useContext, useState } from 'react';
import { initialWorkers } from '../data/workers';
import { initialBookings } from '../data/bookings';
import { initialCustomers } from '../data/customers';
import { initialServices } from '../data/services';
import { initialPayments, paymentStats } from '../data/payments';
import { initialInsurancePolicies, initialWelfareClaims } from '../data/insurance';
import { initialReviews } from '../data/reviews';
import { initialNotifications } from '../data/notifications';
import { useToast } from './ToastContext';

const AppContext = createContext(null);

export function AppProvider({ children }) {
  const { showToast } = useToast();

  // State entities
  const [workers, setWorkers] = useState(initialWorkers);
  const [bookings, setBookings] = useState(initialBookings);
  const [customers, setCustomers] = useState(initialCustomers);
  const [services, setServices] = useState(initialServices);
  const [payments, setPayments] = useState(initialPayments);
  const [insurancePolicies, setInsurancePolicies] = useState(initialInsurancePolicies);
  const [welfareClaims, setWelfareClaims] = useState(initialWelfareClaims);
  const [reviews, setReviews] = useState(initialReviews);
  const [notifications, setNotifications] = useState(initialNotifications);
  
  // Date & Filter states
  const [selectedDateRange, setSelectedDateRange] = useState('Today (26 May, 2025)');

  // Settings State
  const [settings, setSettings] = useState({
    platformName: 'Cooperative Gig Services Platform',
    cooperativeWelfarePercent: 5,
    autoDispatchEnabled: true,
    emergencyHotline: '1800-456-GIGS (4447)',
    emailNotifications: true,
    smsAlerts: true,
    payoutSchedule: 'Instant Automated UPI',
    escrowHoldingHours: 24,
    theme: 'light',
  });

  // --- WORKER ACTIONS ---
  const addWorker = (workerData) => {
    const newWorker = {
      ...workerData,
      id: `WRK-${100 + workers.length + 1}`,
      joinedDate: 'Today',
      rating: 5.0,
      totalReviews: 0,
      completedJobs: 0,
      todayEarnings: '₹0',
      lifetimeEarnings: '₹0',
      battery: '100%',
      availability: 'Available',
      insuranceStatus: 'Active (Cooperative Pool)',
    };
    setWorkers((prev) => [newWorker, ...prev]);
    showToast('success', `Worker ${newWorker.name} onboarded successfully!`);
  };

  const updateWorker = (id, updatedFields) => {
    setWorkers((prev) =>
      prev.map((w) => (w.id === id ? { ...w, ...updatedFields } : w))
    );
    showToast('success', `Worker profile updated successfully.`);
  };

  const verifyWorker = (id) => {
    setWorkers((prev) =>
      prev.map((w) => (w.id === id ? { ...w, verification: 'Verified', insuranceStatus: 'Active (₹5L Policy)' } : w))
    );
    showToast('success', `Worker #${id} verified and insurance activated!`);
  };

  const rejectWorker = (id) => {
    setWorkers((prev) =>
      prev.map((w) => (w.id === id ? { ...w, verification: 'Rejected' } : w))
    );
    showToast('error', `Worker application #${id} rejected.`);
  };

  const suspendWorker = (id) => {
    setWorkers((prev) =>
      prev.map((w) => (w.id === id ? { ...w, verification: 'Suspended', availability: 'Offline' } : w))
    );
    showToast('error', `Worker #${id} account suspended.`);
  };

  // --- BOOKING ACTIONS ---
  const addBooking = (bookingData) => {
    const newBooking = {
      ...bookingData,
      id: `BK-2025-${1022 + bookings.length}`,
      date: '26 May, 2025',
      time: 'Just now',
      status: 'Confirmed',
    };
    setBookings((prev) => [newBooking, ...prev]);
    showToast('success', `Booking ${newBooking.id} created successfully.`);
  };

  const updateBookingStatus = (id, newStatus) => {
    setBookings((prev) =>
      prev.map((b) => (b.id === id ? { ...b, status: newStatus } : b))
    );
    showToast('success', `Booking ${id} status changed to ${newStatus}`);
  };

  const assignWorkerToBooking = (bookingId, workerId) => {
    const worker = workers.find((w) => w.id === workerId);
    if (!worker) return;

    setBookings((prev) =>
      prev.map((b) =>
        b.id === bookingId
          ? {
              ...b,
              workerId: worker.id,
              worker: worker.name,
              workerPhone: worker.phone,
              workerRating: worker.rating,
              status: 'Assigned',
            }
          : b
      )
    );
    showToast('success', `Worker ${worker.name} assigned to booking ${bookingId}`);
  };

  const rescheduleBooking = (bookingId, newSlot) => {
    setBookings((prev) =>
      prev.map((b) =>
        b.id === bookingId
          ? { ...b, scheduledSlot: newSlot, time: newSlot.split(', ')[1] || b.time }
          : b
      )
    );
    showToast('success', `Booking ${bookingId} rescheduled to ${newSlot}`);
  };

  const cancelBooking = (bookingId, reason = '') => {
    setBookings((prev) =>
      prev.map((b) =>
        b.id === bookingId ? { ...b, status: 'Cancelled', notes: `Cancelled: ${reason}` } : b
      )
    );
    showToast('error', `Booking ${bookingId} has been cancelled.`);
  };

  // --- CUSTOMER ACTIONS ---
  const toggleCustomerBlock = (customerId) => {
    setCustomers((prev) =>
      prev.map((c) => {
        if (c.id === customerId) {
          const newStatus = c.status === 'Blocked' ? 'Active' : 'Blocked';
          showToast(newStatus === 'Blocked' ? 'error' : 'success', `Customer ${c.name} is now ${newStatus}`);
          return { ...c, status: newStatus };
        }
        return c;
      })
    );
  };

  // --- SERVICE ACTIONS ---
  const addService = (serviceData) => {
    const newService = {
      ...serviceData,
      id: `SRV-${String(services.length + 1).padStart(2, '0')}`,
      activeWorkers: 0,
      completedTasks: '0',
      avgRating: 5.0,
      percentage: 5,
      icon: 'Layers',
      iconColor: '#0284c7',
      bg: '#f0f9ff',
      coopWelfarePercent: 5,
    };
    setServices((prev) => [...prev, newService]);
    showToast('success', `Service "${newService.name}" added to catalog!`);
  };

  const updateService = (id, updatedFields) => {
    setServices((prev) =>
      prev.map((s) => (s.id === id ? { ...s, ...updatedFields } : s))
    );
    showToast('success', `Service updated successfully.`);
  };

  const deleteService = (id) => {
    setServices((prev) => prev.filter((s) => s.id !== id));
    showToast('error', `Service deleted from catalog.`);
  };

  // --- REVIEW ACTIONS ---
  const deleteReview = (id) => {
    setReviews((prev) => prev.filter((r) => r.id !== id));
    showToast('info', `Inappropriate review #${id} deleted.`);
  };

  // --- NOTIFICATION ACTIONS ---
  const addNotification = (notifData) => {
    const newNotif = {
      ...notifData,
      id: `NOTIF-${String(notifications.length + 1).padStart(2, '0')}`,
      time: 'Just now',
      date: '26 May, 2025',
      unread: true,
    };
    setNotifications((prev) => [newNotif, ...prev]);
    showToast('success', `Broadcast notification dispatched!`);
  };

  const markAllNotificationsRead = () => {
    setNotifications((prev) => prev.map((n) => ({ ...n, unread: false })));
    showToast('info', `All notifications marked as read.`);
  };

  const deleteNotification = (id) => {
    setNotifications((prev) => prev.filter((n) => n.id !== id));
  };

  // --- SETTINGS ACTIONS ---
  const updateSettings = (newSettings) => {
    setSettings((prev) => ({ ...prev, ...newSettings }));
    showToast('success', `Platform settings saved successfully!`);
  };

  return (
    <AppContext.Provider
      value={{
        workers,
        bookings,
        customers,
        services,
        payments,
        insurancePolicies,
        welfareClaims,
        reviews,
        notifications,
        settings,
        selectedDateRange,
        setSelectedDateRange,
        
        // Actions
        addWorker,
        updateWorker,
        verifyWorker,
        rejectWorker,
        suspendWorker,
        
        addBooking,
        updateBookingStatus,
        assignWorkerToBooking,
        rescheduleBooking,
        cancelBooking,
        
        toggleCustomerBlock,
        
        addService,
        updateService,
        deleteService,
        
        deleteReview,
        
        addNotification,
        markAllNotificationsRead,
        deleteNotification,
        
        updateSettings,
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
