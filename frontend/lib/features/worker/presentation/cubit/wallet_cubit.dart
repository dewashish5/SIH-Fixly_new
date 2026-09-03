import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../shared/models/models.dart';
import '../../../payments/data/payments_api_repository.dart';

part 'wallet_state.dart';

class WalletCubit extends Cubit<WalletState> {
  WalletCubit({PaymentsApiRepository? paymentsRepository})
      : _payments = paymentsRepository ?? PaymentsApiRepository(),
        super(const WalletState());

  final PaymentsApiRepository _payments;

  Future<void> load() async {
    emit(state.copyWith(status: WalletStatus.loading, clearError: true));
    try {
      final snap = await _payments.workerWallet();
      final txs = snap.history.map((e) {
        final amount = (e['amount'] as num?)?.toDouble() ?? 0;
        return WalletTransaction(
          id: (e['_id'] ?? e['id'] ?? e['orderId'] ?? '').toString(),
          label: (e['status'] ?? e['paymentMethod'] ?? 'Transaction').toString(),
          amount: amount.abs(),
          isCredit: true,
          date: DateTime.tryParse(e['createdAt']?.toString() ?? '') ??
              DateTime.now(),
        );
      }).toList();
      emit(
        WalletState(
          status: WalletStatus.loaded,
          balance: snap.balance,
          transactions: txs,
        ),
      );
    } on ApiException catch (e) {
      emit(state.copyWith(status: WalletStatus.failure, error: e.message));
    }
  }

  Future<void> withdraw(double amount) async {
    try {
      await _payments.withdraw(amount);
      await load();
    } on ApiException catch (e) {
      emit(state.copyWith(error: e.message));
    }
  }
}
