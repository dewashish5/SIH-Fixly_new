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
}
