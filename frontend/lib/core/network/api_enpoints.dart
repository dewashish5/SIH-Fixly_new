/// Centralized API endpoint routes across the app.
abstract final class ApiEndpoints {
  // --- Auth ---
  static const String register = '/api/auth/register';
  static const String verifyOtp = '/api/auth/verify-otp';
  static const String login = '/api/auth/login';
  static const String googleLogin = '/api/auth/google';
  static const String refreshToken = '/api/auth/refresh-token';
  static const String forgotPassword = '/api/auth/forgot-password';
  static const String resetPassword = '/api/auth/reset-password';
  static const String logout = '/api/auth/logout';
  static const String me = '/api/auth/me';
  static const String usersMe = '/api/users/me';

  // --- Notifications ---
  static const String notifications = '/api/notifications';
  static const String markAllNotificationsRead = '/api/notifications/read-all';
  static String markNotificationRead(String id) =>
      '/api/notifications/$id/read';
  static String deleteNotification(String id) => '/api/notifications/$id';
  static const String registerDeviceToken = '/api/notifications/device-token';
  static const String removeDeviceToken = '/api/notifications/device-token';

  // --- Home & Services ---
  static const String home = '/api/home/home';
  static const String banners = '/api/home/banners';
  static const String categories = '/api/services/categories';
  static const String homeCategories = '/api/home/categories';
  static String serviceById(String serviceId) => '/api/services/$serviceId';

  // --- Bookings (Customer & Shared) ---
  static const String bookingEstimate = '/api/bookings/estimate';
  static const String createBooking = '/api/bookings/';
  static const String bookingHistory = '/api/bookings/history';
  static String bookingById(String bookingId) => '/api/bookings/$bookingId';
  static String cancelBooking(String bookingId) =>
      '/api/bookings/$bookingId/cancel';
  static String verifyArrivalOtp(String bookingId) =>
      '/api/bookings/$bookingId/verify-otp';
  static String completeBooking(String bookingId) =>
      '/api/bookings/$bookingId/complete';
  static String addParts(String bookingId) =>
      '/api/bookings/$bookingId/add-parts';
  static String bookingInvoice(String bookingId) =>
      '/api/bookings/$bookingId/invoice';
  static String bookingReview(String bookingId) =>
      '/api/bookings/$bookingId/review';
  static String bookingSos(String bookingId) => '/api/bookings/$bookingId/sos';
  static String bookingTrack(String bookingId) =>
      '/api/bookings/$bookingId/track';

  // --- Bookings (Worker Operations) ---
  static const String workerIncomingJobs = '/api/bookings/worker/incoming';
  static const String workerActiveJobs = '/api/bookings/worker/active';
  static const String workerCompletedJobs = '/api/bookings/worker/completed';
  static String acceptJob(String bookingId) =>
      '/api/bookings/$bookingId/accept';
  static String declineJob(String bookingId) =>
      '/api/bookings/$bookingId/decline';
  static String startJob(String bookingId) =>
      '/api/bookings/$bookingId/start-job';

  // --- Workers ---
  static const String workers = '/api/workers/';
  static const String setupProfile = '/api/workers/setup-profile';
  static const String workerAvailability = '/api/workers/me/availability';
  static const String workerWallet = '/api/workers/me/wallet';
  static const String workerEarningsSummary =
      '/api/workers/me/earnings/summary';
  static const String workerWithdraw = '/api/workers/me/withdraw';
  static String workerById(String workerId) => '/api/workers/$workerId';
  static String workerReliability(String workerId) =>
      '/api/workers/$workerId/reliability';
  static String workerReviews(String workerId) =>
      '/api/workers/$workerId/reviews';
  static const String workerAvailabilitySchedule =
      '/api/workers/me/availability/schedule';
  static const String workerCertificates = '/api/workers/me/certificates';
  static String workerCertificate(String id) =>
      '/api/workers/me/certificates/$id';
  static const String workerEarnings = '/api/workers/me/earnings';
  static const String workerInsurance = '/api/workers/me/insurance';
  static const String workerInsuranceClaims =
      '/api/workers/me/insurance/claims';
  static const String workerMembership = '/api/workers/me/membership';
  static const String workerPayouts = '/api/workers/me/payouts';
  static const String workerTransactions = '/api/workers/me/transactions';
  static const String workerWelfare = '/api/workers/me/welfare';
  static const String workerWelfareTransactions =
      '/api/workers/me/welfare/transactions';

  // --- Payments ---
  static const String paymentConfig = '/api/payments/config';
  static const String createPaymentOrder = '/api/payments/create-order';
  static const String verifyPayment = '/api/payments/verify';
  static const String paymentWalletHistory = '/api/payments/wallet-history';

  // --- Reviews ---
  static String submitReview(String bookingId) => '/api/reviews/$bookingId';

  // --- AI ---
  static const String aiAnalyzeIssue = '/api/ai/analyze-issue';

  // --- Upload ---
  static const String upload = '/api/upload';

  /// Check if a request path is an unauthenticated auth route.
  static bool isAuthPath(String path) {
    return path.contains(login) ||
        path.contains(register) ||
        path.contains(verifyOtp) ||
        path.contains(refreshToken) ||
        path.contains(forgotPassword) ||
        path.contains(resetPassword) ||
        path.contains(googleLogin);
  }
}
