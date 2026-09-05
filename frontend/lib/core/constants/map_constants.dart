import 'dart:math' as math;

import '../location/app_location.dart';
import 'map_token.dart';

/// Mapbox helpers + live user coordinates (no demo city hardcodes).
abstract final class MapConstants {
  static String get accessToken => MapToken.accessToken;

  static bool get hasToken => MapToken.hasToken;

  /// Current device location after [LocationService] refresh.
  static MapCoordinate? get current => AppLocation.instance.coordinateOrNull;

  /// Animated "worker en route" start — offset from current GPS.
  static MapCoordinate? get workerApproachStart =>
      AppLocation.instance.approachStartOrNull;

  static const defaultZoom = 13.0;
  static const navigationZoom = 14.0;
  static const serviceAreaZoom = 11.5;
  static const pickerZoom = 16.0;

  static MapCoordinate lerpRoute(
    MapCoordinate from,
    MapCoordinate to,
    double progress,
  ) {
    final t = progress.clamp(0.0, 1.0);
    return MapCoordinate(
      lat: from.lat + (to.lat - from.lat) * t,
      lng: from.lng + (to.lng - from.lng) * t,
      label: to.label,
    );
  }

  static double circleRadiusPixels({
    required double radiusKm,
    required double latitude,
    required double zoom,
  }) {
    final metersPerPixel =
        156543.03392 * math.cos(latitude * math.pi / 180) / math.pow(2, zoom);
    return (radiusKm * 1000) / metersPerPixel;
  }
}

class MapCoordinate {
  const MapCoordinate({
    required this.lat,
    required this.lng,
    this.label,
    this.heading,
  });

  final double lat;
  final double lng;
  final String? label;
  final double? heading;

  MapCoordinate copyWith({
    double? lat,
    double? lng,
    String? label,
    double? heading,
  }) {
    return MapCoordinate(
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      label: label ?? this.label,
      heading: heading ?? this.heading,
    );
  }

  static MapCoordinate lerp(MapCoordinate from, MapCoordinate to, double progress) {
    return MapConstants.lerpRoute(from, to, progress);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MapCoordinate &&
          runtimeType == other.runtimeType &&
          lat == other.lat &&
          lng == other.lng &&
          label == other.label &&
          heading == other.heading;

  @override
  int get hashCode => Object.hash(lat, lng, label, heading);

  @override
  String toString() =>
      'MapCoordinate(lat: $lat, lng: $lng, label: $label, heading: $heading)';
}

