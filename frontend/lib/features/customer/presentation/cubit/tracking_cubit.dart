import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/map_constants.dart';
import '../../../../core/network/live_tracking_socket.dart';
import '../../../../core/utils/navigation_math.dart';
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
  Timer? _pollTimer;
  Timer? _animationTimer;

  Future<void> startTracking({
    String? bookingId,
    String? workerName,
    MapCoordinate? destination,
  }) async {
    _pollTimer?.cancel();
    await _socketSubscription?.cancel();
    final current = AppLocation.instance.coordinateOrNull;
    var target = destination;
    var name = workerName;
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
      } catch (_) {}
    }
    emit(
      TrackingState(
        isActive: bookingId != null,
        workerName: name,
        workerPosition: current,
        customerPosition: target,
        phase: TrackingPhase.enRoute,
      ),
    );
    if (bookingId == null) return;
    if (current != null && target != null) {
      try {
        final route = await _bookings.fetchDrivingRoute(
          from: current,
          to: target,
        );
        if (!isClosed && route.length >= 2) {
          emit(state.copyWith(routeCoordinates: route));
        }
      } catch (_) {}
    }
    _socket.connect(bookingId);
    _socketSubscription = _socket.positions.listen(_onPosition);
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      try {
        final position = await _bookings.trackWorkerPosition(bookingId);
        if (position != null) _onPosition(position);
      } catch (_) {}
    });
  }

  void _onPosition(MapCoordinate position) {
    final target = state.customerPosition;
    if (target == null) {
      emit(state.copyWith(workerPosition: position));
      return;
    }
    final previous = state.workerPosition ?? position;
    _animationTimer?.cancel();
    var tick = 0;
    _animationTimer = Timer.periodic(const Duration(milliseconds: 80), (timer) {
      tick++;
      final progress = (tick / 12).clamp(0.0, 1.0);
      final current = MapConstants.lerpRoute(previous, position, progress);
      final distance = NavigationMath.distanceMeters(current, target);
      final phase = distance <= 500
          ? TrackingPhase.arrived
          : distance <= 2000
          ? TrackingPhase.nearby
          : TrackingPhase.enRoute;
      emit(
        state.copyWith(
          workerPosition: current,
          phase: phase,
          isActive: phase != TrackingPhase.arrived,
        ),
      );
      if (progress >= 1) timer.cancel();
    });
  }

  void reset() {
    _pollTimer?.cancel();
    _animationTimer?.cancel();
    _socketSubscription?.cancel();
    _socket.disconnect();
    emit(const TrackingState());
  }

  @override
  Future<void> close() {
    _pollTimer?.cancel();
    _animationTimer?.cancel();
    _socketSubscription?.cancel();
    _socket.dispose();
    return super.close();
  }
}
