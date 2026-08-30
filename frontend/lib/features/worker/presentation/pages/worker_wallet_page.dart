import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../cubit/wallet_cubit.dart';
import '../../../../core/constants/app_strings.dart';

class WorkerWalletPage extends StatefulWidget {
  const WorkerWalletPage({super.key});

  @override
  State<WorkerWalletPage> createState() => _WorkerWalletPageState();
}

class _WorkerWalletPageState extends State<WorkerWalletPage> {
  @override
  void initState() {
    super.initState();
    context.read<WalletCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('d MMM');

    return BlocBuilder<WalletCubit, WalletState>(
      builder: (context, state) {
        return AppScaffold(
          title: context.l10n.wallet,
          showBack: false,
          body: state.status == WalletStatus.loading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Balance',
                              style: Theme.of(context).textTheme.labelMedium),
                          Text(
                            '₹${state.balance.toStringAsFixed(0)}',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('Transactions',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.separated(
                        itemCount: state.transactions.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final tx = state.transactions[index];
                          final sign = tx.isCredit ? '+' : '-';
                          final color =
                              tx.isCredit ? AppColors.success : AppColors.error;

                          return AppCard(
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(tx.label),
                                      if (tx.date != null)
                                        Text(
                                          dateFormat.format(tx.date!),
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '$sign₹${tx.amount.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    PrimaryButton(
                      label: 'Withdraw (mock)',
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Withdrawal initiated')),
                        );
                      },
                    ),
                  ],
                ),
        );
      },
    );
  }
}
