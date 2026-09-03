part of 'wallet_cubit.dart';

enum WalletStatus { initial, loading, loaded, failure }

class WalletState extends Equatable {
  const WalletState({
    this.status = WalletStatus.initial,
    this.balance = 0,
    this.transactions = const [],
    this.error,
  });

  final WalletStatus status;
  final double balance;
  final List<WalletTransaction> transactions;
  final String? error;

  WalletState copyWith({
    WalletStatus? status,
    double? balance,
    List<WalletTransaction>? transactions,
    String? error,
    bool clearError = false,
  }) {
    return WalletState(
      status: status ?? this.status,
      balance: balance ?? this.balance,
      transactions: transactions ?? this.transactions,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [status, balance, transactions, error];
}
