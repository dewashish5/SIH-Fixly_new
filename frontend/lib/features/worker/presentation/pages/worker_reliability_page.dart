import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../../shared/data/mock/mock_repository.dart';
import '../../../../core/constants/app_strings.dart';

class WorkerReliabilityPage extends StatelessWidget {
  const WorkerReliabilityPage({super.key});

  @override
  Widget build(BuildContext context) {
    final score = MockRepository.instance.reliabilityScore;

    return AppScaffold(
      title: context.l10n.reliabilityScore,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: SizedBox(
              width: 160,
              height: 160,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 160,
                    height: 160,
                    child: CircularProgressIndicator(
                      value: score / 100,
                      strokeWidth: 12,
                      backgroundColor: AppColors.surfaceContainer,
                      color: AppColors.secondary,
                    ),
                  ),
                  Text(
                    '$score%',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MetricRow(label: 'On-time arrival', value: '98%'),
                SizedBox(height: 12),
                _MetricRow(label: 'Job completion', value: '96%'),
                SizedBox(height: 12),
                _MetricRow(label: 'Customer rating', value: '4.9'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Higher reliability gets priority in job matching.',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
