import 'package:go_router/go_router.dart';

import '../../app/router/route_names.dart';
import 'notification_payload.dart';

class NotificationRouter {
  NotificationRouter._();

  static final instance = NotificationRouter._();

  GoRouter? _router;
  bool _authReady = false;
  NotificationPayload? _pending;

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

  void handle(NotificationPayload payload) {
    if (!_authReady || _router == null) {
      _pending = payload;
      return;
    }
    _navigate(payload);
  }

  void flushPending() {
    final pending = _pending;
    if (pending == null || !_authReady || _router == null) return;
    _pending = null;
    _navigate(pending);
  }

  void _navigate(NotificationPayload payload) {
    final router = _router;
    if (router == null) return;
    router.go(_locationFor(payload));
  }

  String _locationFor(NotificationPayload payload) {
    final bookingId = payload.bookingId ?? payload.entityId;
    switch (payload.action) {
      case 'worker_job':
        if (bookingId != null && bookingId.isNotEmpty) {
          return RouteNames.workerJobDetailPath(bookingId);
        }
        return RouteNames.workerIncoming;
      case 'booking_tracking':
        return RouteNames.customerTracking;
      case 'invoice':
        if (bookingId != null && bookingId.isNotEmpty) {
          return RouteNames.customerInvoice.replaceFirst(':id', bookingId);
        }
        return RouteNames.customerPayments;
      case 'payment':
        return RouteNames.customerPayment;
      case 'wallet':
        return RouteNames.workerWallet;
      case 'verification':
        return RouteNames.workerOnboardingStatus;
      case 'support_ticket':
        return RouteNames.sharedSupportChat;
      case 'system':
        return RouteNames.sharedNotifications;
      case 'booking_details':
      default:
        if (bookingId != null && bookingId.isNotEmpty) {
          return RouteNames.bookingDetailPath(bookingId);
        }
        return RouteNames.sharedNotifications;
    }
  }
}
