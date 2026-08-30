import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../cubit/booking_flow_cubit.dart';
import '../../../../core/constants/app_strings.dart';

class CustomerRatingPage extends StatefulWidget {
  const CustomerRatingPage({super.key});

  @override
  State<CustomerRatingPage> createState() => _CustomerRatingPageState();
}

class _CustomerRatingPageState extends State<CustomerRatingPage> {
  int _rating = 5;
  final _feedbackController = TextEditingController();

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final workerName =
        context.read<BookingFlowCubit>().state.booking?.workerName ??
            'Worker';

    return AppScaffold(
      title: context.l10n.rateService,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
            Text(
              'How was your experience?',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Rate $workerName',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.outline,
                  ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final star = index + 1;
                return IconButton(
                  iconSize: 44,
                  tooltip: '$star',
                  onPressed: () => setState(() => _rating = star),
                  icon: Icon(
                    star <= _rating ? Icons.star : Icons.star_border,
                    color: AppColors.tertiary,
                  ),
                ).animate(delay: (index * 80).ms).scale(
                      begin: const Offset(0.5, 0.5),
                      duration: 300.ms,
                    );
              }),
            ),
            const SizedBox(height: 24),
            AppTextField(
              controller: _feedbackController,
              label: 'Feedback (optional)',
              hint: 'Tell us about your experience...',
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                'Professional',
                'On time',
                'Quality work',
                'Friendly',
              ]
                  .map(
                    (tag) => ActionChip(
                      label: Text(tag),
                      onPressed: () {
                        _feedbackController.text =
                            '${_feedbackController.text} $tag'.trim();
                      },
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              label: 'Submit Rating',
              onPressed: () =>
                  context.push(RouteNames.customerBookingConfirmation),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () =>
                  context.push(RouteNames.customerBookingConfirmation),
              child: const Text('Skip'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
