import 'package:flutter/material.dart';

/// Fixly brand color system — blue dominant, orange accent sparingly.
abstract final class AppColors {
  // Primary blue scale
  static const primary50 = Color(0xFFE6F4FA);
  static const primary100 = Color(0xFFCCE9F5);
  static const primary200 = Color(0xFF99D3EB);
  static const primary300 = Color(0xFF66BDE1);
  static const primary400 = Color(0xFF3398C5);
  static const primary = Color(0xFF01668F);
  static const primary600 = Color(0xFF015577);
  static const primaryDark = Color(0xFF01455F);
  static const primary800 = Color(0xFF013548);
  static const primary900 = Color(0xFF012532);

  // Orange accent scale
  static const accent50 = Color(0xFFFFF3E6);
  static const accent100 = Color(0xFFFFE7CC);
  static const accent200 = Color(0xFFFFCF99);
  static const accent300 = Color(0xFFFFB766);
  static const accent400 = Color(0xFFFF8F33);
  static const accent = Color(0xFFFD6E01);
  static const accent600 = Color(0xFFDD6001);
  static const accentDark = Color(0xFFBC5101);
  static const accent800 = Color(0xFF9B4201);
  static const accent900 = Color(0xFF7A3401);

  // Neutrals
  static const background = Color(0xFFF8FAFB);
  static const surface = Color(0xFFFFFFFF);
  static const border = Color(0xFFE5E7EB);
  static const splashBackground = Color(0xFFF8FAFB);

  // Dark neutrals
  static const backgroundDark = Color(0xFF0B1419);
  static const surfaceDark = Color(0xFF122029);
  static const borderDark = Color(0xFF1E3340);
  static const aiBackgroundDark = Color(0xFF0F2430);

  // Text
  static const textPrimary = Color(0xFF17212B);
  static const textSecondary = Color(0xFF64748B);
  static const textMuted = Color(0xFF94A3B8);
  static const textPrimaryDark = Color(0xFFF8FAFB);
  static const textSecondaryDark = Color(0xFF94A3B8);
  static const textMutedDark = Color(0xFF64748B);

  // Status
  static const success = Color(0xFF16A34A);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFDC2626);

  // Semantic aliases (brand usage)
  static const secondary = accent;
  static const tertiary = accent;

  // Feature surfaces
  static const aiBackground = primary50;
  static const aiHighlight = accent;
  static const recommendedHighlight = accent;

  // Dark elevated containers (desaturated — not inverted light)
  static const surfaceContainerDark = Color(0xFF1A2C36);
  static const surfaceContainerHighDark = Color(0xFF243744);

  // Semantic aliases (light defaults — prefer Theme.colorScheme in widgets)
  static const onSurface = textPrimary;
  static const onSurfaceVariant = textSecondary;
  static const outline = textSecondary;
  static const outlineVariant = border;
  static const surfaceContainer = primary50;
  static const surfaceContainerHigh = primary100;
  static const surfaceContainerHighest = primary200;

  static const primaryGradient = [primary, primary400];
  static const accentGradient = [accent, accent400];
}
