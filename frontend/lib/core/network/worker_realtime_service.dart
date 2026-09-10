import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import 'api_config.dart';

/// Real-time Socket.io orchestrator for Worker screens.
/// Provides reactive streams for StreamBuilder and Cubits to eliminate manual pull-to-refresh.
class WorkerRealtimeService {
  WorkerRealtimeService._() {
    ApiConfig.urlNotifier.addListener(_onBaseUrlChanged);
  }
  static final WorkerRealtimeService instance = WorkerRealtimeService._();

  io.Socket? _socket;
  String? _currentWorkerId;
  String? _activeBookingId;
  int _candidateIndex = 0;
  Timer? _candidateFailoverTimer;
  String? _currentConnectedUrl;

  final _bookingStatusStream = StreamController<Map<String, dynamic>>.broadcast();
  final _incomingJobsStream = StreamController<Map<String, dynamic>>.broadcast();
  final _jobClaimedStream = StreamController<Map<String, dynamic>>.broadcast();
  final _connectionStream = StreamController<bool>.broadcast();

  Stream<Map<String, dynamic>> get bookingStatusStream => _bookingStatusStream.stream;
  Stream<Map<String, dynamic>> get incomingJobsStream => _incomingJobsStream.stream;
  Stream<Map<String, dynamic>> get jobClaimedStream => _jobClaimedStream.stream;
  Stream<bool> get connectionStream => _connectionStream.stream;

  bool get isConnected => _socket?.connected == true;

  void _onBaseUrlChanged() {
    final newUrl = ApiConfig.baseUrl;
    if (_currentConnectedUrl != newUrl && (_socket == null || !_socket!.connected)) {
      debugPrint('[WorkerRealtimeService] BaseUrl changed to $newUrl, reconnecting socket...');
      _connectToUrl(newUrl);
    }
  }

  /// Call whenever worker session is ready or app starts with worker role
  void initForWorker(String workerId) {
    if (_currentWorkerId == workerId && _socket != null && _socket!.connected) {
      if (!_connectionStream.isClosed) _connectionStream.add(true);
      return;
    }
    _currentWorkerId = workerId;
    _candidateIndex = 0;
    _connectSocket();
  }

  /// Explicit reconnect (e.g. from refresh button or tapping status badge)
  void reconnect() {
    _candidateIndex = 0;
    _connectSocket();
  }

  void _connectSocket() {
    final candidates = ApiConfig.candidateUrls;
    final targetUrl = (_candidateIndex < candidates.length)
        ? candidates[_candidateIndex]
        : ApiConfig.baseUrl;
    _connectToUrl(targetUrl);
  }

  void _tryNextCandidate() {
    final candidates = ApiConfig.candidateUrls;
    if (candidates.isEmpty) return;
    _candidateIndex = (_candidateIndex + 1) % candidates.length;
    final nextUrl = candidates[_candidateIndex];
    debugPrint('[WorkerRealtimeService] Socket failover to candidate: $nextUrl');
    _connectToUrl(nextUrl);
  }

  void _connectToUrl(String url) {
    _candidateFailoverTimer?.cancel();
    _socket?.disconnect();
    _socket?.dispose();

    debugPrint('[WorkerRealtimeService] Connecting to Socket.io at: $url');
    final socket = io.io(
      url,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .enableReconnection()
          .setReconnectionDelay(1000)
          .setReconnectionAttempts(5)
          .setTimeout(4000)
          .build(),
    );
    _socket = socket;

    // Failover timer: if not connected within 4 seconds, try next candidate
    _candidateFailoverTimer = Timer(const Duration(seconds: 4), () {
      if (_socket == socket && !socket.connected) {
        debugPrint('[WorkerRealtimeService] Socket connection timed out for $url, trying next candidate');
        _tryNextCandidate();
      }
    });

    socket.onConnect((_) {
      _candidateFailoverTimer?.cancel();
      _currentConnectedUrl = url;
      ApiConfig.setBaseUrl(url);
      debugPrint('[WorkerRealtimeService] Connected to Socket.io at $url ✅');
      if (!_connectionStream.isClosed) _connectionStream.add(true);
      if (_currentWorkerId != null) {
        socket.emit('join_worker_room', _currentWorkerId);
      }
      if (_activeBookingId != null) {
        socket.emit('join_booking_room', _activeBookingId);
      }
    });

    socket.onDisconnect((_) {
      debugPrint('[WorkerRealtimeService] Disconnected from Socket.io');
      if (!_connectionStream.isClosed) _connectionStream.add(false);
    });

    socket.onConnectError((err) {
      debugPrint('[WorkerRealtimeService] Connect error on $url: $err');
      if (!_connectionStream.isClosed) _connectionStream.add(false);
      _tryNextCandidate();
    });

    // Real-time Booking status updates (ARRIVED, IN_PROGRESS, PAYMENT_PENDING, COMPLETED, PAID)
    void onBookingStatus(dynamic data) {
      debugPrint('[WorkerRealtimeService] booking_status_update received: $data');
      if (data is Map && !_bookingStatusStream.isClosed) {
        _bookingStatusStream.add(Map<String, dynamic>.from(data));
      }
    }

    socket.on('booking_status_update', onBookingStatus);
    socket.on('booking:status', onBookingStatus);
    socket.on('status_update', onBookingStatus);
    socket.on('booking:updated', onBookingStatus);
    socket.on('booking_completion_otp_required', onBookingStatus);

    // New Incoming job requests for worker feed
    void onIncomingJob(dynamic data) {
      debugPrint('[WorkerRealtimeService] incoming job alert: $data');
      if (data is Map && !_incomingJobsStream.isClosed) {
        _incomingJobsStream.add(Map<String, dynamic>.from(data));
      }
    }

    socket.on('worker:booking_requested', onIncomingJob);
    socket.on('emergency:booking_requested', onIncomingJob);
    socket.on('booking:new_available', onIncomingJob);

    // Jobs claimed by another worker
    void onJobClaimed(dynamic data) {
      debugPrint('[WorkerRealtimeService] job claimed: $data');
      if (data is Map && !_jobClaimedStream.isClosed) {
        _jobClaimedStream.add(Map<String, dynamic>.from(data));
      }
    }

    socket.on('booking:claimed', onJobClaimed);
    socket.on('booking:declined', onJobClaimed);

    // Worker availability events
    socket.on('worker:availability_changed', onBookingStatus);
    socket.on('worker:availability-changed', onBookingStatus);

    socket.connect();
  }

  /// Subscribe worker to a specific active booking room
  void trackBooking(String bookingId) {
    _activeBookingId = bookingId;
    if (_socket != null && _socket!.connected) {
      _socket!.emit('join_booking_room', bookingId);
    }
  }

  void untrackBooking() {
    _activeBookingId = null;
  }

  void dispose() {
    _candidateFailoverTimer?.cancel();
    ApiConfig.urlNotifier.removeListener(_onBaseUrlChanged);
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}
