import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/data/mock/mock_repository.dart';
import '../../../../shared/models/models.dart';

part 'app_session_state.dart';

class AppSessionCubit extends Cubit<AppSessionState> {
  AppSessionCubit({MockRepository? repository})
      : _repo = repository ?? MockRepository.instance,
        super(AppSessionState(locale: (repository ?? MockRepository.instance).locale));

  final MockRepository _repo;

  void setLocale(String locale) {
    _repo.locale = locale;
    emit(state.copyWith(locale: locale));
  }

  void setRole(String role) {
    final userRole = role == 'worker' ? UserRole.worker : UserRole.customer;
    _repo.selectedRole = userRole;
    emit(state.copyWith(role: role));
  }

  void setAuthFlow(AuthFlow flow) {
    emit(state.copyWith(authFlow: flow));
  }

  Future<bool> signInWithGoogle() => _completeMockAuth(provider: 'Google');

  Future<bool> signInWithFacebook() => _completeMockAuth(provider: 'Facebook');

  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    emit(state.copyWith(email: email, status: AppSessionStatus.loading));
    await _repo.mockDelay();
    _finishAuthSession(
      name: _nameFromEmail(email),
      email: email,
    );
    return true;
  }

  Future<bool> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    emit(state.copyWith(email: email, status: AppSessionStatus.loading));
    await _repo.mockDelay();
    _finishAuthSession(
      name: _nameFromEmail(email),
      email: email,
    );
    return true;
  }

  Future<void> sendOtp(String phone) async {
    emit(state.copyWith(phone: phone, status: AppSessionStatus.loading));
    await _repo.mockDelay();
    emit(state.copyWith(status: AppSessionStatus.otpSent));
  }

  Future<bool> verifyOtp(String otp) async {
    emit(state.copyWith(status: AppSessionStatus.loading));
    await _repo.mockDelay();
    if (otp == AppConstants.mockOtp) {
      _finishAuthSession(phone: state.phone);
      return true;
    }
    emit(state.copyWith(status: AppSessionStatus.otpFailed));
    return false;
  }

  void resetOtpStatus() {
    emit(state.copyWith(status: AppSessionStatus.otpSent));
  }

  String postAuthRoute() {
    if (state.role == 'worker') {
      return RouteNames.workerOnboardingPersonal;
    }
    return RouteNames.customerHome;
  }

  Future<bool> _completeMockAuth({required String provider}) async {
    emit(state.copyWith(status: AppSessionStatus.loading));
    await _repo.mockDelay();
    _finishAuthSession(name: '$provider User');
    return true;
  }

  void _finishAuthSession({
    String? name,
    String? email,
    String? phone,
  }) {
    final role = _repo.selectedRole ?? UserRole.customer;
    _repo.currentUser = AppUser(
      id: 'u1',
      name: name ?? 'Priya Sharma',
      phone: phone ?? state.phone ?? '',
      role: role,
    );
    emit(
      state.copyWith(
        email: email ?? state.email,
        phone: phone ?? state.phone,
        status: AppSessionStatus.authenticated,
      ),
    );
  }

  String _nameFromEmail(String email) {
    final local = email.split('@').first.trim();
    if (local.isEmpty) return 'Fixly User';
    return local
        .split(RegExp(r'[._-]+'))
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
  }
}
