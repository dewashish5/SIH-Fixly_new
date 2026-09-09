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
        final transactionId = (e['transactionId'] ?? e['paymentId'] ?? '')
            .toString();
        final type = (e['type'] ?? 'CREDIT').toString();
        final rawDescription = (e['description'] ?? '').toString();
        final description = rawDescription.isNotEmpty
            ? rawDescription
            : transactionId.isNotEmpty
                ? '$type • $transactionId'
                : '$type • Payment';
        return WalletTransaction(
          id: (e['_id'] ?? e['id'] ?? e['orderId'] ?? transactionId)
              .toString(),
          label: description,
          amount: amount.abs(),
          isCredit: type.toUpperCase() != 'DEBIT',
          date: DateTime.tryParse(e['createdAt']?.toString() ?? '') ??
              DateTime.now(),
          transactionId:
              transactionId.isNotEmpty ? transactionId : null,
          status: e['status']?.toString(),
          type: type,
        );
      }).toList();
      emit(
        WalletState(
          status: WalletStatus.loaded,
          balance: snap.balance,
          totalEarnings: snap.totalEarnings,
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
