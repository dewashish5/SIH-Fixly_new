import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../shared/data/mock/mock_repository.dart';
import '../../../auth/data/auth_api_repository.dart';

part 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit({
    MockRepository? repository,
    AuthApiRepository? authRepository,
  })  : _repo = repository ?? MockRepository.instance,
        _auth = authRepository ?? AuthApiRepository(),
        super(const ProfileState());

  final MockRepository _repo;
  final AuthApiRepository _auth;

  Future<void> load() async {
    emit(state.copyWith(status: ProfileStatus.loading, clearError: true));
    try {
      final user = await _auth.fetchMe();
      _repo.currentUser = user;
      emit(
        ProfileState(
          status: ProfileStatus.loaded,
          name: user.name,
          phone: user.phone,
          email: user.email,
          eshramUan: user.eshramUan ?? _repo.onboardingData.eshramUan,
          insured: user.insured,
          skills: _repo.onboardingData.skills,
        ),
      );
    } on ApiException catch (e) {
      final user = _repo.currentUser;
      emit(
        ProfileState(
          status: ProfileStatus.loaded,
          name: user?.name ?? '',
          phone: user?.phone ?? '',
          email: user?.email ?? '',
          eshramUan: user?.eshramUan ?? _repo.onboardingData.eshramUan,
          insured: user?.insured ?? false,
          skills: _repo.onboardingData.skills,
          errorMessage: e.message,
        ),
      );
    } catch (_) {
      final user = _repo.currentUser;
      emit(
        ProfileState(
          status: ProfileStatus.loaded,
          name: user?.name ?? '',
          phone: user?.phone ?? '',
          email: user?.email ?? '',
          eshramUan: user?.eshramUan ?? _repo.onboardingData.eshramUan,
          insured: user?.insured ?? false,
          skills: _repo.onboardingData.skills,
        ),
      );
    }
  }

  Future<void> updateProfile({required String name, required String phone}) async {
    emit(state.copyWith(status: ProfileStatus.loading, clearError: true));
    try {
      final user = await _auth.updateProfile(name: name, phone: phone);
      _repo.currentUser = user;
      emit(
        state.copyWith(
          status: ProfileStatus.updated,
          name: user.name,
          phone: user.phone,
          email: user.email,
        ),
      );
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          status: ProfileStatus.error,
          errorMessage: e.message,
        ),
      );
      rethrow;
    }
  }
}
