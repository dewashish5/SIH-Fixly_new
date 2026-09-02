import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Size;

import '../../app/theme/app_colors.dart';
import '../constants/map_constants.dart';
import '../constants/map_geo_utils.dart';

/// Mapbox map with route, worker progress, and service-area circle.
class FixlyMapView extends StatefulWidget {
  const FixlyMapView({
    super.key,
    this.height = 260,
    this.expand = false,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.center,
    this.zoom = MapConstants.defaultZoom,
    this.routeEnd,
    this.routeProgress,
    this.serviceRadiusKm,
    this.showDestinationPin = true,
    this.routeStart,
    this.claimGestures = false,
  });

  final double height;
  final bool expand;
  final BorderRadius borderRadius;
  final MapCoordinate? center;
  final double zoom;
  final MapCoordinate? routeEnd;
  final double? routeProgress;
  final double? serviceRadiusKm;
  final bool showDestinationPin;
  /// Worker / route start. Defaults to [MapConstants.workerApproachStart].
  final MapCoordinate? routeStart;
  /// Win gesture arena vs parent [ScrollView] so user can pan/zoom the map.
  final bool claimGestures;

  @override
  State<FixlyMapView> createState() => _FixlyMapViewState();
}

class _FixlyMapViewState extends State<FixlyMapView> {
  MapboxMap? _mapboxMap;
  PolylineAnnotationManager? _polylineManager;
  PolygonAnnotationManager? _polygonManager;
  PointAnnotationManager? _pointManager;
  PolylineAnnotation? _routeLine;
  PolygonAnnotation? _areaPolygon;
  PointAnnotation? _destinationMarker;
  PointAnnotation? _workerMarker;
  String? _mapError;

  @override
  void didUpdateWidget(covariant FixlyMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_mapboxMap == null) return;

    final changed = oldWidget.routeProgress != widget.routeProgress ||
        oldWidget.serviceRadiusKm != widget.serviceRadiusKm ||
        oldWidget.routeEnd != widget.routeEnd ||
        oldWidget.routeStart?.lat != widget.routeStart?.lat ||
        oldWidget.routeStart?.lng != widget.routeStart?.lng ||
        oldWidget.center?.lat != widget.center?.lat ||
        oldWidget.center?.lng != widget.center?.lng ||
        oldWidget.showDestinationPin != widget.showDestinationPin;

    if (changed) {
      _refreshAnnotations();
    }
  }

  Future<void> _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    await mapboxMap.scaleBar.updateSettings(ScaleBarSettings(enabled: false));
    await mapboxMap.compass.updateSettings(CompassSettings(enabled: false));
    await mapboxMap.logo.updateSettings(LogoSettings(marginBottom: 8, marginLeft: 8));
    await mapboxMap.attribution.updateSettings(
      AttributionSettings(marginBottom: 8, marginRight: 8),
    );

    _polylineManager = await mapboxMap.annotations.createPolylineAnnotationManager();
    _polygonManager = await mapboxMap.annotations.createPolygonAnnotationManager();
    _pointManager = await mapboxMap.annotations.createPointAnnotationManager();

    await _refreshAnnotations();
  }

  Future<void> _refreshAnnotations() async {
    final polylineManager = _polylineManager;
    final polygonManager = _polygonManager;
    final pointManager = _pointManager;
    if (polylineManager == null || polygonManager == null || pointManager == null) {
      return;
    }

    final destination = widget.center ?? MapConstants.current;
    if (destination == null) {
      return;
    }
    final start = widget.routeStart ?? MapConstants.workerApproachStart;
    final worker = widget.routeEnd == null || start == null
        ? null
        : MapConstants.lerpRoute(
            start,
            widget.routeEnd!,
            widget.routeProgress ?? 0,
          );

    if (widget.serviceRadiusKm != null) {
      final polygon = MapGeoUtils.geodesicCirclePolygon(
        lat: destination.lat,
        lng: destination.lng,
        radiusKm: widget.serviceRadiusKm!,
      );
      final areaOptions = PolygonAnnotationOptions(
        geometry: polygon,
        fillColor: AppColors.primary.withValues(alpha: 0.18).toARGB32(),
        fillOutlineColor: AppColors.primary.withValues(alpha: 0.85).toARGB32(),
        fillOpacity: 0.75,
      );
      if (_areaPolygon == null) {
        _areaPolygon = await polygonManager.create(areaOptions);
      } else {
        _areaPolygon!
          ..geometry = areaOptions.geometry
          ..fillColor = areaOptions.fillColor
          ..fillOutlineColor = areaOptions.fillOutlineColor
          ..fillOpacity = areaOptions.fillOpacity;
        await polygonManager.update(_areaPolygon!);
      }
    } else if (_areaPolygon != null) {
      await polygonManager.delete(_areaPolygon!);
      _areaPolygon = null;
    }

    if (widget.routeEnd != null && start != null) {
      final route = LineString(
        coordinates: [
          Position(start.lng, start.lat),
          Position(widget.routeEnd!.lng, widget.routeEnd!.lat),
        ],
      );
      final routeOptions = PolylineAnnotationOptions(
        geometry: route,
        lineColor: AppColors.primary.toARGB32(),
        lineWidth: 5,
        lineOpacity: 0.95,
        lineJoin: LineJoin.ROUND,
        lineBorderColor: Colors.white.toARGB32(),
        lineBorderWidth: 1.5,
      );
      if (_routeLine == null) {
        _routeLine = await polylineManager.create(routeOptions);
      } else {
        _routeLine!
          ..geometry = routeOptions.geometry
          ..lineColor = routeOptions.lineColor
          ..lineWidth = routeOptions.lineWidth;
        await polylineManager.update(_routeLine!);
      }
    } else if (_routeLine != null) {
      await polylineManager.delete(_routeLine!);
      _routeLine = null;
    }

    if (widget.showDestinationPin) {
      final destinationOptions = PointAnnotationOptions(
        geometry: Point(coordinates: Position(destination.lng, destination.lat)),
        iconImage: 'marker-15',
        iconSize: 1.35,
        iconColor: AppColors.accent.toARGB32(),
        iconAnchor: IconAnchor.BOTTOM,
        textField: destination.label ?? 'Destination',
        textSize: 12,
        textColor: AppColors.onSurface.toARGB32(),
        textHaloColor: Colors.white.toARGB32(),
        textHaloWidth: 1.5,
        textOffset: [0, 0.8],
        textAnchor: TextAnchor.TOP,
      );
      if (_destinationMarker == null) {
        _destinationMarker = await pointManager.create(destinationOptions);
      } else {
        _destinationMarker!
          ..geometry = destinationOptions.geometry
          ..textField = destinationOptions.textField;
        await pointManager.update(_destinationMarker!);
      }
    } else if (_destinationMarker != null) {
      await pointManager.delete(_destinationMarker!);
      _destinationMarker = null;
    }

    if (worker != null) {
      final workerOptions = PointAnnotationOptions(
        geometry: Point(coordinates: Position(worker.lng, worker.lat)),
        iconImage: 'car-15',
        iconSize: 1.25,
        iconColor: AppColors.primary.toARGB32(),
        iconAnchor: IconAnchor.CENTER,
        textField: start?.label ?? 'Worker',
        textSize: 12,
        textColor: AppColors.primary.toARGB32(),
        textHaloColor: Colors.white.toARGB32(),
        textHaloWidth: 1.5,
        textOffset: [0, 1.2],
        textAnchor: TextAnchor.TOP,
      );
      if (_workerMarker == null) {
        _workerMarker = await pointManager.create(workerOptions);
      } else {
        _workerMarker!
          ..geometry = workerOptions.geometry
          ..textField = workerOptions.textField;
        await pointManager.update(_workerMarker!);
      }
    } else if (_workerMarker != null) {
      await pointManager.delete(_workerMarker!);
      _workerMarker = null;
    }

    await _fitCamera();
  }

  Future<void> _fitCamera() async {
    final mapboxMap = _mapboxMap;
    if (mapboxMap == null) return;

    final center = widget.center ?? MapConstants.current;
    if (center == null) return;

    final points = MapGeoUtils.cameraPoints(
      center: center,
      routeStart: widget.routeStart ?? MapConstants.workerApproachStart,
      routeEnd: widget.routeEnd,
      routeProgress: widget.routeProgress,
      serviceRadiusKm: widget.serviceRadiusKm,
    );

    if (points.length <= 1) {
      await mapboxMap.setCamera(
        CameraOptions(
          center: Point(
            coordinates: Position(center.lng, center.lat),
          ),
          zoom: widget.zoom,
        ),
      );
      return;
    }

    final camera = await mapboxMap.cameraForCoordinatesPadding(
      points,
      CameraOptions(),
      MbxEdgeInsets(top: 56, left: 40, bottom: 56, right: 40),
      widget.routeEnd != null ? 15.5 : 13.5,
      null,
    );
    await mapboxMap.setCamera(camera);
  }

  @override
  Widget build(BuildContext context) {
    final center = widget.center ?? MapConstants.current;
    if (center == null) {
      final placeholder = DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: widget.borderRadius,
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_searching, color: AppColors.primary),
              SizedBox(height: 8),
              Text('Waiting for location…'),
            ],
          ),
        ),
      );
      if (widget.expand) {
        return placeholder;
      }
      return SizedBox(height: widget.height, child: placeholder);
    }

    final mapCore = MapConstants.hasToken && _mapError == null
        ? MapWidget(
            key: ValueKey('fixly-map-${center.lat}-${center.lng}'),
            styleUri: MapboxStyles.MAPBOX_STREETS,
            textureView: true,
            gestureRecognizers: widget.claimGestures
                ? <Factory<OneSequenceGestureRecognizer>>{
                    Factory<EagerGestureRecognizer>(
                      EagerGestureRecognizer.new,
                    ),
                  }
                : null,
            viewport: CameraViewportState(
              center: Point(
                coordinates: Position(center.lng, center.lat),
              ),
              zoom: widget.zoom,
            ),
            onMapCreated: _onMapCreated,
            onMapLoadErrorListener: (event) {
              if (!mounted) return;
              setState(() => _mapError = event.message);
            },
          )
        : _MapPreviewFallback(
            center: center,
            routeEnd: widget.routeEnd,
            routeProgress: widget.routeProgress,
            serviceRadiusKm: widget.serviceRadiusKm,
            showDestinationPin: widget.showDestinationPin,
            message: _mapError ??
                (MapConstants.hasToken ? null : 'Add ACCESS_TOKEN for Mapbox'),
          );

    final mapChild = Stack(
      fit: StackFit.expand,
      children: [
        mapCore,
        if (widget.routeEnd != null && _mapError == null && MapConstants.hasToken)
          const Positioned(
            top: 12,
            left: 12,
            child: _MapLegend(),
          ),
      ],
    );

    final content = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: widget.borderRadius,
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: widget.borderRadius,
        child: mapChild,
      ),
    );

    if (widget.expand) {
      return content;
    }
    return SizedBox(
      width: double.infinity,
      height: widget.height,
      child: content,
    );
  }
}

class _MapLegend extends StatelessWidget {
  const _MapLegend();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            _LegendRow(color: AppColors.primary, label: 'Worker'),
            SizedBox(height: 6),
            _LegendRow(color: AppColors.accent, label: 'Destination'),
          ],
        ),
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

class _MapPreviewFallback extends StatelessWidget {
  const _MapPreviewFallback({
    required this.center,
    this.routeEnd,
    this.routeProgress,
    this.serviceRadiusKm,
    this.showDestinationPin = true,
    this.message,
  });

  final MapCoordinate center;
  final MapCoordinate? routeEnd;
  final double? routeProgress;
  final double? serviceRadiusKm;
  final bool showDestinationPin;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            painter: _MapGridPainter(
              center: center,
              routeEnd: routeEnd,
              routeProgress: routeProgress,
              serviceRadiusKm: serviceRadiusKm,
              showDestinationPin: showDestinationPin,
            ),
          ),
          if (message != null)
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Text(
                    message!,
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  _MapGridPainter({
    required this.center,
    this.routeEnd,
    this.routeProgress,
    this.serviceRadiusKm,
    this.showDestinationPin = true,
  });

  final MapCoordinate center;
  final MapCoordinate? routeEnd;
  final double? routeProgress;
  final double? serviceRadiusKm;
  final bool showDestinationPin;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 28) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (var y = 0.0; y < size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final dest = Offset(size.width * 0.62, size.height * 0.58);
    final workerStart = Offset(size.width * 0.28, size.height * 0.34);
    final workerEnd = routeEnd == null
        ? workerStart
        : Offset(
            workerStart.dx + (dest.dx - workerStart.dx) * (routeProgress ?? 0),
            workerStart.dy + (dest.dy - workerStart.dy) * (routeProgress ?? 0),
          );

    if (serviceRadiusKm != null) {
      final radius = serviceRadiusKm! * 8;
      canvas.drawCircle(
        dest,
        radius,
        Paint()
          ..color = AppColors.primary.withValues(alpha: 0.12)
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        dest,
        radius,
        Paint()
          ..color = AppColors.primary.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    if (routeEnd != null) {
      canvas.drawLine(
        workerStart,
        dest,
        Paint()
          ..color = AppColors.primary
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round,
      );
      _drawPin(canvas, workerEnd, AppColors.primary);
    }

    if (showDestinationPin) {
      _drawPin(canvas, dest, AppColors.accent);
    }
  }

  void _drawPin(Canvas canvas, Offset point, Color color) {
    canvas.drawCircle(point, 10, Paint()..color = color);
    canvas.drawCircle(
      point,
      10,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _MapGridPainter oldDelegate) {
    return oldDelegate.routeProgress != routeProgress ||
        oldDelegate.serviceRadiusKm != serviceRadiusKm;
  }
}
