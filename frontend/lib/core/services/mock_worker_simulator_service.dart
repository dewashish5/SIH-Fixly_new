import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../config/feature_flag.dart';
import '../network/api_config.dart';

/// Simulates a real-time Socket.io worker client for Vaibhav Jain (`6a9d255bf09b371a043e8b77`).
/// Enables continuous availability, booking dispatch handling, and live GPS location updates.
/// Controlled entirely via [FeatureFlags.kEnableMockWorkerSimulation].
class MockWorkerSimulatorService {
  MockWorkerSimulatorService._();
  static final MockWorkerSimulatorService instance = MockWorkerSimulatorService._();

  static const String workerId = '6a9d255bf09b371a043e8b77';
  static const String workerName = 'Vaibhav Jain';
  static const String workerCategory = 'electrician';

  // Base coordinates for Vaibhav Jain (Bilaspur, CG)
  static const double initialLat = 22.0765629;
  static const double initialLng = 82.1529507;

  io.Socket? _socket;
  Timer? _movementTimer;
  String? _activeBookingId;
  double _currentLat = initialLat;
  double _currentLng = initialLng;
  bool _initialized = false;

  bool get isConnected => _socket?.connected == true;
  String? get activeBookingId => _activeBookingId;

  /// Initializes the mock worker socket client if enabled in [FeatureFlags].
  void init() {
    if (!kEnableMockWorkerSimulation) {
      debugPrint('ℹ️ [MockWorkerSimulator] Disabled via FeatureFlags.kEnableMockWorkerSimulation = false');
      stop();
      return;
    }

    if (_initialized && _socket != null && _socket!.connected) {
      return;
    }

    _initialized = true;
    _currentLat = initialLat;
    _currentLng = initialLng;

    debugPrint('🚀 [MockWorkerSimulator] Initializing Vaibhav Jain socket client at ${ApiConfig.baseUrl}');

    _socket?.disconnect();
    _socket?.dispose();

    final socket = io.io(
      ApiConfig.baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .enableReconnection()
          .setReconnectionDelay(2000)
          .build(),
    );
    _socket = socket;

    socket.onConnect((_) {
      debugPrint('✅ [MockWorkerSimulator] Connected to Socket.io server as worker "$workerName" ($workerId)');

      // Join worker-specific room and global worker pool room
      socket.emit('join_worker_room', workerId);
      socket.emit('join_worker_room', 'workers_all');

      // Sync worker base location
      socket.emit('worker_location_update', {
        'workerId': workerId,
        'lat': _currentLat,
        'lng': _currentLng,
        'heading': 0.0,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    });

    socket.onDisconnect((reason) {
      debugPrint('⚠️ [MockWorkerSimulator] Disconnected: $reason');
    });

    socket.onConnectError((err) {
      debugPrint('❌ [MockWorkerSimulator] Connection error: $err');
    });

    // Listen for direct booking assignment to Vaibhav Jain
    socket.on('worker:booking_requested', (data) {
      if (!kEnableMockWorkerSimulation) return;
      debugPrint('📩 [MockWorkerSimulator] Direct booking request received: $data');
      _handleIncomingBooking(data);
    });

    // Listen for emergency or general broadcast bookings
    socket.on('booking:new_available', (data) {
      if (!kEnableMockWorkerSimulation) return;
      debugPrint('⚡ [MockWorkerSimulator] New booking broadcast received: $data');
      _handleIncomingBooking(data);
    });

    socket.on('emergency:booking_requested', (data) {
      if (!kEnableMockWorkerSimulation) return;
      debugPrint('🚨 [MockWorkerSimulator] SOS Emergency booking received: $data');
      _handleIncomingBooking(data);
    });

    socket.connect();
  }

  void _handleIncomingBooking(dynamic data) {
    if (data is! Map) return;

    final booking = data['booking'] is Map ? data['booking'] as Map : data;
    final bookingId = booking['_id']?.toString() ??
        booking['bookingId']?.toString() ??
        data['bookingId']?.toString();

    if (bookingId == null) return;

    // Check if designated for this worker or matching category
    final assignedWorkerId = data['workerId']?.toString() ??
        (booking['worker'] is Map ? booking['worker']['_id']?.toString() : booking['worker']?.toString());

    final category = (data['category'] ?? booking['category'] ?? '').toString().toLowerCase();

    final isTargeted = assignedWorkerId == workerId || category.contains('electric') || assignedWorkerId == null;

    if (!isTargeted) {
      return;
    }

    debugPrint('🎯 [MockWorkerSimulator] Vaibhav Jain claiming/acknowledging booking $bookingId');
    _activeBookingId = bookingId;

    // Join the booking room for live coordination
    _socket?.emit('join_booking_room', bookingId);

    // Extract destination customer coordinates
    double? destLat;
    double? destLng;
    final coords = data['coordinates'] ??
        booking['serviceAddress']?['location']?['coordinates'] ??
        booking['location']?['coordinates'];

    if (coords is List && coords.length >= 2) {
      // GeoJSON Point is [longitude, latitude]
      destLng = (coords[0] as num).toDouble();
      destLat = (coords[1] as num).toDouble();
    }

    startLocationSimulation(
      bookingId: bookingId,
      customerLat: destLat ?? (_currentLat + 0.005),
      customerLng: destLng ?? (_currentLng + 0.005),
    );
  }

  /// Programmatically simulate worker movement and live GPS updates for any active booking.
  void startLocationSimulation({
    required String bookingId,
    required double customerLat,
    required double customerLng,
  }) {
    if (!kEnableMockWorkerSimulation) return;

    _movementTimer?.cancel();
    _activeBookingId = bookingId;

    // Join the booking room to ensure broadcast delivery
    _socket?.emit('join_booking_room', bookingId);

    debugPrint('📍 [MockWorkerSimulator] Starting GPS movement simulation towards ($customerLat, $customerLng) for booking $bookingId');

    const totalSteps = 20;
    var step = 0;

    final startLat = _currentLat;
    final startLng = _currentLng;

    _movementTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!kEnableMockWorkerSimulation || _socket == null || !_socket!.connected) {
        timer.cancel();
        return;
      }

      step++;
      final fraction = (step / totalSteps).clamp(0.0, 1.0);

      // Interpolate with slight realistic jitter
      final jitter = (Random().nextDouble() - 0.5) * 0.0001;
      _currentLat = startLat + (customerLat - startLat) * fraction + jitter;
      _currentLng = startLng + (customerLng - startLng) * fraction + jitter;

      final heading = _calculateBearing(startLat, startLng, customerLat, customerLng);

      _socket?.emit('worker_location_update', {
        'bookingId': bookingId,
        'workerId': workerId,
        'lat': _currentLat,
        'lng': _currentLng,
        'heading': heading,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      debugPrint('🛰️ [MockWorkerSimulator] Emitted GPS update step $step/$totalSteps: ($_currentLat, $_currentLng)');

      if (step >= totalSteps) {
        debugPrint('🏁 [MockWorkerSimulator] Vaibhav Jain reached destination for booking $bookingId');
        timer.cancel();
      }
    });
  }

  /// Calculates bearing between two coordinates in degrees.
  double _calculateBearing(double startLat, double startLng, double endLat, double endLng) {
    final dLon = (endLng - startLng) * (pi / 180.0);
    final lat1 = startLat * (pi / 180.0);
    final lat2 = endLat * (pi / 180.0);

    final y = sin(dLon) * cos(lat2);
    final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);

    final radians = atan2(y, x);
    return (radians * (180.0 / pi) + 360.0) % 360.0;
  }

  /// Stops simulation and cancels timers.
  void stop() {
    _movementTimer?.cancel();
    _movementTimer = null;
    _activeBookingId = null;
  }

  /// Completely disconnects and tears down the mock worker socket client.
  void dispose() {
    stop();
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _initialized = false;
  }
}
