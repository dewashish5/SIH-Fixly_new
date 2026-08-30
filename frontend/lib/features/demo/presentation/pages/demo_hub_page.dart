import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../../core/constants/app_strings.dart';

class DemoHubPage extends StatelessWidget {
  const DemoHubPage({super.key});

  static const _phases = <_DemoPhase>[
    _DemoPhase(
      title: 'Onboarding',
      routes: [
        _DemoRoute('Splash', RouteNames.splash),
        _DemoRoute('Language', RouteNames.language),
        _DemoRoute('Cooperative', RouteNames.cooperative),
        _DemoRoute('Role Picker', RouteNames.role),
        _DemoRoute('Login', RouteNames.login),
        _DemoRoute('OTP', RouteNames.otp),
      ],
    ),
    _DemoPhase(
      title: 'Customer',
      routes: [
        _DemoRoute('Home', RouteNames.customerHome),
        _DemoRoute('Search', RouteNames.customerSearch),
        _DemoRoute('Categories', RouteNames.customerCategories),
        _DemoRoute('Booking', RouteNames.customerBooking),
        _DemoRoute('Price Estimate', RouteNames.customerPriceEstimate),
        _DemoRoute('Finding Worker', RouteNames.customerFindingWorker),
        _DemoRoute('Worker Accepted', RouteNames.customerWorkerAccepted),
        _DemoRoute('Tracking', RouteNames.customerTracking),
        _DemoRoute('Work Started', RouteNames.customerWorkStarted),
        _DemoRoute('Payment', RouteNames.customerPayment),
        _DemoRoute('Rating', RouteNames.customerRating),
        _DemoRoute('AI Helper', RouteNames.customerAiHelper),
        _DemoRoute('Workers', RouteNames.customerWorkers),
      ],
    ),
    _DemoPhase(
      title: 'Worker Onboarding',
      routes: [
        _DemoRoute('Identity & KYC', RouteNames.workerOnboardingIdentity),
        _DemoRoute('Skills & area', RouteNames.workerOnboardingWork),
        _DemoRoute('Payout & welfare', RouteNames.workerOnboardingPayout),
        _DemoRoute('Status', RouteNames.workerOnboardingStatus),
      ],
    ),
    _DemoPhase(
      title: 'Worker App',
      routes: [
        _DemoRoute('Dashboard', RouteNames.workerDashboard),
        _DemoRoute('Jobs', RouteNames.workerJobs),
        _DemoRoute('Incoming', RouteNames.workerIncoming),
        _DemoRoute('Active Job', RouteNames.workerActiveJob),
        _DemoRoute('Navigation', RouteNames.workerNavigation),
        _DemoRoute('Earnings', RouteNames.workerEarnings),
        _DemoRoute('Wallet', RouteNames.workerWallet),
        _DemoRoute('Profile', RouteNames.workerProfileTab),
        _DemoRoute('Reliability', RouteNames.workerReliability),
      ],
    ),
    _DemoPhase(
      title: 'Shared',
      routes: [
        _DemoRoute('Profile', RouteNames.sharedProfile),
        _DemoRoute('Settings', RouteNames.sharedSettings),
        _DemoRoute('Notifications', RouteNames.sharedNotifications),
        _DemoRoute('Order History', RouteNames.sharedOrderHistory),
        _DemoRoute('SOS', RouteNames.sharedSos),
        _DemoRoute('Support Chat', RouteNames.sharedSupportChat),
      ],
    ),
    _DemoPhase(
      title: 'System States',
      routes: [
        _DemoRoute('No Internet', '/system/noInternet'),
        _DemoRoute('Booking Confirmed', '/system/bookingConfirmed'),
        _DemoRoute('Payment Failed', '/system/paymentFailed'),
        _DemoRoute('KYC Submitted', '/system/kycSubmitted'),
        _DemoRoute('No Workers', '/system/noWorkersNearby'),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: context.l10n.screenGallery,
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.only(top: 16, bottom: 24),
              itemCount: _phases.length,
              separatorBuilder: (_, _) => const SizedBox(height: 24),
              itemBuilder: (context, index) {
                final phase = _phases[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      phase.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.primary,
                          ),
                    ),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 2.4,
                      ),
                      itemCount: phase.routes.length,
                      itemBuilder: (context, routeIndex) {
                        final route = phase.routes[routeIndex];
                        return _RouteTile(
                          label: route.label,
                          path: route.path,
                          onTap: () => context.push(route.path),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DemoPhase {
  const _DemoPhase({required this.title, required this.routes});

  final String title;
  final List<_DemoRoute> routes;
}

class _DemoRoute {
  const _DemoRoute(this.label, this.path);

  final String label;
  final String path;
}

class _RouteTile extends StatelessWidget {
  const _RouteTile({
    required this.label,
    required this.path,
    required this.onTap,
  });

  final String label;
  final String path;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                path,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontSize: 10,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
