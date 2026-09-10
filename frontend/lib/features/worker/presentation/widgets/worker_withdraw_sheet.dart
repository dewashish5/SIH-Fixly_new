import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/theme_x.dart';
import '../../../../core/utils/toast_utils.dart';
import '../cubit/wallet_cubit.dart';
import 'worker_payout_account_sheet.dart';

/// Modal bottom sheet allowing workers to initiate withdrawals
/// with preset chips, threshold checking, and payout account previews.
class WorkerWithdrawSheet extends StatefulWidget {
  const WorkerWithdrawSheet({
    super.key,
    required this.availableBalance,
    this.upiId,
    this.bankAccount,
    this.accountHolderName,
    this.bankName,
    this.payoutMethod,
  });

  final double availableBalance;
  final String? upiId;
  final String? bankAccount;
  final String? accountHolderName;
  final String? bankName;
  final String? payoutMethod;

  static Future<bool?> show(
    BuildContext context, {
    required double availableBalance,
    String? upiId,
    String? bankAccount,
    String? accountHolderName,
    String? bankName,
    String? payoutMethod,
  }) {
    final walletCubit = context.read<WalletCubit>();

    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BlocProvider<WalletCubit>.value(
        value: walletCubit,
        child: WorkerWithdrawSheet(
          availableBalance: availableBalance,
          upiId: upiId,
          bankAccount: bankAccount,
          accountHolderName: accountHolderName,
          bankName: bankName,
          payoutMethod: payoutMethod,
        ),
      ),
    );
  }

  @override
  State<WorkerWithdrawSheet> createState() => _WorkerWithdrawSheetState();
}

class _WorkerWithdrawSheetState extends State<WorkerWithdrawSheet> {
  final _amountController = TextEditingController();
  double _selectedAmount = 0;
  String? _validationError;

  static const double _minWithdrawal = 100;

  @override
  void initState() {
    super.initState();
    // Default to full balance if between 100 and 2000, else default to 500 or 100
    if (widget.availableBalance >= _minWithdrawal) {
      final initial = widget.availableBalance >= 500 ? 500.0 : widget.availableBalance;
      _setAmount(initial);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _setAmount(double amount) {
    setState(() {
      _selectedAmount = amount;
      _amountController.text = amount > 0 ? amount.toStringAsFixed(0) : '';
      _validate(amount);
    });
  }

  void _validate(double amount) {
    if (amount <= 0) {
      _validationError = 'Please enter an amount';
    } else if (amount < _minWithdrawal) {
      _validationError = 'Minimum withdrawal is ₹${_minWithdrawal.toStringAsFixed(0)}';
    } else if (amount > widget.availableBalance) {
      _validationError = 'Amount exceeds available balance (₹${widget.availableBalance.toStringAsFixed(0)})';
    } else {
      _validationError = null;
    }
  }

  bool get _hasPayoutAccount =>
      (widget.upiId != null && widget.upiId!.trim().isNotEmpty) ||
      (widget.bankAccount != null && widget.bankAccount!.trim().isNotEmpty);

  Future<void> _handleWithdraw(BuildContext context) async {
    final entered = double.tryParse(_amountController.text.trim()) ?? 0;
    _validate(entered);
    if (_validationError != null) {
      ToastUtils.showError(context: context, message: _validationError!);
      return;
    }

    if (!_hasPayoutAccount) {
      ToastUtils.showError(
        context: context,
        message: 'Please link a UPI ID or Bank account first',
      );
      _openAccountSetup(context);
      return;
    }

    HapticFeedback.mediumImpact();
    final cubit = context.read<WalletCubit>();
    final nav = Navigator.of(context);
    final success = await cubit.withdraw(entered);
    if (success && mounted) {
      nav.pop(true);
    }
  }

  void _openAccountSetup(BuildContext context) {
    WorkerPayoutAccountSheet.show(
      context,
      initialMethod: widget.payoutMethod,
      initialUpi: widget.upiId,
      initialAccountNumber: widget.bankAccount,
      initialAccountName: widget.accountHolderName,
      initialBankName: widget.bankName,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scheme = context.scheme;
    final primaryColor = scheme.primary;

    return BlocBuilder<WalletCubit, WalletState>(
      builder: (context, state) {
        final currentUpi = state.upiId ?? widget.upiId;
        final currentBank = state.bankAccount ?? widget.bankAccount;
        final currentName = state.accountHolderName ?? widget.accountHolderName;
        final hasAccount = (currentUpi != null && currentUpi.trim().isNotEmpty) ||
            (currentBank != null && currentBank.trim().isNotEmpty);

        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Drag Handle
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.black12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.arrow_upward_rounded,
                            color: primaryColor,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Withdraw to Account',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Available: ₹${widget.availableBalance.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1),

                  const SizedBox(height: 16),

                  // Amount input field
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Enter Withdrawal Amount',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : const Color(0xFF334155),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: false),
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                            letterSpacing: -0.5,
                          ),
                          decoration: InputDecoration(
                            prefixIcon: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                              child: Text(
                                '₹',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                            prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                            suffixIcon: _amountController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 20),
                                    onPressed: () => _setAmount(0),
                                  )
                                : null,
                            hintText: '0',
                            filled: true,
                            fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: _validationError != null
                                    ? Colors.red
                                    : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: _validationError != null ? Colors.red : primaryColor,
                                width: 2,
                              ),
                            ),
                          ),
                          onChanged: (val) {
                            final parsed = double.tryParse(val.trim()) ?? 0;
                            setState(() {
                              _selectedAmount = parsed;
                              _validate(parsed);
                            });
                          },
                        ),
                        if (_validationError != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            _validationError!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Preset Quick Amount Chips
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _QuickChip(
                            label: '₹200',
                            isSelected: _selectedAmount == 200,
                            primaryColor: primaryColor,
                            onTap: () => _setAmount(200),
                          ),
                          _QuickChip(
                            label: '₹500',
                            isSelected: _selectedAmount == 500,
                            primaryColor: primaryColor,
                            onTap: () => _setAmount(500),
                          ),
                          _QuickChip(
                            label: '₹1,000',
                            isSelected: _selectedAmount == 1000,
                            primaryColor: primaryColor,
                            onTap: () => _setAmount(1000),
                          ),
                          _QuickChip(
                            label: '₹2,000',
                            isSelected: _selectedAmount == 2000,
                            primaryColor: primaryColor,
                            onTap: () => _setAmount(2000),
                          ),
                          if (widget.availableBalance >= _minWithdrawal)
                            _QuickChip(
                              label: 'Full (₹${widget.availableBalance.toStringAsFixed(0)})',
                              isSelected: _selectedAmount == widget.availableBalance,
                              primaryColor: primaryColor,
                              onTap: () => _setAmount(widget.availableBalance),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Destination Account Preview Card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: hasAccount
                                  ? const Color(0xFF10B981).withValues(alpha: 0.12)
                                  : Colors.amber.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              hasAccount
                                  ? (currentUpi != null && currentUpi.isNotEmpty
                                      ? Icons.bolt_rounded
                                      : Icons.account_balance_rounded)
                                  : Icons.warning_amber_rounded,
                              size: 20,
                              color: hasAccount
                                  ? const Color(0xFF10B981)
                                  : Colors.amber.shade800,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  hasAccount
                                      ? (currentUpi != null && currentUpi.isNotEmpty
                                          ? 'Payout to UPI'
                                          : 'Payout to Bank Account')
                                      : 'No Payout Account Linked',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  hasAccount
                                      ? (currentUpi != null && currentUpi.isNotEmpty
                                          ? currentUpi
                                          : '${currentName ?? 'Bank'} (••${currentBank != null && currentBank.length >= 4 ? currentBank.substring(currentBank.length - 4) : ''})')
                                      : 'Add your UPI ID or Bank account to receive funds',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () => _openAccountSetup(context),
                            style: TextButton.styleFrom(
                              foregroundColor: primaryColor,
                              visualDensity: VisualDensity.compact,
                            ),
                            child: Text(hasAccount ? 'Change' : 'Link Now'),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Terms Summary List
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTermRow(
                          icon: Icons.check_circle_outline_rounded,
                          text: 'Minimum withdrawal ₹100 • 0% platform fee',
                          isDark: isDark,
                        ),
                        const SizedBox(height: 6),
                        _buildTermRow(
                          icon: Icons.schedule_rounded,
                          text: 'Instant credit to UPI • 2-4 hours for IMPS/NEFT bank accounts',
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Confirm & Withdraw Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: state.isWithdrawing ? null : () => _handleWithdraw(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          elevation: 0,
                        ),
                        child: state.isWithdrawing
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _selectedAmount > 0
                                    ? 'Withdraw ₹${_selectedAmount.toStringAsFixed(0)}'
                                    : 'Withdraw Funds',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTermRow({
    required IconData icon,
    required String text,
    required bool isDark,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: isDark ? Colors.white54 : const Color(0xFF64748B),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 11.5,
              color: isDark ? Colors.white60 : const Color(0xFF64748B),
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({
    required this.label,
    required this.isSelected,
    required this.primaryColor,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final Color primaryColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected
                ? primaryColor
                : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? primaryColor
                  : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.white70 : const Color(0xFF334155)),
            ),
          ),
        ),
      ),
    );
  }
}
