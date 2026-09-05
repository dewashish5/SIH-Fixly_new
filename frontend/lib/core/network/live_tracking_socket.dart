import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as io;

import '../constants/map_constants.dart';
import 'api_config.dart';

class LiveTrackingSocket {
  io.Socket? _socket;
  final _positions = StreamController<MapCoordinate>.broadcast();
  final _connectionState = StreamController<bool>.broadcast();
  bool _connected = false;

  Stream<MapCoordinate> get positions => _positions.stream;
  Stream<bool> get connectionState => _connectionState.stream;
  bool get isConnected => _connected;

  void connect(String bookingId) {
    disconnect();
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

    void onPosition(dynamic value) {
      final coordinate = _parse(value);
      if (coordinate != null && !_positions.isClosed) {
        _positions.add(coordinate);
      }
    }

    // Register all tracking broadcast events
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
      socket.on(event, onPosition);
    }

    socket.onConnect((_) {
      _connected = true;
      if (!_connectionState.isClosed) _connectionState.add(true);

      // Join room using backend convention
      socket.emit('join_booking_room', bookingId);
      socket.emit('joinBooking', {'bookingId': bookingId});
      socket.emit('subscribeBooking', {'bookingId': bookingId});
    });

    socket.onDisconnect((_) {
      _connected = false;
      if (!_connectionState.isClosed) _connectionState.add(false);
    });

    socket.onConnectError((err) {
      _connected = false;
      if (!_connectionState.isClosed) _connectionState.add(false);
    });

    socket.connect();
  }

  /// Worker emits real-time GPS coordinate to backend room
  void emitWorkerLocation({
    required String bookingId,
    required double lat,
    required double lng,
    double? heading,
  }) {
    final payload = {
      'bookingId': bookingId,
      'lat': lat,
      'lng': lng,
      'heading': heading ?? 0.0,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    _socket?.emit('worker_location_update', payload);
  }

  void disconnect() {
    _connected = false;
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  MapCoordinate? _parse(dynamic value) {
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

    return MapCoordinate(lat: lat, lng: lng, heading: heading);
  }

  Future<void> dispose() async {
    disconnect();
    await _positions.close();
    await _connectionState.close();
  }
}

