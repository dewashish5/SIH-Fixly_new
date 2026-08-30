import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/data/mock/mock_repository.dart';

part 'wallet_state.dart';

class WalletCubit extends Cubit<WalletState> {
  WalletCubit({MockRepository? repository})
      : _repo = repository ?? MockRepository.instance,
        super(const WalletState());

  final MockRepository _repo;

  Future<void> load() async {
    emit(state.copyWith(status: WalletStatus.loading));
    await _repo.mockDelay();
    emit(
      WalletState(
        status: WalletStatus.loaded,
        balance: _repo.walletBalance,
        transactions: List.from(_repo.walletTransactions),
      ),
    );
  }
}
