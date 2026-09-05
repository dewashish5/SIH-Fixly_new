import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../../core/widgets/fixly_map_view.dart';
import '../../../../core/constants/map_constants.dart';
import '../cubit/booking_flow_cubit.dart';
import '../cubit/tracking_cubit.dart';
import '../../../../core/constants/app_strings.dart';

class CustomerTrackingPage extends StatefulWidget {
  const CustomerTrackingPage({super.key, this.bookingId});

  final String? bookingId;

  @override
  State<CustomerTrackingPage> createState() => _CustomerTrackingPageState();
}

class _CustomerTrackingPageState extends State<CustomerTrackingPage> {
  @override
  void initState() {
    super.initState();
    final booking = context.read<BookingFlowCubit>().state.booking;
    context.read<TrackingCubit>().startTracking(
      bookingId: widget.bookingId ?? booking?.id,
      workerName: booking?.workerName,
      destination: booking?.customerLat == null || booking?.customerLng == null
          ? null
          : MapCoordinate(
              lat: booking!.customerLat!,
              lng: booking.customerLng!,
              label: 'Customer',
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppScaffold(
      title: l10n.liveTracking,
      body: BlocBuilder<TrackingCubit, TrackingState>(
        builder: (context, state) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FixlyMapView(
                  height: 320,
                  borderRadius: BorderRadius.circular(20),
                  center: state.customerPosition,
                  zoom: MapConstants.navigationZoom,
                  routeEnd: state.customerPosition,
                  routeStart: state.workerPosition,
                  routeCoordinates: state.routeCoordinates,
                  routeProgress: 0,
                  claimGestures: true,
                  showZoomControls: true,
                  showRecenterButton: true,
                ),
                const SizedBox(height: 24),
                Text(
                  state.phaseLabelFor(l10n.locale),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  state.workerName ?? l10n.worker,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                Text(
                  state.workerPosition == null
                      ? 'Waiting for live worker location'
                      : 'Live location updates are active',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 32),
                AppCard(
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, color: AppColors.accent),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.destination,
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                            Text(
                              context.read<BookingFlowCubit>().state.address ??
                                  'Customer location',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}
