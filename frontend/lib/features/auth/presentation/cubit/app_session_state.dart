part of 'app_session_cubit.dart';

enum AppSessionStatus { initial, loading, otpSent, authenticated, otpFailed }

enum AuthFlow { login, signup }

class AppSessionState extends Equatable {
  const AppSessionState({
    this.locale = 'en',
    this.themeMode = ThemeMode.system,
    this.languageSelected = false,
    this.notificationsEnabled = true,
    this.role = 'customer',
    this.phone,
    this.email,
    this.status = AppSessionStatus.initial,
    this.authFlow = AuthFlow.login,
    this.errorMessage,
  });

  final String locale;
  final ThemeMode themeMode;
  final bool languageSelected;
  final bool notificationsEnabled;
  final String role;
  final String? phone;
  final String? email;
  final AppSessionStatus status;
  final AuthFlow authFlow;
  final String? errorMessage;

  AppSessionState copyWith({
    String? locale,
    ThemeMode? themeMode,
    bool? languageSelected,
    bool? notificationsEnabled,
    String? role,
    String? phone,
    String? email,
    AppSessionStatus? status,
    AuthFlow? authFlow,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AppSessionState(
      locale: locale ?? this.locale,
      themeMode: themeMode ?? this.themeMode,
      languageSelected: languageSelected ?? this.languageSelected,
      notificationsEnabled:
          notificationsEnabled ?? this.notificationsEnabled,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      status: status ?? this.status,
      authFlow: authFlow ?? this.authFlow,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        locale,
        themeMode,
        languageSelected,
        notificationsEnabled,
        role,
        phone,
        email,
        status,
        authFlow,
        errorMessage,
      ];
}
