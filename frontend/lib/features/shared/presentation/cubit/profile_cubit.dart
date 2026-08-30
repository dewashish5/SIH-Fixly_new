import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/data/mock/mock_repository.dart';
import '../../../../shared/models/models.dart';

part 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit({MockRepository? repository})
      : _repo = repository ?? MockRepository.instance,
        super(const ProfileState());

  final MockRepository _repo;

  Future<void> load() async {
    emit(state.copyWith(status: ProfileStatus.loading));
    await _repo.mockDelay();
    final user = _repo.currentUser;
    emit(
      ProfileState(
        status: ProfileStatus.loaded,
        name: user?.name ?? 'Rajesh Kumar',
        phone: user?.phone ?? '+91 9876543210',
        eshramUan: user?.eshramUan ?? _repo.onboardingData.eshramUan,
        insured: user?.insured ?? _repo.onboardingData.hasEshram,
        skills: _repo.onboardingData.skills,
      ),
    );
  }

  Future<void> updateProfile({required String name, required String phone}) async {
    emit(state.copyWith(status: ProfileStatus.loading));
    await _repo.mockDelay();
    if (_repo.currentUser != null) {
      _repo.currentUser = AppUser(
        id: _repo.currentUser!.id,
        name: name,
        phone: phone,
        role: _repo.currentUser!.role,
        eshramUan: _repo.currentUser!.eshramUan,
        insured: _repo.currentUser!.insured,
      );
    }
    emit(
      state.copyWith(
        status: ProfileStatus.updated,
        name: name,
        phone: phone,
      ),
    );
  }
}
