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
    final user = _repo.currentUser;
    emit(
      ProfileState(
        status: ProfileStatus.loaded,
        name: user?.name ?? '',
        phone: user?.phone ?? '',
        eshramUan: user?.eshramUan ?? _repo.onboardingData.eshramUan,
        insured: user?.insured ?? false,
        skills: _repo.onboardingData.skills,
      ),
    );
  }

  Future<void> updateProfile({required String name, required String phone}) async {
    emit(state.copyWith(status: ProfileStatus.loading));
    if (_repo.currentUser != null) {
      _repo.currentUser = AppUser(
        id: _repo.currentUser!.id,
        name: name,
        phone: phone,
        email: _repo.currentUser!.email,
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
