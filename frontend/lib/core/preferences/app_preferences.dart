import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local prefs: locale, theme, onboarding flags, notification toggle.
class AppPreferences {
  AppPreferences._();
  static final AppPreferences instance = AppPreferences._();

  static const _keyLocale = 'pref_locale';
  static const _keyThemeMode = 'pref_theme_mode';
  static const _keyLanguageSelected = 'pref_language_selected';
  static const _keyNotifications = 'pref_notifications_enabled';

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  SharedPreferences get _require {
    final prefs = _prefs;
    if (prefs == null) {
      throw StateError('AppPreferences.init() not called');
    }
    return prefs;
  }

  String get locale => _prefs?.getString(_keyLocale) ?? 'en';

  Future<void> setLocale(String locale) async {
    await _require.setString(_keyLocale, locale);
  }

  ThemeMode get themeMode {
    switch (_prefs?.getString(_keyThemeMode)) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await _require.setString(_keyThemeMode, value);
  }

  bool get languageSelected =>
      _prefs?.getBool(_keyLanguageSelected) ?? false;

  Future<void> setLanguageSelected(bool value) async {
    await _require.setBool(_keyLanguageSelected, value);
  }

  bool get notificationsEnabled =>
      _prefs?.getBool(_keyNotifications) ?? true;

  Future<void> setNotificationsEnabled(bool value) async {
    await _require.setBool(_keyNotifications, value);
  }
}
