part of 'wallet_cubit.dart';

enum WalletStatus { initial, loading, loaded, failure }

class WalletState extends Equatable {
  const WalletState({
    this.status = WalletStatus.initial,
    this.balance = 0,
    this.totalEarnings = 0,
    this.transactions = const [],
    this.error,
  });

  final WalletStatus status;
  final double balance;
  final double totalEarnings;
  final List<WalletTransaction> transactions;
  final String? error;

  WalletState copyWith({
    WalletStatus? status,
    double? balance,
    double? totalEarnings,
    List<WalletTransaction>? transactions,
    String? error,
    bool clearError = false,
  }) {
    return WalletState(
      status: status ?? this.status,
      balance: balance ?? this.balance,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      transactions: transactions ?? this.transactions,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props =>
      [status, balance, totalEarnings, transactions, error];
}
