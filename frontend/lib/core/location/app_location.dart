import '../constants/map_constants.dart';

/// Live device position — filled after permission + GPS refresh on app open.
class AppLocation {
  AppLocation._();
  static final AppLocation instance = AppLocation._();

  double? lat;
  double? lng;
  String? addressLabel;
  bool permissionGranted = false;
  DateTime? lastUpdated;

  bool get hasFix => lat != null && lng != null;

  double get requireLat {
    final v = lat;
    if (v == null) {
      throw StateError('Location not available yet');
    }
    return v;
  }

  double get requireLng {
    final v = lng;
    if (v == null) {
      throw StateError('Location not available yet');
    }
    return v;
  }

  MapCoordinate get asCoordinate {
    if (!hasFix) {
      throw StateError('Location not available yet');
    }
    return MapCoordinate(lat: lat!, lng: lng!, label: addressLabel);
  }

  /// Soft read for UI — null until GPS ready.
  MapCoordinate? get coordinateOrNull =>
      hasFix ? MapCoordinate(lat: lat!, lng: lng!, label: addressLabel) : null;

  /// Approximate point ~800m NE of user for "worker approaching" map animation.
  MapCoordinate? get approachStartOrNull {
    if (!hasFix) return null;
    return MapCoordinate(
      lat: lat! + 0.0072,
      lng: lng! - 0.0065,
      label: 'Worker',
    );
  }

  void update({
    required double latitude,
    required double longitude,
    String? address,
  }) {
    lat = latitude;
    lng = longitude;
    if (address != null && address.isNotEmpty) {
      addressLabel = address;
    }
    lastUpdated = DateTime.now();
    permissionGranted = true;
  }

  void clear() {
    lat = null;
    lng = null;
    addressLabel = null;
    lastUpdated = null;
    permissionGranted = false;
  }
}
