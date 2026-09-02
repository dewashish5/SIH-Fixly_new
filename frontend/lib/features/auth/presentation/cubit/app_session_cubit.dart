import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/auth/google_auth_service.dart';
import '../../../../core/location/location_service.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/preferences/app_preferences.dart';
import '../../../../shared/data/mock/mock_repository.dart';
import '../../../../shared/models/models.dart';
import '../../data/auth_api_repository.dart';

part 'app_session_state.dart';

class AppSessionCubit extends Cubit<AppSessionState> {
  AppSessionCubit({
    MockRepository? repository,
    AppPreferences? preferences,
    AuthApiRepository? authRepository,
  })  : _repo = repository ?? MockRepository.instance,
        _prefs = preferences ?? AppPreferences.instance,
        _auth = authRepository ?? AuthApiRepository(),
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
  final AuthApiRepository _auth;

  Future<void> restoreSession() async {
    final session = await _auth.restoreSession();
    if (session == null) return;
    _repo.currentUser = session.user;
    _repo.selectedRole = session.user.role;
    emit(
      state.copyWith(
        role: session.user.role == UserRole.worker ? 'worker' : 'customer',
        email: session.user.email,
        status: AppSessionStatus.authenticated,
        clearError: true,
      ),
    );
  }

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

  Future<bool> signInWithGoogle() async {
    emit(state.copyWith(status: AppSessionStatus.loading, clearError: true));
    try {
      await GoogleAuthService.instance.ensureReady();

      final locationReady =
          await LocationService.instance.refreshCurrentPosition();
      if (!locationReady) {
        throw ApiException(
          'Location required — enable GPS and try again',
        );
      }

      final profile = await GoogleAuthService.instance.signIn();
      final session = await _auth.googleLogin(
        email: profile.email,
        name: profile.name,
        phone: profile.phone,
        avatar: profile.avatar,
        role: state.role,
      );
      _applySession(session);
      return true;
    } on ApiException catch (e) {
      emit(state.copyWith(
        status: AppSessionStatus.initial,
        errorMessage: e.message,
      ));
      return false;
    } on GoogleSignInException catch (e) {
      final canceled = e.code == GoogleSignInExceptionCode.canceled;
      emit(state.copyWith(
        status: AppSessionStatus.initial,
        errorMessage: canceled ? null : e.toString(),
        clearError: canceled,
      ));
      return false;
    } catch (e) {
      emit(state.copyWith(
        status: AppSessionStatus.initial,
        errorMessage: e.toString(),
      ));
      return false;
    }
  }

  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    emit(state.copyWith(
      email: email,
      status: AppSessionStatus.loading,
      clearError: true,
    ));
    try {
      final session = await _auth.login(email: email, password: password);
      _applySession(session);
      return true;
    } on ApiException catch (e) {
      emit(state.copyWith(
        status: AppSessionStatus.initial,
        errorMessage: e.message,
      ));
      return false;
    } catch (e) {
      emit(state.copyWith(
        status: AppSessionStatus.initial,
        errorMessage: e.toString(),
      ));
      return false;
    }
  }

  /// Register then expect OTP verify (email).
  Future<bool> signUpWithEmail({
    required String name,
    required String email,
    required String password,
    required String phone,
  }) async {
    emit(state.copyWith(
      email: email,
      phone: phone,
      pendingSignupName: name,
      pendingSignupPassword: password,
      status: AppSessionStatus.loading,
      clearError: true,
    ));
    try {
      await _auth.register(
        name: name,
        email: email,
        password: password,
        role: state.role,
        phone: phone,
      );
      emit(state.copyWith(
        email: email,
        phone: phone,
        pendingSignupName: name,
        pendingSignupPassword: password,
        status: AppSessionStatus.otpSent,
        clearError: true,
      ));
      return true;
    } on ApiException catch (e) {
      emit(state.copyWith(
        status: AppSessionStatus.initial,
        errorMessage: e.message,
      ));
      return false;
    } catch (e) {
      emit(state.copyWith(
        status: AppSessionStatus.initial,
        errorMessage: e.toString(),
      ));
      return false;
    }
  }

  /// Re-hit register to trigger a fresh email OTP.
  Future<bool> resendSignupOtp() async {
    final name = state.pendingSignupName;
    final email = state.email;
    final password = state.pendingSignupPassword;
    final phone = state.phone;
    if (name == null ||
        email == null ||
        email.isEmpty ||
        password == null ||
        phone == null) {
      emit(state.copyWith(
        errorMessage: 'Missing signup details — go back and sign up again',
      ));
      return false;
    }

    try {
      await _auth.register(
        name: name,
        email: email,
        password: password,
        role: state.role,
        phone: phone,
      );
      emit(state.copyWith(
        status: AppSessionStatus.otpSent,
        clearError: true,
      ));
      return true;
    } on ApiException catch (e) {
      emit(state.copyWith(errorMessage: e.message));
      return false;
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
      return false;
    }
  }

  Future<bool> verifyOtp(String otp) async {
    final email = state.email;
    if (email == null || email.isEmpty) {
      emit(state.copyWith(
        status: AppSessionStatus.otpFailed,
        errorMessage: 'Missing email for OTP',
      ));
      return false;
    }
    emit(state.copyWith(status: AppSessionStatus.loading, clearError: true));
    try {
      final session = await _auth.verifyOtp(email: email, otp: otp);
      _applySession(session);
      return true;
    } on ApiException catch (e) {
      emit(state.copyWith(
        status: AppSessionStatus.otpFailed,
        errorMessage: e.message,
      ));
      return false;
    } catch (e) {
      emit(state.copyWith(
        status: AppSessionStatus.otpFailed,
        errorMessage: e.toString(),
      ));
      return false;
    }
  }

  void resetOtpStatus() {
    emit(state.copyWith(status: AppSessionStatus.otpSent, clearError: true));
  }

  String postAuthRoute() {
    if (state.role == 'worker') {
      return RouteNames.workerOnboardingIdentity;
    }
    return RouteNames.customerHome;
  }

  Future<void> signOut() async {
    await _auth.logout();
    _repo.currentUser = null;
    emit(
      state.copyWith(
        status: AppSessionStatus.initial,
        email: '',
        phone: '',
        pendingSignupName: '',
        pendingSignupPassword: '',
        clearError: true,
      ),
    );
  }

  void _applySession(AuthSession session) {
    _repo.currentUser = session.user;
    _repo.selectedRole = session.user.role;
    emit(
      state.copyWith(
        email: session.user.email,
        phone: session.user.phone,
        pendingSignupName: '',
        pendingSignupPassword: '',
        role: session.user.role == UserRole.worker ? 'worker' : 'customer',
        status: AppSessionStatus.authenticated,
        clearError: true,
      ),
    );
  }

}
