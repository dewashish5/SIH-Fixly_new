import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import 'app_location.dart';
import 'location_permission_dialogs.dart';

/// Asks location permission (themed) + refreshes GPS once per app open.
class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  final Geocoding _geocoder = Geocoding();
  bool _refreshing = false;

  /// Call when UI is ready (splash). Shows themed dialogs if needed.
  Future<bool> ensureOnAppOpen(BuildContext context) async {
    if (_refreshing) return AppLocation.instance.hasFix;
    _refreshing = true;
    try {
      final granted = await _ensurePermission(context);
      if (!granted) {
        AppLocation.instance.permissionGranted = false;
        return false;
      }
      return await refreshCurrentPosition();
    } finally {
      _refreshing = false;
    }
  }

  /// GPS-only refresh (permission already granted). Safe without context.
  Future<bool> refreshCurrentPosition() async {
    try {
      final serviceOn = await Geolocator.isLocationServiceEnabled();
      if (!serviceOn) {
        debugPrint('LocationService: device location services off');
        return false;
      }

      final status = await Permission.locationWhenInUse.status;
      if (!status.isGranted) {
        return false;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      String? address;
      try {
        final places = await _geocoder.placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (places.isNotEmpty) {
          address = _formatPlacemark(places.first);
        }
      } catch (e) {
        debugPrint('LocationService: reverse geocode failed: $e');
      }

      AppLocation.instance.update(
        latitude: position.latitude,
        longitude: position.longitude,
        address: address,
      );
      return true;
    } catch (e) {
      debugPrint('LocationService: position failed: $e');
      return false;
    }
  }

  Future<bool> _ensurePermission(BuildContext context) async {
    if (!context.mounted) return false;

    var status = await Permission.locationWhenInUse.status;

    if (status.isGranted) return true;

    if (status.isPermanentlyDenied) {
      if (!context.mounted) return false;
      await LocationPermissionDialogs.showOpenSettings(context);
      status = await Permission.locationWhenInUse.status;
      return status.isGranted;
    }

    if (!context.mounted) return false;
    final proceed = await LocationPermissionDialogs.showRationale(context);
    if (!proceed) return false;

    status = await Permission.locationWhenInUse.request();

    if (status.isPermanentlyDenied && context.mounted) {
      await LocationPermissionDialogs.showOpenSettings(context);
      status = await Permission.locationWhenInUse.status;
    }

    return status.isGranted;
  }

  static String _formatPlacemark(Placemark p) {
    final parts = <String>[
      if ((p.street ?? '').trim().isNotEmpty) p.street!.trim(),
      if ((p.subLocality ?? '').trim().isNotEmpty) p.subLocality!.trim(),
      if ((p.locality ?? '').trim().isNotEmpty) p.locality!.trim(),
      if ((p.administrativeArea ?? '').trim().isNotEmpty)
        p.administrativeArea!.trim(),
      if ((p.postalCode ?? '').trim().isNotEmpty) p.postalCode!.trim(),
    ];
    if (parts.isEmpty) {
      return [
        p.name,
        p.locality,
        p.country,
      ].whereType<String>().where((s) => s.trim().isNotEmpty).join(', ');
    }
    return parts.join(', ');
  }
}
