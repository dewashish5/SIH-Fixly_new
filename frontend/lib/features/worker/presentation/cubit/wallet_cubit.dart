import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/data/mock/mock_repository.dart';
import '../../../payments/data/payments_api_repository.dart';

part 'wallet_state.dart';

class WalletCubit extends Cubit<WalletState> {
  WalletCubit({
    MockRepository? repository,
    PaymentsApiRepository? paymentsRepository,
  })  : _repo = repository ?? MockRepository.instance,
        _payments = paymentsRepository ?? PaymentsApiRepository(),
        super(const WalletState());

  final MockRepository _repo;
  final PaymentsApiRepository _payments;

  Future<void> load() async {
    emit(state.copyWith(status: WalletStatus.loading));
    final snap = await _payments.walletHistory();
    if (snap.history.isEmpty && snap.balance == 0) {
      // Fall back to mock display if API empty/failed.
      emit(
        WalletState(
          status: WalletStatus.loaded,
          balance: _repo.walletBalance,
          transactions: List.from(_repo.walletTransactions),
        ),
      );
      return;
    }
    final txs = snap.history.map((e) {
      final amount = (e['amount'] as num?)?.toDouble() ?? 0;
      return WalletTransaction(
        id: (e['_id'] ?? e['id'] ?? e['orderId'] ?? '').toString(),
        label: (e['status'] ?? e['paymentMethod'] ?? 'Transaction').toString(),
        amount: amount.abs(),
        isCredit: amount >= 0,
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
  }
}
