import 'package:flutter/material.dart';

extension FixlyThemeX on BuildContext {
  ThemeData get theme => Theme.of(this);

  ColorScheme get scheme => theme.colorScheme;

  bool get isDark => theme.brightness == Brightness.dark;

  Color get canvas => theme.scaffoldBackgroundColor;

  Color get card => scheme.surface;

  Color get hairline => scheme.outline;

  Color get ink => scheme.onSurface;

  Color get muted => scheme.onSurfaceVariant;

  Color get container => scheme.surfaceContainerHighest;

  // ── Responsive helpers ──────────────────────────────────────────────────────

  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;

  /// Scale a size relative to 390-pt design width (iPhone 14 baseline).
  double rw(double size) => size * screenWidth / 390;

  /// Scale a size relative to 844-pt design height.
  double rh(double size) => size * screenHeight / 844;

  /// Font scale: clamps between 0.82× (tiny screens) and 1.1× (tablets).
  double get _fontScale => (screenWidth / 390).clamp(0.82, 1.1);

  /// Responsive font size — use instead of raw numbers.
  double sp(double size) => (size * _fontScale).roundToDouble();

  /// True when the shortest screen dimension < 600 (phone, not tablet).
  bool get isPhone => screenWidth < 600;

  /// True on compact/small phones (e.g. SE, 5-inch Android).
  bool get isSmallPhone => screenHeight < 720;
}
