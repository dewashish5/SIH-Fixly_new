import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/theme_x.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/toast_utils.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../../shared/models/models.dart';
import '../cubit/wallet_cubit.dart';
import '../widgets/worker_payout_account_sheet.dart';
import '../widgets/worker_withdraw_sheet.dart';

class WorkerWalletPage extends StatefulWidget {
  const WorkerWalletPage({super.key});

  @override
  State<WorkerWalletPage> createState() => _WorkerWalletPageState();
}

class _WorkerWalletPageState extends State<WorkerWalletPage> {
  String _selectedTxFilter = 'ALL'; // 'ALL', 'EARNINGS', 'WITHDRAWALS'

  @override
  void initState() {
    super.initState();
    context.read<WalletCubit>().load();
  }

  void _openPayoutSettings(BuildContext context, WalletState state) {
    WorkerPayoutAccountSheet.show(
      context,
      initialMethod: state.payoutMethod,
      initialUpi: state.upiId,
      initialAccountNumber: state.bankAccount,
      initialAccountName: state.accountHolderName,
      initialIfsc: state.ifscCode,
      initialBankName: state.bankName,
    );
  }

  void _openWithdrawModal(BuildContext context, WalletState state) {
    if (state.balance < 100) {
      ToastUtils.showToast(
        context: context,
        message: 'Minimum withdrawal is ₹100. Current available balance is ₹${state.balance.toStringAsFixed(0)}',
      );
      return;
    }

    WorkerWithdrawSheet.show(
      context,
      availableBalance: state.balance,
      upiId: state.upiId,
      bankAccount: state.bankAccount,
      accountHolderName: state.accountHolderName,
      bankName: state.bankName,
      payoutMethod: state.payoutMethod,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scheme = context.scheme;
    final primaryColor = scheme.primary;

    return BlocConsumer<WalletCubit, WalletState>(
      listener: (context, state) {
        if (state.error != null && state.error!.isNotEmpty) {
          ToastUtils.showError(context: context, message: state.error!);
        }
        if (state.actionSuccessMessage != null &&
            state.actionSuccessMessage!.isNotEmpty) {
          ToastUtils.showToast(
            context: context,
            message: state.actionSuccessMessage!,
          );
        }
      },
      builder: (context, state) {
        final transactions = state.transactions;
        final filteredTxs = transactions.where((tx) {
          if (_selectedTxFilter == 'EARNINGS') return tx.isCredit;
          if (_selectedTxFilter == 'WITHDRAWALS') return !tx.isCredit;
          return true;
        }).toList();

        return AppScaffold(
          title: context.l10n.wallet,
          showBack: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.account_balance_outlined),
              tooltip: 'Payout Settings',
              onPressed: () => _openPayoutSettings(context, state),
            ),
          ],
          body: state.status == WalletStatus.loading && transactions.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : AppRefreshIndicator(
                  onRefresh: () => context.read<WalletCubit>().load(),
                  child: ListView(
                    physics: appRefreshScrollPhysics,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                    children: [
                      // 1. Available Balance Hero Card
                      _buildHeroBalanceCard(context, state, isDark, primaryColor),

                      const SizedBox(height: 16),

                      // 2. Active Payout Method / Destination Card
                      _buildPayoutDestinationCard(context, state, isDark, primaryColor),

                      const SizedBox(height: 16),

                      // 3. Withdrawal Guidelines & Terms Card
                      _buildWithdrawalTermsCard(context, isDark, primaryColor),

                      const SizedBox(height: 20),

                      // 4. Transaction History Header & Filter Pills
                      _buildTransactionHistoryHeader(
                        context,
                        transactions.length,
                        isDark,
                        primaryColor,
                      ),

                      const SizedBox(height: 12),

                      // 5. Transaction Items List
                      if (filteredTxs.isEmpty)
                        _buildEmptyTransactions(context, isDark)
                      else
                        ...filteredTxs.map(
                          (tx) => _buildTransactionItem(context, tx, isDark, scheme),
                        ),
                    ],
                  ),
                ),
        );
      },
    );
  }

  // 1. Hero Balance Card
  Widget _buildHeroBalanceCard(
    BuildContext context,
    WalletState state,
    bool isDark,
    Color primaryColor,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1E3A8A),
            primaryColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Label and Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Available for Withdrawal',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.82),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF34D399),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Ready to Withdraw',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Balance Display
          Text(
            '₹${state.balance.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -1,
            ),
          ),

          const SizedBox(height: 16),

          // Action Buttons: Withdraw Funds & Payout Settings
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _openWithdrawModal(context, state),
                  icon: const Icon(Icons.arrow_upward_rounded, size: 18),
                  label: const Text(
                    'Withdraw Funds',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1E3A8A),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: () => _openPayoutSettings(context, state),
                icon: const Icon(Icons.settings_outlined, size: 17),
                label: const Text('Account'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(
                    color: Colors.white.withValues(alpha: 0.35),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Divider(color: Colors.white.withValues(alpha: 0.15), height: 1),
          const SizedBox(height: 14),

          // Quick stats row: Total Lifetime Earned & Pending Balance
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Earned',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '₹${state.totalEarnings.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 28,
                width: 1,
                color: Colors.white.withValues(alpha: 0.15),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pending Clearance',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '₹${state.pendingBalance.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 2. Active Payout Method / Destination Card
  Widget _buildPayoutDestinationCard(
    BuildContext context,
    WalletState state,
    bool isDark,
    Color primaryColor,
  ) {
    final hasUpi = state.upiId != null && state.upiId!.trim().isNotEmpty;
    final hasBank = state.bankAccount != null && state.bankAccount!.trim().isNotEmpty;
    final isLinked = hasUpi || hasBank;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 18,
                    color: primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Payout Destination',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => _openPayoutSettings(context, state),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Text(
                    isLinked ? 'Edit Account' : 'Link Account',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          if (isLinked) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      hasUpi ? Icons.bolt_rounded : Icons.account_balance_rounded,
                      size: 20,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              hasUpi ? 'UPI Auto-Payout' : (state.bankName ?? 'Bank Account'),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                hasUpi ? 'INSTANT' : 'VERIFIED',
                                style: const TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          hasUpi
                              ? state.upiId!
                              : 'A/C: •••• ${state.bankAccount!.length >= 4 ? state.bankAccount!.substring(state.bankAccount!.length - 4) : state.bankAccount} • IFSC: ${state.ifscCode ?? ''}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white60 : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? const Color(0xFFB45309).withValues(alpha: 0.3) : const Color(0xFFFDE68A),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 22,
                    color: Colors.amber.shade800,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'No Payout Account Linked',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.amber.shade300 : const Color(0xFF92400E),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Link your UPI ID or Bank Account to withdraw your earnings.',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark ? Colors.white70 : const Color(0xFFB45309),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 3. Withdrawal Guidelines & Terms Card
  Widget _buildWithdrawalTermsCard(
    BuildContext context,
    bool isDark,
    Color primaryColor,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.verified_outlined,
                size: 18,
                color: primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                'Withdrawal Guidelines & Terms',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          _buildTermBullet(
            icon: Icons.account_balance_outlined,
            title: 'Payout Destination',
            description:
                'Withdrawals are transferred directly into the UPI ID or Bank Account submitted during registration or profile setup.',
            isDark: isDark,
            primaryColor: primaryColor,
          ),
          const SizedBox(height: 10),
          _buildTermBullet(
            icon: Icons.speed_rounded,
            title: 'Transfer Time',
            description:
                'UPI withdrawals are processed within seconds. IMPS/NEFT bank transfers credit within 2–4 business hours.',
            isDark: isDark,
            primaryColor: primaryColor,
          ),
          const SizedBox(height: 10),
          _buildTermBullet(
            icon: Icons.currency_rupee_rounded,
            title: 'Minimum Withdrawal',
            description:
                'Minimum withdrawal limit is ₹100. There are 0% platform deductions or hidden charges on payouts.',
            isDark: isDark,
            primaryColor: primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildTermBullet({
    required IconData icon,
    required String title,
    required String description,
    required bool isDark,
    required Color primaryColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 2),
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 14, color: primaryColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 1),
              Text(
                description,
                style: TextStyle(
                  fontSize: 11.5,
                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 4. Transaction History Header & Filter Pills
  Widget _buildTransactionHistoryHeader(
    BuildContext context,
    int totalCount,
    bool isDark,
    Color primaryColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Transaction History',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            Text(
              '$totalCount total',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white54 : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('ALL', 'All', primaryColor, isDark),
              const SizedBox(width: 8),
              _buildFilterChip('EARNINGS', 'Earnings (+)', primaryColor, isDark),
              const SizedBox(width: 8),
              _buildFilterChip('WITHDRAWALS', 'Withdrawals (-)', primaryColor, isDark),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(
    String key,
    String label,
    Color primaryColor,
    bool isDark,
  ) {
    final isSelected = _selectedTxFilter == key;

    return InkWell(
      onTap: () => setState(() => _selectedTxFilter = key),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? primaryColor
                : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white70 : const Color(0xFF475569)),
          ),
        ),
      ),
    );
  }

  // 5. Transaction Item Card
  Widget _buildTransactionItem(
    BuildContext context,
    WalletTransaction tx,
    bool isDark,
    ColorScheme scheme,
  ) {
    final dateFormat = DateFormat('d MMM yyyy, hh:mm a');
    final isCredit = tx.isCredit;
    final color = isCredit ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    final sign = isCredit ? '+' : '-';
    final payId = tx.transactionId ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              color: color,
              size: 19,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.label,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (payId.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    'Ref: $payId',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white54 : const Color(0xFF64748B),
                    ),
                  ),
                ],
                if (tx.date != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    dateFormat.format(tx.date!),
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                ],
                if (tx.status != null) ...[
                  const SizedBox(height: 5),
                  _buildStatusBadge(tx.status!),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$sign₹${tx.amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTransactions(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 40,
              color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
            ),
            const SizedBox(height: 10),
            Text(
              'No transactions found',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : const Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Completed jobs and withdrawal payouts will appear here.',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white54 : const Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    final s = status.toUpperCase();
    if (s == 'REQUESTED') {
      color = Colors.amber.shade700;
    } else if (s == 'PROCESSING') {
      color = Colors.orange;
    } else if (s == 'PAID' || s == 'COMPLETED' || s == 'SUCCESS') {
      color = const Color(0xFF10B981);
    } else if (s == 'REJECTED' || s == 'FAILED') {
      color = Colors.red;
    } else {
      color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        s,
        style: TextStyle(
          color: color,
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
