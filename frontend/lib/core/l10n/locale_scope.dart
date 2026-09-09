import 'package:flutter/material.dart';

/// Rebuilds descendants when [AppSessionCubit] locale changes.
class LocaleScope extends InheritedWidget {
  const LocaleScope({
    required this.locale,
    required super.child,
    super.key,
  });

  final String locale;

  static const supportedLocales = [
    'en',
    'hi',
    'ta',
    'te',
    'kn',
    'bn',
    'mr',
    'gu',
  ];

  static LocaleScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<LocaleScope>();
    assert(scope != null, 'LocaleScope not found. Wrap app with LocaleScope.');
    return scope!;
  }

  @override
  bool updateShouldNotify(LocaleScope oldWidget) =>
      oldWidget.locale != locale;
}
