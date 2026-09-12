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
  static const _keyTransactional = 'pref_notifications_transactional';
  static const _keySystem = 'pref_notifications_system';
  static const _keyMarketing = 'pref_notifications_marketing';
  static bool _migratedNotificationPrefs = false;

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    _migrateNotificationPrefs();
  }

  void _migrateNotificationPrefs() {
    if (_migratedNotificationPrefs) return;
    _migratedNotificationPrefs = true;
    final prefs = _prefs;
    if (prefs == null) return;
    if (!prefs.containsKey(_keyNotifications)) {
      prefs.setBool(_keyNotifications, true);
    }
    if (!prefs.containsKey(_keyTransactional)) {
      prefs.setBool(_keyTransactional, true);
    }
    if (!prefs.containsKey(_keySystem)) {
      prefs.setBool(_keySystem, true);
    }
    if (!prefs.containsKey(_keyMarketing)) {
      prefs.setBool(_keyMarketing, true);
    }
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

  bool get notificationsEnabled => transactionalNotificationsEnabled;

  bool get transactionalNotificationsEnabled =>
      _prefs?.getBool(_keyTransactional) ??
      _prefs?.getBool(_keyNotifications) ??
      true;

  bool get systemNotificationsEnabled =>
      _prefs?.getBool(_keySystem) ?? true;

  bool get marketingNotificationsEnabled =>
      _prefs?.getBool(_keyMarketing) ?? true;

  Future<void> setNotificationsEnabled(bool value) =>
      setTransactionalNotificationsEnabled(value);

  Future<void> setTransactionalNotificationsEnabled(bool value) async {
    await _require.setBool(_keyTransactional, value);
    await _require.setBool(_keyNotifications, value);
  }

  Future<void> setSystemNotificationsEnabled(bool value) async {
    await _require.setBool(_keySystem, value);
  }

  Future<void> setMarketingNotificationsEnabled(bool value) async {
    await _require.setBool(_keyMarketing, value);
  }

  String? get activeWorkerJobId => _prefs?.getString('pref_active_worker_job_id');

  Future<void> setActiveWorkerJobId(String? id) async {
    if (id == null) {
      await _require.remove('pref_active_worker_job_id');
    } else {
      await _require.setString('pref_active_worker_job_id', id);
    }
  }
}
