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

  // --- Home & Services ---
  static const String home = '/api/home/home';
  static const String categories = '/api/services/categories';
  static const String homeCategories = '/api/home/categories';
  static String serviceById(String serviceId) => '/api/services/$serviceId';

  // --- Bookings (Customer & Shared) ---
  static const String bookingEstimate = '/api/bookings/estimate';
  static const String createBooking = '/api/bookings/';
  static const String bookingHistory = '/api/bookings/history';
  static String bookingById(String bookingId) => '/api/bookings/$bookingId';
  static String cancelBooking(String bookingId) => '/api/bookings/$bookingId/cancel';
  static String verifyArrivalOtp(String bookingId) => '/api/bookings/$bookingId/verify-otp';
  static String completeBooking(String bookingId) => '/api/bookings/$bookingId/complete';
  static String addParts(String bookingId) => '/api/bookings/$bookingId/add-parts';

  // --- Bookings (Worker Operations) ---
  static const String workerIncomingJobs = '/api/bookings/worker/incoming';
  static const String workerActiveJobs = '/api/bookings/worker/active';
  static const String workerCompletedJobs = '/api/bookings/worker/completed';
  static String acceptJob(String bookingId) => '/api/bookings/$bookingId/accept';
  static String declineJob(String bookingId) => '/api/bookings/$bookingId/decline';
  static String startJob(String bookingId) => '/api/bookings/$bookingId/start-job';

  // --- Workers ---
  static const String workers = '/api/workers/';
  static const String setupProfile = '/api/workers/setup-profile';
  static const String workerAvailability = '/api/workers/me/availability';
  static const String workerWallet = '/api/workers/me/wallet';
  static const String workerEarningsSummary = '/api/workers/me/earnings/summary';
  static const String workerWithdraw = '/api/workers/me/withdraw';
  static String workerById(String workerId) => '/api/workers/$workerId';
  static String workerReliability(String workerId) => '/api/workers/$workerId/reliability';

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
