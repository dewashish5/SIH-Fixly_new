import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/theme_x.dart';
import '../../../../core/widgets/app_motion.dart';
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
    final dateFormat = DateFormat('d MMM yyyy, hh:mm a');
    final scheme = context.scheme;

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
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            scheme.primary,
                            scheme.primary.withValues(alpha: 0.82),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Available balance',
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                  color: scheme.onPrimary.withValues(
                                    alpha: 0.8,
                                  ),
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '₹${state.balance.toStringAsFixed(0)}',
                            style: Theme.of(context)
                                .textTheme
                                .headlineLarge
                                ?.copyWith(
                                  color: scheme.onPrimary,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _StatChip(
                                  label: 'Total earnings',
                                  value:
                                      '₹${state.totalEarnings.toStringAsFixed(0)}',
                                  onPrimary: scheme.onPrimary,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _StatChip(
                                  label: 'Transactions',
                                  value: '${state.transactions.length}',
                                  onPrimary: scheme.onPrimary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Transaction history',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: state.transactions.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.account_balance_wallet_outlined,
                                    size: 64,
                                    color: scheme.outline,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No transactions yet',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(color: context.muted),
                                  ),
                                ],
                              ),
                            )
                          : AppRefreshIndicator(
                              onRefresh: () =>
                                  context.read<WalletCubit>().load(),
                              child: ListView.separated(
                                physics: appRefreshScrollPhysics,
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  24,
                                ),
                                itemCount: state.transactions.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final tx = state.transactions[index];
                                  final sign = tx.isCredit ? '+' : '-';
                                  final color = tx.isCredit
                                      ? scheme.tertiary
                                      : scheme.error;
                                  final payId = tx.transactionId ?? '';

                                  return AppCard(
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            color: color.withValues(
                                              alpha: 0.14,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            tx.isCredit
                                                ? Icons
                                                    .arrow_downward_rounded
                                                : Icons.arrow_upward_rounded,
                                            color: color,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                tx.label,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleSmall
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                maxLines: 2,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                              ),
                                              if (payId.isNotEmpty) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Razorpay ID: $payId',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                        color: context.muted,
                                                      ),
                                                ),
                                              ],
                                              if (tx.date != null) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  dateFormat.format(tx.date!),
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                        color: context.muted,
                                                      ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '$sign₹${tx.amount.toStringAsFixed(0)}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                color: color,
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ).appListEnter(
                                    context,
                                    index: index,
                                    id: tx.id,
                                  );
                                },
                              ),
                            ),
                    ),
                    if (state.balance > 0)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: PrimaryButton(
                          label:
                              'Withdraw ₹${state.balance.toStringAsFixed(0)}',
                          onPressed: () {
                            context
                                .read<WalletCubit>()
                                .withdraw(state.balance);
                          },
                        ),
                      ),
                  ],
                ),
        );
      },
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.onPrimary,
  });

  final String label;
  final String value;
  final Color onPrimary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: onPrimary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: onPrimary.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: onPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
