import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/data/mock/mock_repository.dart';

part 'support_state.dart';

class SupportCubit extends Cubit<SupportState> {
  SupportCubit({MockRepository? repository})
      : _repo = repository ?? MockRepository.instance,
        super(const SupportState());

  final MockRepository _repo;

  Future<void> loadChat() async {
    emit(state.copyWith(status: SupportStatus.loading));
    await _repo.mockDelay();
    emit(
      SupportState(
        status: SupportStatus.loaded,
        messages: List.from(_repo.supportMessages),
      ),
    );
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    _repo.addSupportMessage(text.trim());
    emit(
      state.copyWith(
        messages: List.from(_repo.supportMessages),
      ),
    );
  }

  Future<void> submitTicket({
    required String subject,
    required String description,
  }) async {
    emit(state.copyWith(status: SupportStatus.submitting));
    await _repo.mockDelay();
    emit(
      state.copyWith(
        status: SupportStatus.ticketSubmitted,
        lastTicketSubject: subject,
      ),
    );
  }
}
