import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Size;

import '../../app/theme/app_colors.dart';
import '../constants/map_constants.dart';
import '../constants/map_geo_utils.dart';
import '../utils/navigation_math.dart';

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
    this.routeCoordinates = const [],
    this.workerHeading,
    this.claimGestures = false,
    this.showZoomControls = true,
    this.showRecenterButton = false,
    this.onLocationChanged,
    this.onMapIdled,
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
  final List<MapCoordinate> routeCoordinates;
  final double? workerHeading;

  /// Win gesture arena vs parent [ScrollView] so user can pan/zoom the map.
  final bool claimGestures;

  /// Show floating '+' and '-' zoom buttons.
  final bool showZoomControls;

  /// Show floating recenter button to return to [center].
  final bool showRecenterButton;

  /// Callback when user moves the map / center coordinate (fires continuously during drag).
  final ValueChanged<MapCoordinate>? onLocationChanged;

  /// Callback fired ONCE after map becomes idle (user stopped dragging).
  final ValueChanged<MapCoordinate>? onMapIdled;

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
  PointAnnotation? _startMarker;
  Uint8List? _startImage;
  Uint8List? _stopImage;
  Uint8List? _bikeImage;
  String? _mapError;
  Timer? _idleDebounce;

  @override
  void dispose() {
    _idleDebounce?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant FixlyMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_mapboxMap == null) return;

    final changed =
        oldWidget.routeProgress != widget.routeProgress ||
        oldWidget.serviceRadiusKm != widget.serviceRadiusKm ||
        oldWidget.routeEnd != widget.routeEnd ||
        oldWidget.routeStart?.lat != widget.routeStart?.lat ||
        oldWidget.routeStart?.lng != widget.routeStart?.lng ||
        oldWidget.routeCoordinates != widget.routeCoordinates ||
        oldWidget.workerHeading != widget.workerHeading ||
        oldWidget.center?.lat != widget.center?.lat ||
        oldWidget.center?.lng != widget.center?.lng ||
        oldWidget.showDestinationPin != widget.showDestinationPin;

    if (changed) {
      _refreshAnnotations(fitCamera: false);
    }
  }

  Future<void> _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    _startImage = await _loadAsset('assets/icons/start.png');
    _stopImage = await _loadAsset('assets/icons/stop.png');
    _bikeImage = await _loadAsset('assets/icons/bike_marker.png');
    await mapboxMap.scaleBar.updateSettings(ScaleBarSettings(enabled: false));
    await mapboxMap.compass.updateSettings(CompassSettings(enabled: false));
    await mapboxMap.logo.updateSettings(
      LogoSettings(marginBottom: 8, marginLeft: 8),
    );
    await mapboxMap.attribution.updateSettings(
      AttributionSettings(marginBottom: 8, marginRight: 8),
    );
    await mapboxMap.gestures.updateSettings(
      GesturesSettings(
        scrollEnabled: true,
        pinchToZoomEnabled: true,
        doubleTapToZoomInEnabled: true,
        quickZoomEnabled: true,
        pitchEnabled: false,
      ),
    );

    _polylineManager = await mapboxMap.annotations
        .createPolylineAnnotationManager();
    _polygonManager = await mapboxMap.annotations
        .createPolygonAnnotationManager();
    _pointManager = await mapboxMap.annotations.createPointAnnotationManager();

    await _refreshAnnotations();
  }

  Future<Uint8List?> _loadAsset(String path) async {
    try {
      final data = await DefaultAssetBundle.of(context).load(path);
      return data.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  void _onCameraChanged() {
    if (widget.onLocationChanged == null && widget.onMapIdled == null) return;
    _idleDebounce?.cancel();
    // Only fire onLocationChanged during drag (continuous updates).
    if (widget.onLocationChanged != null) {
      _idleDebounce = Timer(
        const Duration(milliseconds: 350),
        _notifyLocationChanged,
      );
    }
  }

  void _onMapIdle() {
    _idleDebounce?.cancel();
    // Fire onMapIdled ONCE when map becomes idle.
    if (widget.onMapIdled != null) {
      _notifyMapIdled();
    } else if (widget.onLocationChanged != null) {
      // Legacy: fallback for callers that only use onLocationChanged.
      _notifyLocationChanged();
    }
  }

  Future<void> _notifyLocationChanged() async {
    final map = _mapboxMap;
    if (map == null || !mounted || widget.onLocationChanged == null) return;
    try {
      final camera = await map.getCameraState();
      final lat = camera.center.coordinates.lat.toDouble();
      final lng = camera.center.coordinates.lng.toDouble();
      widget.onLocationChanged!(MapCoordinate(lat: lat, lng: lng));
    } catch (e) {
      debugPrint('FixlyMapView _notifyLocationChanged error: $e');
    }
  }

  Future<void> _notifyMapIdled() async {
    final map = _mapboxMap;
    if (map == null || !mounted || widget.onMapIdled == null) return;
    try {
      final camera = await map.getCameraState();
      final lat = camera.center.coordinates.lat.toDouble();
      final lng = camera.center.coordinates.lng.toDouble();
      widget.onMapIdled!(MapCoordinate(lat: lat, lng: lng));
    } catch (e) {
      debugPrint('FixlyMapView _notifyMapIdled error: $e');
    }
  }

  Future<void> _zoomIn() async {
    final mapboxMap = _mapboxMap;
    if (mapboxMap == null) return;
    try {
      final camera = await mapboxMap.getCameraState();
      await mapboxMap.setCamera(
        CameraOptions(zoom: (camera.zoom + 1.0).clamp(2.0, 20.0)),
      );
    } catch (e) {
      debugPrint('FixlyMapView zoomIn error: $e');
    }
  }

  Future<void> _zoomOut() async {
    final mapboxMap = _mapboxMap;
    if (mapboxMap == null) return;
    try {
      final camera = await mapboxMap.getCameraState();
      await mapboxMap.setCamera(
        CameraOptions(zoom: (camera.zoom - 1.0).clamp(2.0, 20.0)),
      );
    } catch (e) {
      debugPrint('FixlyMapView zoomOut error: $e');
    }
  }

  Future<void> _recenter() async {
    final mapboxMap = _mapboxMap;
    final center = widget.center ?? MapConstants.current;
    if (mapboxMap == null || center == null) return;
    try {
      await mapboxMap.setCamera(
        CameraOptions(
          center: Point(coordinates: Position(center.lng, center.lat)),
          zoom: widget.zoom,
        ),
      );
    } catch (e) {
      debugPrint('FixlyMapView recenter error: $e');
    }
  }

  Future<void> _refreshAnnotations({bool fitCamera = true}) async {
    final polylineManager = _polylineManager;
    final polygonManager = _polygonManager;
    final pointManager = _pointManager;
    if (polylineManager == null ||
        polygonManager == null ||
        pointManager == null) {
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
      final coordinates = widget.routeCoordinates.length >= 2
          ? widget.routeCoordinates
          : [start, widget.routeEnd!];
      final route = LineString(
        coordinates: coordinates
            .map((coordinate) => Position(coordinate.lng, coordinate.lat))
            .toList(),
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
        geometry: Point(
          coordinates: Position(destination.lng, destination.lat),
        ),
        image: _stopImage,
        iconImage: _stopImage == null ? 'marker-15' : null,
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

    if (start != null) {
      final startOptions = PointAnnotationOptions(
        geometry: Point(coordinates: Position(start.lng, start.lat)),
        image: _startImage,
        iconImage: _startImage == null ? 'marker-15' : null,
        iconSize: 0.7,
        iconAnchor: IconAnchor.BOTTOM,
        textField: 'Worker',
      );
      if (_startMarker == null) {
        _startMarker = await pointManager.create(startOptions);
      } else {
        _startMarker!
          ..geometry = startOptions.geometry
          ..image = startOptions.image;
        await pointManager.update(_startMarker!);
      }
    }

    if (worker != null) {
      final workerOptions = PointAnnotationOptions(
        geometry: Point(coordinates: Position(worker.lng, worker.lat)),
        image: _bikeImage,
        iconImage: _bikeImage == null ? 'car-15' : null,
        iconSize: 0.8,
        iconColor: _bikeImage == null ? AppColors.primary.toARGB32() : null,
        iconRotate:
            widget.workerHeading ??
            (start != null && widget.routeEnd != null
                ? NavigationMath.bikeIconRotation(start, widget.routeEnd!)
                : 0),
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
          ..image = workerOptions.image
          ..iconRotate = workerOptions.iconRotate
          ..textField = workerOptions.textField;
        await pointManager.update(_workerMarker!);
      }
    } else if (_workerMarker != null) {
      await pointManager.delete(_workerMarker!);
      _workerMarker = null;
    }

    if (fitCamera) await _fitCamera();
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
      routeCoordinates: widget.routeCoordinates,
    );

    if (points.length <= 1) {
      await mapboxMap.setCamera(
        CameraOptions(
          center: Point(coordinates: Position(center.lng, center.lat)),
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
            key: const ValueKey('fixly-map-canvas'),
            styleUri: MapboxStyles.MAPBOX_STREETS,
            textureView: true,
            gestureRecognizers: widget.claimGestures
                ? <Factory<OneSequenceGestureRecognizer>>{
                    Factory<EagerGestureRecognizer>(EagerGestureRecognizer.new),
                  }
                : null,
            viewport: CameraViewportState(
              center: Point(coordinates: Position(center.lng, center.lat)),
              zoom: widget.zoom,
            ),
            onMapCreated: _onMapCreated,
            onCameraChangeListener: (_) => _onCameraChanged(),
            onMapIdleListener: (_) => _onMapIdle(),
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
            message:
                _mapError ??
                (MapConstants.hasToken ? null : 'Add ACCESS_TOKEN for Mapbox'),
          );

    final mapChild = Stack(
      fit: StackFit.expand,
      children: [
        mapCore,
        // sprite icons (marker-15) often missing — center pin always visible for location maps
        if (widget.showDestinationPin &&
            widget.routeEnd == null &&
            _mapError == null &&
            MapConstants.hasToken)
          IgnorePointer(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 28),
                child: Icon(
                  Icons.location_on_rounded,
                  size: 48,
                  color: AppColors.accent,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (widget.routeEnd != null &&
            _mapError == null &&
            MapConstants.hasToken)
          const Positioned(top: 12, left: 12, child: _MapLegend()),
        if (widget.showZoomControls &&
            MapConstants.hasToken &&
            _mapError == null)
          Positioned(
            right: 12,
            bottom: 12,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.showRecenterButton) ...[
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    elevation: 3,
                    shadowColor: Colors.black.withValues(alpha: 0.2),
                    child: _MapControlBtn(
                      icon: Icons.my_location_rounded,
                      tooltip: 'My location',
                      onTap: _recenter,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _MapControlBtn(
                        icon: Icons.add_rounded,
                        tooltip: 'Zoom in',
                        onTap: _zoomIn,
                      ),
                      Container(
                        width: 24,
                        height: 1,
                        color: Colors.grey.withValues(alpha: 0.25),
                      ),
                      _MapControlBtn(
                        icon: Icons.remove_rounded,
                        tooltip: 'Zoom out',
                        onTap: _zoomOut,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );

    final content = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: widget.borderRadius,
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.8),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(borderRadius: widget.borderRadius, child: mapChild),
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
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
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

class _MapControlBtn extends StatelessWidget {
  const _MapControlBtn({required this.icon, required this.onTap, this.tooltip});

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Tooltip(
          message: tooltip ?? '',
          child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(icon, size: 20, color: AppColors.onSurface),
          ),
        ),
      ),
    );
  }
}
