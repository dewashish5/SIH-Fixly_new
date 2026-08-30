import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../../shared/models/models.dart';
import '../cubit/booking_flow_cubit.dart';
import '../../../../core/constants/app_strings.dart';

class CustomerFindingWorkerPage extends StatefulWidget {
  const CustomerFindingWorkerPage({super.key});

  @override
  State<CustomerFindingWorkerPage> createState() =>
      _CustomerFindingWorkerPageState();
}

class _CustomerFindingWorkerPageState extends State<CustomerFindingWorkerPage> {
  @override
  void initState() {
    super.initState();
    _startSearch();
  }

  Future<void> _startSearch() async {
    final cubit = context.read<BookingFlowCubit>();
    await cubit.searchWorker();
    await cubit.workerAccepted();
    if (mounted) {
      context.pushReplacement(RouteNames.customerWorkerAccepted);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: context.l10n.findingWorker,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.search,
                  size: 56,
                  color: AppColors.primary,
                ),
              )
                  .animate(onPlay: (c) => c.repeat())
                  .scale(
                    begin: const Offset(0.9, 0.9),
                    end: const Offset(1.1, 1.1),
                    duration: 1200.ms,
                  )
                  .then()
                  .scale(
                    begin: const Offset(1.1, 1.1),
                    end: const Offset(0.9, 0.9),
                    duration: 1200.ms,
                  ),
              const SizedBox(height: 32),
              Text(
                'Searching nearby workers...',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 12),
              Text(
                'Matching you with verified professionals in your area',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.outline,
                    ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 400.ms),
              const SizedBox(height: 40),
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              BlocBuilder<BookingFlowCubit, BookingFlowState>(
                builder: (context, state) {
                  return Text(
                    state.step == BookingStatus.searching
                        ? 'Scanning 12 workers nearby...'
                        : 'Almost done...',
                    style: Theme.of(context).textTheme.bodySmall,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
