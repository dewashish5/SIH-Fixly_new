import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as io;

import '../constants/map_constants.dart';
import 'api_config.dart';

class LiveTrackingSocket {
  io.Socket? _socket;
  final _positions = StreamController<MapCoordinate>.broadcast();

  Stream<MapCoordinate> get positions => _positions.stream;

  void connect(String bookingId) {
    disconnect();
    final socket = io.io(
      ApiConfig.baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .enableReconnection()
          .build(),
    );
    _socket = socket;
    void onPosition(dynamic value) {
      final coordinate = _parse(value);
      if (coordinate != null && !_positions.isClosed) {
        _positions.add(coordinate);
      }
    }

    for (final event in const [
      'booking:location',
      'booking-location',
      'worker:location',
      'worker-location',
      'location:update',
      'locationUpdate',
    ]) {
      socket.on(event, onPosition);
    }
    socket.onConnect((_) {
      for (final event in const [
        'joinBooking',
        'join-booking',
        'subscribeBooking',
      ]) {
        socket.emit(event, {'bookingId': bookingId});
      }
    });
    socket.connect();
  }

  void disconnect() {
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
    if (coordinates is List && coordinates.length >= 2) {
      final lng = (coordinates[0] as num?)?.toDouble();
      final lat = (coordinates[1] as num?)?.toDouble();
      if (lat != null && lng != null) return MapCoordinate(lat: lat, lng: lng);
    }
    final lat = (data['lat'] ?? data['latitude']) as num?;
    final lng = (data['lng'] ?? data['longitude']) as num?;
    if (lat == null || lng == null) return null;
    return MapCoordinate(lat: lat.toDouble(), lng: lng.toDouble());
  }

  Future<void> dispose() async {
    disconnect();
    await _positions.close();
  }
}
