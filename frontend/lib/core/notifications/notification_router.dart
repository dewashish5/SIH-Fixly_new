import 'package:go_router/go_router.dart';

import '../../app/router/route_names.dart';
import 'notification_payload.dart';

class NotificationRouter {
  NotificationRouter._();

  static final instance = NotificationRouter._();

  GoRouter? _router;
  bool _authReady = false;
  NotificationPayload? _pending;

  bool _pendingIsWorker = false;

  void attachRouter(GoRouter router) {
    _router = router;
    flushPending();
  }

  void setAuthReady(bool ready) {
    _authReady = ready;
    if (ready) {
      flushPending();
    } else {
      _pending = null;
    }
  }

  void handle(NotificationPayload payload, {bool isWorker = false}) {
    if (!_authReady || _router == null) {
      _pending = payload;
      _pendingIsWorker = isWorker;
      return;
    }
    _navigate(payload, isWorker: isWorker);
  }

  void flushPending() {
    final pending = _pending;
    if (pending == null || !_authReady || _router == null) return;
    final isWorker = _pendingIsWorker;
    _pending = null;
    _navigate(pending, isWorker: isWorker);
  }

  void _navigate(NotificationPayload payload, {bool isWorker = false}) {
    final router = _router;
    if (router == null) return;
    router.go(_locationFor(payload, isWorker: isWorker));
  }

  String _locationFor(NotificationPayload payload, {bool isWorker = false}) {
    final bookingId = payload.bookingId ??
        (payload.entityType == 'booking' ? payload.entityId : null);
    final hasBooking = bookingId != null && bookingId.isNotEmpty;
    const fromSuffix = '?from=notifications';

    switch (payload.action) {
      case 'worker_job':
        if (hasBooking) {
          return '${RouteNames.workerJobDetailPath(bookingId)}$fromSuffix';
        }
        return RouteNames.workerIncoming;

      case 'invoice':
        if (hasBooking) {
          return isWorker
              ? '${RouteNames.workerJobDetailPath(bookingId)}$fromSuffix'
              : '${RouteNames.bookingDetailPath(bookingId)}$fromSuffix';
        }
        return RouteNames.customerPayments;

      case 'wallet':
        return RouteNames.workerWallet;

      case 'verification':
        return RouteNames.workerOnboardingStatus;

      case 'support_ticket':
        return RouteNames.sharedSupportChat;

      case 'system':
        return RouteNames.sharedNotifications;

      case 'discount':
        return isWorker ? RouteNames.workerDashboard : RouteNames.customerHome;

      case 'booking_tracking':
      case 'payment':
      case 'booking_details':
      default:
        if (hasBooking) {
          return isWorker
              ? '${RouteNames.workerJobDetailPath(bookingId)}$fromSuffix'
              : '${RouteNames.bookingDetailPath(bookingId)}$fromSuffix';
        }
        return RouteNames.sharedNotifications;
    }
  }
}
