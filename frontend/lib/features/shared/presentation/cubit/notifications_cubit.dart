import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/data/mock/mock_repository.dart';
import '../../../../shared/models/models.dart';

part 'notifications_state.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit({MockRepository? repository})
      : _repo = repository ?? MockRepository.instance,
        super(const NotificationsState());

  final MockRepository _repo;

  Future<void> load() async {
    emit(state.copyWith(status: NotificationsStatus.loading));
    await _repo.mockDelay();
    emit(
      NotificationsState(
        status: NotificationsStatus.loaded,
        items: List.from(_repo.notifications),
      ),
    );
  }

  void markAllRead() {
    final updated = _repo.notifications
        .map(
          (n) => NotificationItem(
            id: n.id,
            title: n.title,
            body: n.body,
            time: n.time,
            read: true,
          ),
        )
        .toList();
    _repo.notifications
      ..clear()
      ..addAll(updated);
    emit(state.copyWith(items: updated));
  }
}
