import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/router/route_names.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/widgets/core_widgets.dart';
import '../../../../../core/constants/app_strings.dart';

class WorkerAvailabilityPage extends StatelessWidget {
  const WorkerAvailabilityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: context.l10n.availability,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'When can you take jobs?',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
          const AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Weekdays', style: TextStyle(fontWeight: FontWeight.w600)),
                SizedBox(height: 8),
                Text('9:00 AM – 6:00 PM'),
                SizedBox(height: 16),
                Text('Weekends', style: TextStyle(fontWeight: FontWeight.w600)),
                SizedBox(height: 8),
                Text('10:00 AM – 4:00 PM'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'You can change availability anytime from the dashboard.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
          ),
          const Spacer(),
          PrimaryButton(
            label: 'Go to dashboard',
            onPressed: () => context.go(RouteNames.workerDashboard),
          ),
        ],
      ),
    );
  }
}
