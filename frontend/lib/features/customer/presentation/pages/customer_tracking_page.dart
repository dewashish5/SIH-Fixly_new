import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/theme_x.dart';
import '../../../../core/constants/map_constants.dart';
import '../../../../core/location/app_location.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../../core/widgets/fixly_map_view.dart';
import '../cubit/booking_flow_cubit.dart';
import '../cubit/tracking_cubit.dart';
import '../../../../core/constants/app_strings.dart';

class CustomerTrackingPage extends StatefulWidget {
  const CustomerTrackingPage({super.key});

  @override
  State<CustomerTrackingPage> createState() => _CustomerTrackingPageState();
}

class _CustomerTrackingPageState extends State<CustomerTrackingPage> {
  @override
  void initState() {
    super.initState();
    final workerName = context.read<BookingFlowCubit>().state.booking?.workerName;
    context.read<TrackingCubit>().startTracking(workerName: workerName);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppScaffold(
      title: l10n.liveTracking,
      body: BlocConsumer<TrackingCubit, TrackingState>(
        listenWhen: (prev, curr) => curr.phase == TrackingPhase.arrived,
        listener: (context, state) {
          if (state.phase == TrackingPhase.arrived) {
            Future.delayed(const Duration(seconds: 1), () {
              if (context.mounted) {
                context.push(RouteNames.customerWorkStarted);
              }
            });
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  FixlyMapView(
                  height: 320,
                  borderRadius: BorderRadius.circular(20),
                  center: MapConstants.current,
                  zoom: MapConstants.navigationZoom,
                  routeEnd: MapConstants.current,
                  routeStart: MapConstants.workerApproachStart,
                  routeProgress: state.progress,
                ).animate().fadeIn(),
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
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: state.progress,
                    minHeight: 8,
                    backgroundColor: context.scheme.surfaceContainerHighest,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.percentComplete
                          .replaceFirst('%s', '${(state.progress * 100).toInt()}'),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      state.etaMinutes > 0
                          ? l10n.etaFormat.replaceFirst(
                              '%s',
                              '${state.etaMinutes}',
                            )
                          : l10n.arrived,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
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
                              context
                                      .read<BookingFlowCubit>()
                                      .state
                                      .address ??
                                  AppLocation.instance.addressLabel ??
                                  'Current location',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (state.phase != TrackingPhase.arrived)
                  PrimaryButton(
                    label: l10n.skipToWorkStarted,
                    onPressed: () =>
                        context.push(RouteNames.customerWorkStarted),
                  ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}
