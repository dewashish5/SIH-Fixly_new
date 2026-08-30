part of 'app_session_cubit.dart';

enum AppSessionStatus { initial, loading, otpSent, authenticated, otpFailed }

enum AuthFlow { login, signup }

class AppSessionState extends Equatable {
  const AppSessionState({
    this.locale = 'en',
    this.role = 'customer',
    this.phone,
    this.email,
    this.status = AppSessionStatus.initial,
    this.authFlow = AuthFlow.login,
  });

  final String locale;
  final String role;
  final String? phone;
  final String? email;
  final AppSessionStatus status;
  final AuthFlow authFlow;

  AppSessionState copyWith({
    String? locale,
    String? role,
    String? phone,
    String? email,
    AppSessionStatus? status,
    AuthFlow? authFlow,
  }) {
    return AppSessionState(
      locale: locale ?? this.locale,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      status: status ?? this.status,
      authFlow: authFlow ?? this.authFlow,
    );
  }

  @override
  List<Object?> get props => [locale, role, phone, email, status, authFlow];
}
