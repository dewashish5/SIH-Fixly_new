part of 'wallet_cubit.dart';

enum WalletStatus { initial, loading, loaded, failure }

class WalletState extends Equatable {
  const WalletState({
    this.status = WalletStatus.initial,
    this.balance = 0,
    this.transactions = const [],
  });

  final WalletStatus status;
  final double balance;
  final List<WalletTransaction> transactions;

  WalletState copyWith({
    WalletStatus? status,
    double? balance,
    List<WalletTransaction>? transactions,
  }) {
    return WalletState(
      status: status ?? this.status,
      balance: balance ?? this.balance,
      transactions: transactions ?? this.transactions,
    );
  }

  @override
  List<Object?> get props => [status, balance, transactions];
}
