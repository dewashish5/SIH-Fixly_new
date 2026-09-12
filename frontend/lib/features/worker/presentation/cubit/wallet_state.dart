part of 'wallet_cubit.dart';

enum WalletStatus { initial, loading, loaded, failure }

class WalletState extends Equatable {
  const WalletState({
    this.status = WalletStatus.initial,
    this.balance = 0,
    this.totalEarnings = 0,
    this.pendingBalance = 0,
    this.transactions = const [],
    this.payoutMethod,
    this.upiId,
    this.accountHolderName,
    this.bankAccount,
    this.ifscCode,
    this.bankName,
    this.isWithdrawing = false,
    this.isUpdatingPayout = false,
    this.actionSuccessMessage,
    this.error,
  });

  final WalletStatus status;
  final double balance;
  final double totalEarnings;
  final double pendingBalance;
  final List<WalletTransaction> transactions;
  final String? payoutMethod;
  final String? upiId;
  final String? accountHolderName;
  final String? bankAccount;
  final String? ifscCode;
  final String? bankName;
  final bool isWithdrawing;
  final bool isUpdatingPayout;
  final String? actionSuccessMessage;
  final String? error;

  bool get hasPayoutAccount =>
      (upiId != null && upiId!.trim().isNotEmpty) ||
      (bankAccount != null && bankAccount!.trim().isNotEmpty);

  WalletState copyWith({
    WalletStatus? status,
    double? balance,
    double? totalEarnings,
    double? pendingBalance,
    List<WalletTransaction>? transactions,
    String? payoutMethod,
    String? upiId,
    String? accountHolderName,
    String? bankAccount,
    String? ifscCode,
    String? bankName,
    bool? isWithdrawing,
    bool? isUpdatingPayout,
    String? actionSuccessMessage,
    String? error,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return WalletState(
      status: status ?? this.status,
      balance: balance ?? this.balance,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      pendingBalance: pendingBalance ?? this.pendingBalance,
      transactions: transactions ?? this.transactions,
      payoutMethod: payoutMethod ?? this.payoutMethod,
      upiId: upiId ?? this.upiId,
      accountHolderName: accountHolderName ?? this.accountHolderName,
      bankAccount: bankAccount ?? this.bankAccount,
      ifscCode: ifscCode ?? this.ifscCode,
      bankName: bankName ?? this.bankName,
      isWithdrawing: isWithdrawing ?? this.isWithdrawing,
      isUpdatingPayout: isUpdatingPayout ?? this.isUpdatingPayout,
      actionSuccessMessage:
          clearSuccess ? null : (actionSuccessMessage ?? this.actionSuccessMessage),
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [
        status,
        balance,
        totalEarnings,
        pendingBalance,
        transactions,
        payoutMethod,
        upiId,
        accountHolderName,
        bankAccount,
        ifscCode,
        bankName,
        isWithdrawing,
        isUpdatingPayout,
        actionSuccessMessage,
        error,
      ];
}
