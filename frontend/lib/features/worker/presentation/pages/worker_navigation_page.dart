import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/map_constants.dart';
import '../../../../core/location/app_location.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../../core/widgets/fixly_map_view.dart';
import '../../../../shared/models/models.dart';
import '../../../bookings/data/bookings_api_repository.dart';
import '../../../../core/utils/toast_utils.dart';

class WorkerNavigationPage extends StatefulWidget {
  const WorkerNavigationPage({super.key, this.bookingId});

  final String? bookingId;

  @override
  State<WorkerNavigationPage> createState() => _WorkerNavigationPageState();
}

class _WorkerNavigationPageState extends State<WorkerNavigationPage> {
  final _bookings = BookingsApiRepository();
  WorkerJob? _job;
  MapCoordinate? _workerPosition;
  MapCoordinate? _destination;
  List<MapCoordinate> _route = const [];
  Timer? _pollTimer;
  Timer? _animationTimer;
  bool _loading = true;
  bool _navigationStarted = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNavigation();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _animationTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadNavigation() async {
    try {
      final job = widget.bookingId == null
          ? null
          : await _bookings.workerJobById(widget.bookingId!);
      final current = AppLocation.instance.coordinateOrNull;
      final destination =
          job == null || job.customerLat == null || job.customerLng == null
          ? MapConstants.current
          : MapCoordinate(
              lat: job.customerLat!,
              lng: job.customerLng!,
              label: 'Customer',
            );
      if (!mounted) return;
      setState(() {
        _job = job;
        _workerPosition = current ?? MapConstants.workerApproachStart;
        _destination = destination;
        _loading = false;
        _error = destination == null ? 'Waiting for location permission' : null;
      });
      await _loadRoute();
      if (widget.bookingId != null) {
        _pollTimer = Timer.periodic(
          const Duration(seconds: 5),
          (_) => _pollPosition(),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _loadRoute() async {
    final from = _workerPosition;
    final to = _destination;
    if (from == null || to == null || !MapConstants.hasToken) return;
    try {
      final route = await _bookings.fetchDrivingRoute(from: from, to: to);
      if (mounted && route.length >= 2) setState(() => _route = route);
    } catch (_) {
      // The map keeps its local fallback line when directions are unavailable.
    }
  }

  Future<void> _pollPosition() async {
    final bookingId = widget.bookingId;
    if (bookingId == null) return;
    try {
      final next = await _bookings.trackWorkerPosition(bookingId);
      if (next == null || !mounted) return;
      _animateWorkerTo(next);
      await _loadRoute();
    } catch (_) {
      // Keep the last known position while a polling request is unavailable.
    }
  }

  void _animateWorkerTo(MapCoordinate target) {
    final start = _workerPosition ?? target;
    _animationTimer?.cancel();
    var tick = 0;
    _animationTimer = Timer.periodic(const Duration(milliseconds: 100), (
      timer,
    ) {
      tick++;
      final progress = (tick / 10).clamp(0.0, 1.0);
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(
        () => _workerPosition = MapConstants.lerpRoute(start, target, progress),
      );
      if (progress >= 1) timer.cancel();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final destination = _destination;
    final worker = _workerPosition;

    if (_loading) {
      return AppScaffold(
        title: l10n.navigation,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return AppScaffold(
      title: l10n.navigation,
      padding: EdgeInsets.zero,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: destination == null
                  ? Center(
                      child: Text(_error ?? 'Customer location unavailable'),
                    )
                  : FixlyMapView(
                      expand: true,
                      borderRadius: BorderRadius.circular(20),
                      center: destination,
                      zoom: MapConstants.navigationZoom,
                      routeEnd: destination,
                      routeStart: worker,
                      routeCoordinates: _route,
                      routeProgress: 0,
                      claimGestures: true,
                      showZoomControls: true,
                      showRecenterButton: true,
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppCard(
                  child: Row(
                    children: [
                      const Icon(Icons.route_rounded, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _job?.address ??
                                  destination?.label ??
                                  'Customer location',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            Text(
                              _route.length >= 2
                                  ? 'Road route • Live location updates every 5 seconds'
                                  : 'Live route to customer',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                PrimaryButton(
                  label: _navigationStarted
                      ? 'Navigation active'
                      : l10n.startNavigation,
                  onPressed: _navigationStarted
                      ? null
                      : () {
                          setState(() => _navigationStarted = true);
                          ToastUtils.showToast(context: context, message: l10n.navigationStarted);
                        },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
