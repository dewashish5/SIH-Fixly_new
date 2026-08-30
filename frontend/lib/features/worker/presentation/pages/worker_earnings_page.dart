import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../../shared/data/mock/mock_repository.dart';
import '../../../../core/constants/app_strings.dart';

class WorkerEarningsPage extends StatelessWidget {
  const WorkerEarningsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = MockRepository.instance;

    return AppScaffold(
      title: context.l10n.earnings,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Today', style: Theme.of(context).textTheme.labelMedium),
                Text(
                  '₹${repo.todayEarnings.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppColors.secondary,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('This month (mock)',
                    style: Theme.of(context).textTheme.labelMedium),
                Text(
                  '₹${(repo.todayEarnings * 18).toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Recent payouts', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: repo.walletTransactions.length,
              itemBuilder: (context, index) {
                final tx = repo.walletTransactions[index];
                if (!tx.isCredit) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AppCard(
                    child: Row(
                      children: [
                        Expanded(child: Text(tx.label)),
                        Text(
                          '+₹${tx.amount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
