import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../constants/map_constants.dart';
import 'api_config.dart';

/// Real-time Socket.io orchestrator for Customer screens.
/// Maintains a persistent, robust socket connection across the customer experience
/// (Home, Finding Worker, Accepted, Arrived, In-Progress, Payment).
class CustomerRealtimeService {
  CustomerRealtimeService._() {
    ApiConfig.urlNotifier.addListener(_onBaseUrlChanged);
  }
  static final CustomerRealtimeService instance = CustomerRealtimeService._();

  io.Socket? _socket;
  String? _currentCustomerId;
  String? _activeBookingId;
  String? _currentConnectedUrl;

  final _bookingStatusStream = StreamController<Map<String, dynamic>>.broadcast();
  final _workerLocationStream = StreamController<MapCoordinate>.broadcast();
  final _connectionStream = StreamController<bool>.broadcast();

  Stream<Map<String, dynamic>> get bookingStatusStream => _bookingStatusStream.stream;
  Stream<MapCoordinate> get workerLocationStream => _workerLocationStream.stream;
  Stream<bool> get connectionStream => _connectionStream.stream;

  bool get isConnected => _socket?.connected == true;
  String? get activeBookingId => _activeBookingId;

  void _onBaseUrlChanged() {
    final newUrl = ApiConfig.baseUrl;
    if (_currentConnectedUrl != newUrl && (_socket == null || !_socket!.connected)) {
      debugPrint('[CustomerRealtimeService] BaseUrl changed to $newUrl, reconnecting socket...');
      _connectToUrl(newUrl);
    }
  }

  /// Initialize persistent socket connection for a customer session
  void initForCustomer(String customerId) {
    _currentCustomerId = customerId;
    if (_socket != null && _socket!.connected) {
      _socket!.emit('join_customer_room', customerId);
      _socket!.emit('join_user_room', customerId);
      if (!_connectionStream.isClosed) _connectionStream.add(true);
      return;
    }
    _connectSocket();
  }

  /// Explicit reconnect
  void reconnect() {
    _connectSocket();
  }

  void _connectSocket() {
    _connectToUrl(ApiConfig.baseUrl);
  }

  void _connectToUrl(String url) {
    if (_socket != null && _socket!.connected && _currentConnectedUrl == url) {
      return;
    }

    _socket?.disconnect();
    _socket?.dispose();

    debugPrint('[CustomerRealtimeService] Connecting persistent Socket.io at: $url');
    final socket = io.io(
      url,
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .enableReconnection()
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(5000)
          .setReconnectionAttempts(double.maxFinite.toInt())
          .setTimeout(20000)
          .build(),
    );
    _socket = socket;

    socket.onConnect((_) {
      _currentConnectedUrl = url;
      debugPrint('[CustomerRealtimeService] Connected to Socket.io at $url ✅');
      if (!_connectionStream.isClosed) _connectionStream.add(true);

      if (_currentCustomerId != null) {
        socket.emit('join_customer_room', _currentCustomerId);
        socket.emit('join_user_room', _currentCustomerId);
      }
      if (_activeBookingId != null) {
        socket.emit('join_booking_room', _activeBookingId);
        socket.emit('joinBooking', {'bookingId': _activeBookingId});
      }
    });

    socket.onDisconnect((reason) {
      debugPrint('[CustomerRealtimeService] Disconnected from Socket.io: $reason');
      if (!_connectionStream.isClosed) _connectionStream.add(false);
    });

    socket.onConnectError((err) {
      debugPrint('[CustomerRealtimeService] Connect error on $url: $err');
      if (!_connectionStream.isClosed) _connectionStream.add(false);
    });

    socket.onError((err) {
      debugPrint('[CustomerRealtimeService] Socket error: $err');
    });

    // 1. Booking status update events
    void onBookingStatus(dynamic data) {
      debugPrint('[CustomerRealtimeService] booking status received: $data');
      if (data is Map && !_bookingStatusStream.isClosed) {
        _bookingStatusStream.add(Map<String, dynamic>.from(data));
      }
    }

    for (final event in const [
      'booking_status_update',
      'booking:status',
      'booking:claimed',
      'booking:declined',
      'booking:updated',
      'status_update',
      'booking_completion_otp_required',
      'sos_alert',
    ]) {
      socket.on(event, onBookingStatus);
    }

    // 2. Worker live location events
    void onWorkerLocation(dynamic data) {
      final coord = _parseCoordinate(data);
      if (coord != null && !_workerLocationStream.isClosed) {
        _workerLocationStream.add(coord);
      }
    }

    for (final event in const [
      'live_tracking',
      'worker:location',
      'worker-location',
      'worker_location_update',
      'booking:location',
      'booking-location',
      'location:update',
      'locationUpdate',
    ]) {
      socket.on(event, onWorkerLocation);
    }

    socket.connect();
  }

  /// Subscribe customer to a specific active booking room
  void trackBooking(String bookingId) {
    _activeBookingId = bookingId;
    if (_socket != null && _socket!.connected) {
      _socket!.emit('join_booking_room', bookingId);
      _socket!.emit('joinBooking', {'bookingId': bookingId});
    }
  }

  void untrackBooking() {
    _activeBookingId = null;
  }

  MapCoordinate? _parseCoordinate(dynamic value) {
    if (value is! Map) return null;
    final nested =
        value['location'] ?? value['position'] ?? value['workerLocation'];
    final data = nested is Map ? nested : value;
    final coordinates = data['coordinates'];

    double? lat;
    double? lng;

    if (coordinates is List && coordinates.length >= 2) {
      lng = (coordinates[0] as num?)?.toDouble();
      lat = (coordinates[1] as num?)?.toDouble();
    } else {
      final rawLat = data['lat'] ?? data['latitude'];
      final rawLng = data['lng'] ?? data['longitude'];
      if (rawLat is num) lat = rawLat.toDouble();
      if (rawLng is num) lng = rawLng.toDouble();
    }

    if (lat == null || lng == null) return null;

    final rawHeading = data['heading'] ??
        data['bearing'] ??
        value['heading'] ??
        value['bearing'];
    final heading = rawHeading is num ? rawHeading.toDouble() : null;

    final rawTs = data['timestamp'] ?? value['timestamp'];
    final timestamp = rawTs is num ? rawTs.toInt() : null;

    return MapCoordinate(lat: lat, lng: lng, heading: heading, timestamp: timestamp);
  }

  void dispose() {
    ApiConfig.urlNotifier.removeListener(_onBaseUrlChanged);
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}
