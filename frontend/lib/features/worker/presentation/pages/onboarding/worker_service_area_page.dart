import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/router/route_names.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/constants/map_constants.dart';
import '../../../../../core/widgets/fixly_map_view.dart';
import '../../cubit/worker_onboarding_cubit.dart';
import 'worker_onboarding_layout.dart';
import '../../../../../core/constants/app_strings.dart';

class WorkerServiceAreaPage extends StatelessWidget {
  const WorkerServiceAreaPage({super.key});

  void _continue(BuildContext context) {
    final cubit = context.read<WorkerOnboardingCubit>();
    final error = cubit.validateStep(7);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    cubit.setStep(7);
    context.push(RouteNames.workerOnboardingWelfare);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WorkerOnboardingCubit, WorkerOnboardingState>(
      builder: (context, state) {
        final radius = state.formData.serviceRadiusKm;

        return WorkerOnboardingLayout(
          step: 7,
          title: context.l10n.serviceArea,
          onContinue: () => _continue(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.serviceAreaHint,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              FixlyMapView(
                height: 260,
                borderRadius: BorderRadius.circular(20),
                center: MapConstants.noidaSector12,
                zoom: MapConstants.serviceAreaZoom,
                serviceRadiusKm: radius,
                showDestinationPin: true,
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  '${radius.toStringAsFixed(0)} km',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppColors.primary,
                      ),
                ),
              ),
              Slider(
                value: radius,
                min: 1,
                max: 25,
                divisions: 24,
                label: '${radius.toStringAsFixed(0)} km',
                onChanged: context
                    .read<WorkerOnboardingCubit>()
                    .updateServiceRadius,
              ),
              Text(
                context.l10n.largerRadiusHint,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        );
      },
    );
  }
}
