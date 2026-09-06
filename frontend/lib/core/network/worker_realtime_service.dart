import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import 'api_config.dart';

/// Real-time Socket.io orchestrator for Worker screens.
/// Provides reactive streams for StreamBuilder and Cubits to eliminate manual pull-to-refresh.
class WorkerRealtimeService {
  WorkerRealtimeService._();
  static final WorkerRealtimeService instance = WorkerRealtimeService._();

  io.Socket? _socket;
  String? _currentWorkerId;
  String? _activeBookingId;

  final _bookingStatusStream = StreamController<Map<String, dynamic>>.broadcast();
  final _incomingJobsStream = StreamController<Map<String, dynamic>>.broadcast();
  final _jobClaimedStream = StreamController<Map<String, dynamic>>.broadcast();
  final _connectionStream = StreamController<bool>.broadcast();

  Stream<Map<String, dynamic>> get bookingStatusStream => _bookingStatusStream.stream;
  Stream<Map<String, dynamic>> get incomingJobsStream => _incomingJobsStream.stream;
  Stream<Map<String, dynamic>> get jobClaimedStream => _jobClaimedStream.stream;
  Stream<bool> get connectionStream => _connectionStream.stream;

  bool get isConnected => _socket?.connected == true;

  /// Call whenever worker session is ready or app starts with worker role
  void initForWorker(String workerId) {
    if (_currentWorkerId == workerId && _socket != null && _socket!.connected) {
      return;
    }
    _currentWorkerId = workerId;
    _connectSocket();
  }

  void _connectSocket() {
    _socket?.disconnect();
    _socket?.dispose();

    final socket = io.io(
      ApiConfig.baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .enableReconnection()
          .setReconnectionDelay(1000)
          .build(),
    );
    _socket = socket;

    socket.onConnect((_) {
      debugPrint('[WorkerRealtimeService] Connected to Socket.io');
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
      debugPrint('[WorkerRealtimeService] Connect error: $err');
      if (!_connectionStream.isClosed) _connectionStream.add(false);
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

    // New Incoming job requests for worker feed
    void onIncomingJob(dynamic data) {
      debugPrint('[WorkerRealtimeService] incoming job alert: $data');
      if (data is Map && !_incomingJobsStream.isClosed) {
        _incomingJobsStream.add(Map<String, dynamic>.from(data));
      }
    }

    socket.on('worker:booking_requested', onIncomingJob);
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
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}
