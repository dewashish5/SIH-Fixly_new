import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../../core/widgets/fixly_map_view.dart';
import '../../../../core/constants/map_constants.dart';
import '../cubit/booking_flow_cubit.dart';
import '../cubit/tracking_cubit.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/models/models.dart';
import '../../../../core/utils/toast_utils.dart';

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
      body: MultiBlocListener(
        listeners: [
          BlocListener<TrackingCubit, TrackingState>(
            listenWhen: (previous, current) =>
                previous.phase != current.phase &&
                current.phase == TrackingPhase.arrived,
            listener: (context, state) {
              ScaffoldMessenger.of(context).showMaterialBanner(
                MaterialBanner(
                  content: const Text('Worker is nearby!'),
                  leading: const Icon(Icons.info_outline),
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  actions: [
                    TextButton(
                      onPressed: () => ScaffoldMessenger.of(context).hideCurrentMaterialBanner(),
                      child: const Text('DISMISS'),
                    ),
                  ],
                ),
              );
              Future.delayed(const Duration(seconds: 5), () {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
                }
              });
            },
          ),
          BlocListener<BookingFlowCubit, BookingFlowState>(
            listenWhen: (previous, current) =>
                previous.step != current.step &&
                current.step == BookingStatus.arrived,
            listener: (context, state) {
              ToastUtils.showToast(context: context, message: 'Worker has arrived! Check your booking for OTP.');
            },
          ),
        ],
        child: BlocBuilder<TrackingCubit, TrackingState>(
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
                  if (state.phase == TrackingPhase.arrived) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.near_me, color: AppColors.primary),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Worker is nearby! They will arrive shortly.',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
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
      ),
    );
  }
}
