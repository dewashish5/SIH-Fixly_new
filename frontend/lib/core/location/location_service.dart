import 'package:flutter/foundation.dart';
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

  /// Connaught Place, New Delhi — debug/simulator when GPS unavailable.
  static const double debugFallbackLat = 28.6139;
  static const double debugFallbackLng = 77.2090;
  static const String debugFallbackAddress = 'New Delhi (debug fallback)';

  final Geocoding _geocoder = Geocoding();
  bool _refreshing = false;

  /// Call when UI is ready (splash). Shows themed dialogs if needed.
  Future<bool> ensureOnAppOpen(BuildContext context) async {
    if (_refreshing) return AppLocation.instance.hasFix;
    _refreshing = true;
    try {
      if (!await _ensureLocationServices(context)) {
        AppLocation.instance.permissionGranted = false;
        return _finishWithOptionalDebugFallback('location services off');
      }
      if (!context.mounted) {
        return _finishWithOptionalDebugFallback('context unmounted');
      }
      final granted = await _ensurePermission(context);
      if (!granted) {
        AppLocation.instance.permissionGranted = false;
        return _finishWithOptionalDebugFallback('permission denied');
      }
      return await refreshCurrentPosition();
    } finally {
      _refreshing = false;
    }
  }

  /// Sign-up / register — GPS on, permission granted, then fix for API body.
  Future<bool> ensureForSignup(BuildContext context) async {
    if (!context.mounted) {
      return _finishWithOptionalDebugFallback('signup context unmounted');
    }
    if (!await _ensureLocationServices(context)) {
      return _finishWithOptionalDebugFallback('signup location services off');
    }
    if (!context.mounted) {
      return _finishWithOptionalDebugFallback('signup context unmounted');
    }
    if (!await _ensurePermission(context)) {
      return _finishWithOptionalDebugFallback('signup permission denied');
    }
    return refreshCurrentPosition();
  }

  /// GPS-only refresh (permission already granted). Safe without context.
  Future<bool> refreshCurrentPosition() async {
    try {
      final serviceOn = await Geolocator.isLocationServiceEnabled();
      if (!serviceOn) {
        debugPrint('LocationService: device location services off');
        return _finishWithOptionalDebugFallback('services off on refresh');
      }

      final status = await Permission.locationWhenInUse.status;
      if (!status.isGranted) {
        return _finishWithOptionalDebugFallback('permission missing on refresh');
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
      return _finishWithOptionalDebugFallback('position error: $e');
    }
  }

  /// Debug-only: seed Delhi so API/maps work without simulator GPS.
  bool _finishWithOptionalDebugFallback(String reason) {
    if (AppLocation.instance.hasFix) return true;
    if (!kDebugMode) return false;
    AppLocation.instance.update(
      latitude: debugFallbackLat,
      longitude: debugFallbackLng,
      address: debugFallbackAddress,
    );
    debugPrint('LocationService: debug fallback Delhi — $reason');
    return true;
  }

  Future<bool> _ensureLocationServices(BuildContext context) async {
    if (await Geolocator.isLocationServiceEnabled()) return true;
    if (!context.mounted) return false;

    final open = await LocationPermissionDialogs.showLocationServicesOff(context);
    if (!open) return false;

    await Geolocator.openLocationSettings();
    return Geolocator.isLocationServiceEnabled();
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
