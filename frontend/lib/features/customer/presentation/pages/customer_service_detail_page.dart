import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../../shared/models/models.dart';
import '../../../home/data/home_api_repository.dart';
import '../cubit/booking_flow_cubit.dart';

class CustomerServiceDetailPage extends StatefulWidget {
  const CustomerServiceDetailPage({required this.serviceId, super.key});

  final String serviceId;

  @override
  State<CustomerServiceDetailPage> createState() =>
      _CustomerServiceDetailPageState();
}

class _CustomerServiceDetailPageState extends State<CustomerServiceDetailPage> {
  late final Future<ServiceItem> _future =
      HomeApiRepository().fetchService(widget.serviceId);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ServiceItem>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const AppScaffold(
            title: 'Service',
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError || !snap.hasData) {
          return AppScaffold(
            title: context.l10n.service,
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text(snap.error?.toString() ?? 'Service not found'),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    label: 'Go Back',
                    onPressed: () => context.pop(),
                  ),
                ],
              ),
            ),
          );
        }

        final service = snap.data!;
        return BlocProvider(
          create: (_) => BookingFlowCubit()..selectService(service),
          child: AppScaffold(
            title: service.title,
            body: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 180,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.handyman,
                      size: 64,
                      color: AppColors.primary,
                    ),
                  ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95)),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Icon(Icons.star, color: AppColors.accent, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        '${service.rating}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Spacer(),
                      Text(
                        'From ₹${service.priceFrom.toInt()}',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: AppColors.primary,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'About this service',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    service.description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  const _FeatureRow(icon: Icons.verified, text: 'Verified workers'),
                  const _FeatureRow(
                    icon: Icons.schedule,
                    text: 'Same-day availability',
                    color: AppColors.accent,
                  ),
                  const _FeatureRow(icon: Icons.shield, text: 'Insurance covered'),
                  const SizedBox(height: 32),
                  AccentButton(
                    label: 'Book Now',
                    onPressed: () => context.push(RouteNames.customerBooking),
                  ),
                  const SizedBox(height: 12),
                  SecondaryButton(
                    label: 'View Workers',
                    onPressed: () => context.push(RouteNames.customerWorkers),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.text,
    this.color = AppColors.primary,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
