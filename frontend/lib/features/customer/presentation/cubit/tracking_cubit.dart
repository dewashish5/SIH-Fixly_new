import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/map_constants.dart';
import '../../../../core/network/live_tracking_socket.dart';
import '../../../../core/utils/tracking_helpers.dart';
import '../../../../core/location/app_location.dart';
import '../../../bookings/data/bookings_api_repository.dart';

part 'tracking_state.dart';

class TrackingCubit extends Cubit<TrackingState> {
  TrackingCubit({BookingsApiRepository? bookings})
    : _bookings = bookings ?? BookingsApiRepository(),
      super(const TrackingState());

  final BookingsApiRepository _bookings;
  final LiveTrackingSocket _socket = LiveTrackingSocket();
  StreamSubscription<MapCoordinate>? _socketSubscription;
  StreamSubscription<bool>? _connectionSubscription;
  Timer? _pollTimer;
  Timer? _animationTimer;

  Future<void> startTracking({
    String? bookingId,
    String? workerName,
    MapCoordinate? destination,
  }) async {
    _pollTimer?.cancel();
    _animationTimer?.cancel();
    await _socketSubscription?.cancel();
    await _connectionSubscription?.cancel();

    var target = destination;
    var name = workerName;
    String? serviceTitle;
    String? arrivalOtp;
    String? workerPhone;
    double? workerRating;
    String? workerAvatar;
    MapCoordinate? initialWorkerPos;

    if (bookingId != null) {
      try {
        final booking = await _bookings.getById(bookingId);
        target ??= booking.customerLat == null || booking.customerLng == null
            ? null
            : MapCoordinate(
                lat: booking.customerLat!,
                lng: booking.customerLng!,
                label: 'Customer',
              );
        name ??= booking.workerName;
        serviceTitle = booking.serviceTitle;
        arrivalOtp = booking.arrivalOtp;

        // Try getting latest worker position from DB/API
        try {
          initialWorkerPos = await _bookings.trackWorkerPosition(bookingId);
        } catch (_) {}
      } catch (_) {}
    }

    // Ensure customer position falls back to current device if null
    target ??= AppLocation.instance.coordinateOrNull ?? MapConstants.current;

    // Separate worker position from customer location to prevent pinpoint stacking
    if (initialWorkerPos == null && target != null) {
      // Offset worker departure point slightly southwest of customer (~1.2 km away)
      initialWorkerPos = MapCoordinate(
        lat: target.lat - 0.010,
        lng: target.lng - 0.009,
        label: 'Worker Departure',
      );
    }

    final initialHeading = (initialWorkerPos != null && target != null)
        ? TrackingHelpers.bearingDegrees(initialWorkerPos, target)
        : 0.0;

    final initialDistance = (initialWorkerPos != null && target != null)
        ? TrackingHelpers.distanceMeters(initialWorkerPos, target)
        : 1200.0;

    final initialEta = TrackingHelpers.estimateEtaMinutes(initialDistance);

    emit(
      TrackingState(
        isActive: bookingId != null,
        bookingId: bookingId,
        workerName: name,
        serviceTitle: serviceTitle,
        arrivalOtp: arrivalOtp,
        workerPhone: workerPhone,
        workerRating: workerRating ?? 4.8,
        workerAvatar: workerAvatar,
        workerPosition: initialWorkerPos,
        startPosition: initialWorkerPos,
        customerPosition: target,
        workerHeading: initialHeading,
        distanceMeters: initialDistance,
        etaMinutes: initialEta,
        phase: initialDistance <= 200 ? TrackingPhase.arrived : TrackingPhase.enRoute,
        isSocketConnected: false,
      ),
    );

    if (bookingId == null) return;

    // Load initial driving route
    if (initialWorkerPos != null && target != null) {
      _loadRoute(initialWorkerPos, target);
    }

    // Connect real-time socket
    _socket.connect(bookingId);
    _socketSubscription = _socket.positions.listen((pos) {
      _lastSocketTime = DateTime.now();
      _onPosition(pos);
    });
    _connectionSubscription = _socket.connectionState.listen((connected) {
      if (!isClosed) emit(state.copyWith(isSocketConnected: connected));
    });

    // Fallback polling every 8s — only used if socket is disconnected or hasn't emitted recently
    _pollTimer = Timer.periodic(const Duration(seconds: 8), (_) async {
      final now = DateTime.now();
      if (_socket.isConnected &&
          _lastSocketTime != null &&
          now.difference(_lastSocketTime!).inSeconds < 10) {
        // Socket is alive and fresh; skip stale HTTP DB poll to avoid pulling bike backwards!
        return;
      }
      try {
        final position = await _bookings.trackWorkerPosition(bookingId);
        if (position != null) _onPosition(position);
      } catch (_) {}
    });
  }

  DateTime? _lastSocketTime;
  int _lastPositionTimestamp = 0;

  Future<void> _loadRoute(MapCoordinate from, MapCoordinate to) async {
    try {
      final route = await _bookings.fetchDrivingRoute(from: from, to: to);
      if (!isClosed && route.length >= 2) {
        emit(state.copyWith(routeCoordinates: route));
      }
    } catch (_) {}
  }

  void _onPosition(MapCoordinate position) {
    // Timestamp order check: ignore older delayed coordinates
    if (position.timestamp != null && position.timestamp! > 0) {
      if (position.timestamp! < _lastPositionTimestamp) {
        return; // Stale packet, ignore!
      }
      _lastPositionTimestamp = position.timestamp!;
    }

    final target = state.customerPosition;
    final previous = state.workerPosition ?? position;

    final distFromPrev = TrackingHelpers.distanceMeters(previous, position);

    // Calculate heading: if jitter movement < 2.5m, preserve previous heading to prevent bike flipping 180°
    double heading;
    if (position.heading != null && position.heading! > 0) {
      heading = TrackingHelpers.normalizeHeading(position.heading!);
    } else if (distFromPrev < 2.5 && previous.heading != null && previous.heading! > 0) {
      heading = previous.heading!;
    } else {
      heading = TrackingHelpers.bearingDegrees(previous, position);
    }

    final targetPos = position.copyWith(heading: heading);

    if (target == null) {
      emit(
        state.copyWith(
          workerPosition: targetPos,
          workerHeading: heading,
        ),
      );
      return;
    }

    final totalDist = TrackingHelpers.distanceMeters(targetPos, target);
    final eta = TrackingHelpers.estimateEtaMinutes(totalDist);
    final phase = totalDist <= 150
        ? TrackingPhase.arrived
        : totalDist <= 800
            ? TrackingPhase.nearby
            : TrackingPhase.enRoute;

    // Smooth interpolation over 480ms (6 steps x 80ms)
    _animationTimer?.cancel();
    var tick = 0;
    const totalTicks = 6;
    _animationTimer = Timer.periodic(const Duration(milliseconds: 80), (timer) {
      tick++;
      final progress = (tick / totalTicks).clamp(0.0, 1.0);
      final current = TrackingHelpers.lerpCoordinate(previous, targetPos, progress);

      if (!isClosed) {
        emit(
          state.copyWith(
            workerPosition: current,
            workerHeading: heading,
            distanceMeters: totalDist,
            etaMinutes: eta,
            phase: phase,
            isActive: phase != TrackingPhase.arrived,
          ),
        );
      }
      if (progress >= 1.0) timer.cancel();
    });
  }

  void reset() {
    _pollTimer?.cancel();
    _animationTimer?.cancel();
    _socketSubscription?.cancel();
    _connectionSubscription?.cancel();
    _socket.disconnect();
    emit(const TrackingState());
  }

  @override
  Future<void> close() {
    _pollTimer?.cancel();
    _animationTimer?.cancel();
    _socketSubscription?.cancel();
    _connectionSubscription?.cancel();
    _socket.dispose();
    return super.close();
  }
}

