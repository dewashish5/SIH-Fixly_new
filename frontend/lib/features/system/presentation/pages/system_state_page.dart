import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/theme_x.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../../shared/data/mock/mock_repository.dart';
import '../../../../shared/models/models.dart';
import '../system_state_type.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/toast_utils.dart';

class SystemStatePage extends StatelessWidget {
  const SystemStatePage({required this.typeParam, super.key});

  final String typeParam;

  @override
  Widget build(BuildContext context) {
    final type = SystemStateTypeX.fromPath(typeParam);

    final l10n = context.l10n;

    if (type == null) {
      return AppScaffold(
        title: l10n.unknownState,
        body: Center(child: Text('${l10n.unknownState}: $typeParam')),
      );
    }

    return AppScaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: type.accentColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(type.icon, size: 48, color: type.accentColor),
              ),
              const SizedBox(height: 24),
              Text(
                type.localizedTitle(l10n),
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                type.message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: context.muted,
                    ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              PrimaryButton(
                label: type.localizedAction(l10n),
                onPressed: () => _onPrimaryAction(context, type),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.pop(),
                child: Text(l10n.goBack),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onPrimaryAction(BuildContext context, SystemStateType type) {
    switch (type) {
      case SystemStateType.noOrders:
      case SystemStateType.noEarnings:
        context.go(RouteNames.workerDashboard);
      case SystemStateType.noWorkersNearby:
        context.go(RouteNames.workerOnboardingWork);
      case SystemStateType.noNotifications:
      case SystemStateType.ratingSubmitted:
        context.go(RouteNames.customerHome);
      case SystemStateType.noSearchResults:
        context.go(RouteNames.customerCategories);
      case SystemStateType.noInternet:
      case SystemStateType.serverError:
      case SystemStateType.otpFailed:
      case SystemStateType.paymentFailed:
      case SystemStateType.bookingFailed:
        context.pop();
      case SystemStateType.gpsDenied:
      case SystemStateType.cameraDenied:
        ToastUtils.showToast(context: context, message: 'Open device settings (mock)');
      case SystemStateType.kycFailed:
        context.go(RouteNames.workerOnboardingIdentity);
      case SystemStateType.sessionExpired:
        context.go(RouteNames.login);
      case SystemStateType.timeoutError:
      case SystemStateType.accountSuspended:
        context.push(RouteNames.sharedSupportTicket);
      case SystemStateType.bookingConfirmed:
        context.go(RouteNames.customerTracking);
      case SystemStateType.paymentSuccessful:
        context.go(RouteNames.customerPayment);
      case SystemStateType.kycSubmitted:
        context.go(RouteNames.workerOnboardingStatus);
      case SystemStateType.profileUpdated:
        context.go(
          MockRepository.instance.selectedRole == UserRole.worker
              ? RouteNames.workerProfileTab
              : RouteNames.customerProfileTab,
        );
      case SystemStateType.complaintSubmitted:
        context.go(RouteNames.sharedSupportChat);
    }
  }
}
