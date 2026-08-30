import 'dart:math' as math;

import 'map_token.dart';

/// Mapbox + Noida demo coordinates for Fixly service area.
abstract final class MapConstants {
  static String get accessToken => MapToken.accessToken;

  static bool get hasToken => MapToken.hasToken;

  /// Sector 12, Noida — default customer location.
  static const noidaSector12 = MapCoordinate(
    lat: 28.5789,
    lng: 77.3178,
    label: 'Sector 12, Noida',
  );

  /// Mock worker start point for live tracking / navigation.
  static const workerStart = MapCoordinate(
    lat: 28.5862,
    lng: 77.3045,
    label: 'Worker',
  );

  static const defaultZoom = 13.0;
  static const navigationZoom = 14.0;
  static const serviceAreaZoom = 11.5;

  static MapCoordinate lerpRoute(
    MapCoordinate from,
    MapCoordinate to,
    double progress,
  ) {
    final t = progress.clamp(0.0, 1.0);
    return MapCoordinate(
      lat: from.lat + (to.lat - from.lat) * t,
      lng: from.lng + (to.lng - from.lng) * t,
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
  });

  final double lat;
  final double lng;
  final String? label;
}
