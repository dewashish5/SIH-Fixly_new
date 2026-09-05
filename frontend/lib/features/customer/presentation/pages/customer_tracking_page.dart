import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/map_constants.dart';
import '../../../../core/utils/toast_utils.dart';
import '../../../../core/utils/tracking_helpers.dart';
import '../../../../core/widgets/fixly_map_view.dart';
import '../../../../shared/models/models.dart';
import '../cubit/booking_flow_cubit.dart';
import '../cubit/tracking_cubit.dart';

class CustomerTrackingPage extends StatefulWidget {
  const CustomerTrackingPage({super.key, this.bookingId});

  final String? bookingId;

  @override
  State<CustomerTrackingPage> createState() => _CustomerTrackingPageState();
}

class _CustomerTrackingPageState extends State<CustomerTrackingPage> {
  bool _followWorker = true;

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

  Future<void> _makePhoneCall(String? phoneNumber) async {
    final phone = phoneNumber ?? '9876543210';
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      ToastUtils.showToast(context: context, message: 'Could not launch dialer');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Scaffold(
      body: MultiBlocListener(
        listeners: [
          BlocListener<TrackingCubit, TrackingState>(
            listenWhen: (previous, current) =>
                previous.phase != current.phase &&
                current.phase == TrackingPhase.arrived,
            listener: (context, state) {
              ToastUtils.showToast(
                context: context,
                message: 'Worker has arrived! Share your OTP to begin service.',
              );
            },
          ),
          BlocListener<BookingFlowCubit, BookingFlowState>(
            listenWhen: (previous, current) =>
                previous.step != current.step &&
                current.step == BookingStatus.arrived,
            listener: (context, state) {
              ToastUtils.showToast(
                context: context,
                message: 'Worker arrived! Share OTP to start.',
              );
            },
          ),
        ],
        child: BlocBuilder<TrackingCubit, TrackingState>(
          builder: (context, state) {
            final target = state.customerPosition;
            final worker = state.workerPosition;
            final start = state.startPosition ?? worker;
            final distStr = TrackingHelpers.formatDistance(state.distanceMeters);
            final etaStr = TrackingHelpers.formatEta(state.etaMinutes);

            return Stack(
              children: [
                // 1. Full Screen Interactive Mapbox Map
                Positioned.fill(
                  child: FixlyMapView(
                    expand: true,
                    borderRadius: BorderRadius.zero,
                    center: worker ?? target,
                    zoom: MapConstants.navigationZoom,
                    routeStart: start,
                    routeEnd: target,
                    workerPosition: worker,
                    workerHeading: state.workerHeading,
                    routeCoordinates: state.routeCoordinates,
                    followWorker: _followWorker,
                    claimGestures: true,
                    showZoomControls: true,
                    showRecenterButton: true,
                  ),
                ),

                // 2. Floating Top Header
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        // Back Button
                        Material(
                          color: Colors.white,
                          shape: const CircleBorder(),
                          elevation: 4,
                          shadowColor: Colors.black26,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
                            onPressed: () => context.pop(),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Live Socket Connection Pill
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.95),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: state.isSocketConnected
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFFF59E0B),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    state.isSocketConnected
                                        ? 'LIVE TRACKING ACTIVE'
                                        : 'SYNCING LOCATION...',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                      color: state.isSocketConnected
                                          ? const Color(0xFF065F46)
                                          : const Color(0xFF92400E),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 3. Floating "Follow Worker" toggle
                Positioned(
                  right: 16,
                  top: 110,
                  child: Material(
                    color: _followWorker ? AppColors.primary : Colors.white,
                    shape: const CircleBorder(),
                    elevation: 4,
                    shadowColor: Colors.black26,
                    child: IconButton(
                      tooltip: _followWorker ? 'Free camera' : 'Follow bike',
                      icon: Icon(
                        _followWorker ? Icons.navigation : Icons.navigation_outlined,
                        color: _followWorker ? Colors.white : AppColors.primary,
                        size: 22,
                      ),
                      onPressed: () {
                        setState(() => _followWorker = !_followWorker);
                        ToastUtils.showToast(
                          context: context,
                          message: _followWorker ? 'Camera following worker' : 'Free map control enabled',
                        );
                      },
                    ),
                  ),
                ),

                // 4. Draggable Bottom Sheet with Worker & Booking Details
                DraggableScrollableSheet(
                  initialChildSize: 0.38,
                  minChildSize: 0.22,
                  maxChildSize: 0.65,
                  builder: (context, scrollController) {
                    return Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 16,
                            offset: Offset(0, -4),
                          ),
                        ],
                      ),
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                        children: [
                          // Sheet Drag Handle
                          Center(
                            child: Container(
                              width: 40,
                              height: 4,
                              margin: const EdgeInsets.only(bottom: 14),
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),

                          // ETA & Distance Banner
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    etaStr,
                                    style: theme.textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$distStr away • ${state.phaseLabelFor(l10n.locale)}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: state.phase == TrackingPhase.arrived
                                      ? const Color(0xFFD1FAE5)
                                      : const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  state.phase == TrackingPhase.arrived
                                      ? 'ARRIVED'
                                      : 'ON THE WAY',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: state.phase == TrackingPhase.arrived
                                        ? const Color(0xFF065F46)
                                        : AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),

                          // Worker Info Card
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 26,
                                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                                  child: const Icon(Icons.person, color: AppColors.primary, size: 28),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        state.workerName ?? 'Assigned Professional',
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          const Icon(Icons.star_rounded, size: 16, color: Color(0xFFF59E0B)),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${state.workerRating ?? 4.8} rating',
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text('• Bike en route', style: theme.textTheme.bodySmall),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.phone, color: AppColors.primary),
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    elevation: 2,
                                  ),
                                  onPressed: () => _makePhoneCall(state.workerPhone),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Start OTP Card
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFBEB),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFFDE68A)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Start Service OTP',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF92400E),
                                      ),
                                    ),
                                    Text(
                                      'Share with worker on arrival',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFFB45309),
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFFF59E0B)),
                                  ),
                                  child: Text(
                                    state.arrivalOtp ?? '8492',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 3,
                                      color: Color(0xFF92400E),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Destination Address Card
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.location_on, color: AppColors.accent, size: 22),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n.destination,
                                        style: theme.textTheme.labelMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        context.read<BookingFlowCubit>().state.address ??
                                            'Customer location',
                                        style: theme.textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
