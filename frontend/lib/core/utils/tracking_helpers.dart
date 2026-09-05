import 'dart:math' as math;

import '../constants/map_constants.dart';

/// Helper functions for live map tracking, bearing, heading, distance, and ETA.
abstract final class TrackingHelpers {
  /// Calculates standard geodesic bearing in degrees (0° = North, 90° = East, 180° = South, 270° = West).
  static double bearingDegrees(MapCoordinate from, MapCoordinate to) {
    final lat1 = from.lat * math.pi / 180.0;
    final lat2 = to.lat * math.pi / 180.0;
    final deltaLng = (to.lng - from.lng) * math.pi / 180.0;
    final y = math.sin(deltaLng) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(deltaLng);
    return (math.atan2(y, x) * 180.0 / math.pi + 360.0) % 360.0;
  }

  /// Calculates rotation angle for [assets/icons/bike_marker.png].
  /// The bike artwork faces North (0° up), so rotation matches bearing directly.
  static double bikeIconRotation(MapCoordinate from, MapCoordinate to) {
    return bearingDegrees(from, to);
  }

  /// Normalizes any heading or bearing to 0..360 range.
  static double normalizeHeading(double heading) {
    return (heading % 360.0 + 360.0) % 360.0;
  }

  /// Haversine distance in meters between two coordinates.
  static double distanceMeters(MapCoordinate from, MapCoordinate to) {
    const earthRadius = 6371000.0;
    final lat1 = from.lat * math.pi / 180.0;
    final lat2 = to.lat * math.pi / 180.0;
    final dLat = (to.lat - from.lat) * math.pi / 180.0;
    final dLng = (to.lng - from.lng) * math.pi / 180.0;
    final a = math.sin(dLat / 2.0) * math.sin(dLat / 2.0) +
        math.cos(lat1) * math.cos(lat2) * math.sin(dLng / 2.0) * math.sin(dLng / 2.0);
    return earthRadius * 2.0 * math.atan2(math.sqrt(a), math.sqrt(1.0 - a));
  }

  /// Linearly interpolates between two coordinates with optional heading interpolation.
  static MapCoordinate lerpCoordinate(MapCoordinate from, MapCoordinate to, double t) {
    final progress = t.clamp(0.0, 1.0);
    final lat = from.lat + (to.lat - from.lat) * progress;
    final lng = from.lng + (to.lng - from.lng) * progress;

    double? heading;
    if (from.heading != null && to.heading != null) {
      // Shortest angle interpolation
      var diff = (to.heading! - from.heading!) % 360.0;
      if (diff > 180.0) diff -= 360.0;
      if (diff < -180.0) diff += 360.0;
      heading = (from.heading! + diff * progress + 360.0) % 360.0;
    } else {
      heading = to.heading ?? from.heading ?? bearingDegrees(from, to);
    }

    return MapCoordinate(
      lat: lat,
      lng: lng,
      label: to.label ?? from.label,
      heading: heading,
    );
  }

  /// Formats distance in meters to a readable string (e.g., "450 m" or "2.4 km").
  static String formatDistance(double meters) {
    if (meters < 1000.0) {
      return '${meters.round()} m';
    }
    return '${(meters / 1000.0).toStringAsFixed(1)} km';
  }

  /// Estimates ETA minutes assuming typical city navigation speed (default 25 km/h).
  static int estimateEtaMinutes(double distanceInMeters, {double speedKmh = 25.0}) {
    if (distanceInMeters <= 50.0) return 0;
    final hours = (distanceInMeters / 1000.0) / speedKmh;
    return math.max(1, (hours * 60.0).round());
  }

  /// Formats ETA into human readable string.
  static String formatEta(int minutes) {
    if (minutes <= 0) return 'Arriving now';
    if (minutes == 1) return '1 min away';
    return '$minutes mins away';
  }
}
