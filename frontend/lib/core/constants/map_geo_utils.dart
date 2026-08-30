import 'dart:math' as math;

import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import 'map_constants.dart';

abstract final class MapGeoUtils {
  static Polygon geodesicCirclePolygon({
    required double lat,
    required double lng,
    required double radiusKm,
    int steps = 72,
  }) {
    const earthRadiusKm = 6371.0;
    final ring = <Position>[];

    for (var i = 0; i <= steps; i++) {
      final bearing = (i / steps) * 2 * math.pi;
      final latRad = lat * math.pi / 180;
      final lngRad = lng * math.pi / 180;
      final angularDistance = radiusKm / earthRadiusKm;

      final lat2 = math.asin(
        math.sin(latRad) * math.cos(angularDistance) +
            math.cos(latRad) * math.sin(angularDistance) * math.cos(bearing),
      );
      final lng2 = lngRad +
          math.atan2(
            math.sin(bearing) * math.sin(angularDistance) * math.cos(latRad),
            math.cos(angularDistance) - math.sin(latRad) * math.sin(lat2),
          );

      ring.add(Position(lng2 * 180 / math.pi, lat2 * 180 / math.pi));
    }

    return Polygon(coordinates: [ring]);
  }

  static List<Point> cameraPoints({
    required MapCoordinate center,
    MapCoordinate? routeEnd,
    double? routeProgress,
    double? serviceRadiusKm,
  }) {
    final points = <Point>[
      Point(coordinates: Position(center.lng, center.lat)),
    ];

    if (serviceRadiusKm != null) {
      const bearings = [0.0, 90.0, 180.0, 270.0];
      for (final bearing in bearings) {
        final edge = _destinationAtBearing(
          lat: center.lat,
          lng: center.lng,
          radiusKm: serviceRadiusKm,
          bearingDegrees: bearing,
        );
        points.add(Point(coordinates: Position(edge.lng, edge.lat)));
      }
    }

    if (routeEnd != null) {
      points.add(
        Point(
          coordinates: Position(
            MapConstants.workerStart.lng,
            MapConstants.workerStart.lat,
          ),
        ),
      );
      final worker = MapConstants.lerpRoute(
        MapConstants.workerStart,
        routeEnd,
        routeProgress ?? 0,
      );
      points.add(Point(coordinates: Position(worker.lng, worker.lat)));
      points.add(Point(coordinates: Position(routeEnd.lng, routeEnd.lat)));
    }

    return points;
  }

  static MapCoordinate _destinationAtBearing({
    required double lat,
    required double lng,
    required double radiusKm,
    required double bearingDegrees,
  }) {
    const earthRadiusKm = 6371.0;
    final bearing = bearingDegrees * math.pi / 180;
    final latRad = lat * math.pi / 180;
    final lngRad = lng * math.pi / 180;
    final angularDistance = radiusKm / earthRadiusKm;

    final lat2 = math.asin(
      math.sin(latRad) * math.cos(angularDistance) +
          math.cos(latRad) * math.sin(angularDistance) * math.cos(bearing),
    );
    final lng2 = lngRad +
        math.atan2(
          math.sin(bearing) * math.sin(angularDistance) * math.cos(latRad),
          math.cos(angularDistance) - math.sin(latRad) * math.sin(lat2),
        );

    return MapCoordinate(
      lat: lat2 * 180 / math.pi,
      lng: lng2 * 180 / math.pi,
    );
  }
}
