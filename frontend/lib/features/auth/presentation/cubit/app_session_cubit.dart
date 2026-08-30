import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/preferences/app_preferences.dart';
import '../../../../shared/data/mock/mock_repository.dart';
import '../../../../shared/models/models.dart';

part 'app_session_state.dart';

class AppSessionCubit extends Cubit<AppSessionState> {
  AppSessionCubit({
    MockRepository? repository,
    AppPreferences? preferences,
  })  : _repo = repository ?? MockRepository.instance,
        _prefs = preferences ?? AppPreferences.instance,
        super(
          AppSessionState(
            locale: (preferences ?? AppPreferences.instance).locale,
            themeMode: (preferences ?? AppPreferences.instance).themeMode,
            languageSelected:
                (preferences ?? AppPreferences.instance).languageSelected,
            notificationsEnabled:
                (preferences ?? AppPreferences.instance).notificationsEnabled,
          ),
        ) {
    _repo.locale = state.locale;
  }

  final MockRepository _repo;
  final AppPreferences _prefs;

  Future<void> setLocale(String locale) async {
    await _prefs.setLocale(locale);
    _repo.locale = locale;
    emit(state.copyWith(locale: locale));
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _prefs.setThemeMode(mode);
    emit(state.copyWith(themeMode: mode));
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    await _prefs.setNotificationsEnabled(enabled);
    emit(state.copyWith(notificationsEnabled: enabled));
  }

  Future<void> completeLanguageSelection() async {
    await _prefs.setLanguageSelected(true);
    emit(state.copyWith(languageSelected: true));
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
      return RouteNames.workerOnboardingIdentity;
    }
    return RouteNames.customerHome;
  }

  void signOut() {
    _repo.currentUser = null;
    emit(
      state.copyWith(
        status: AppSessionStatus.initial,
        email: '',
        phone: '',
      ),
    );
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
