import 'package:flutter/material.dart';

/// Fixly color system — royal blue primary (attendance-app reference).
/// Accent = blue family; orange reserved for warning status only.
abstract final class AppColors {
  // Primary blue scale
  static const primary50 = Color(0xFFEFF6FF);
  static const primary100 = Color(0xFFDBEAFE);
  static const primary200 = Color(0xFFBFDBFE);
  static const primary300 = Color(0xFF93C5FD);
  static const primary400 = Color(0xFF60A5FA);
  static const primary = Color(0xFF2563EB);
  static const primary600 = Color(0xFF1D4ED8);
  static const primaryDark = Color(0xFF1E40AF);
  static const primary800 = Color(0xFF1E3A8A);
  static const primary900 = Color(0xFF172554);

  // Accent = primary family (no brand orange)
  static const accent50 = Color(0xFFEFF6FF);
  static const accent100 = Color(0xFFDBEAFE);
  static const accent200 = Color(0xFFBFDBFE);
  static const accent300 = Color(0xFF93C5FD);
  static const accent400 = Color(0xFF60A5FA);
  static const accent = Color(0xFF2563EB);
  static const accent600 = Color(0xFF1D4ED8);
  static const accentDark = Color(0xFF1E40AF);
  static const accent800 = Color(0xFF1E3A8A);
  static const accent900 = Color(0xFF172554);

  // Neutrals
  static const background = Color(0xFFF8FAFC);
  static const surface = Color(0xFFFFFFFF);
  static const border = Color(0xFFE2E8F0);
  static const splashBackground = Color(0xFFF8FAFC);

  // Dark neutrals (blue-slate, not inverted light)
  static const backgroundDark = Color(0xFF0B1220);
  static const surfaceDark = Color(0xFF111827);
  static const borderDark = Color(0xFF1E293B);
  static const aiBackgroundDark = Color(0xFF0F172A);

  // Text
  static const textPrimary = Color(0xFF1E293B);
  static const textSecondary = Color(0xFF64748B);
  static const textMuted = Color(0xFF94A3B8);
  static const textPrimaryDark = Color(0xFFF8FAFC);
  static const textSecondaryDark = Color(0xFF94A3B8);
  static const textMutedDark = Color(0xFF64748B);

  // Status
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFDC2626);

  // Semantic aliases (brand usage)
  static const secondary = accent;
  static const tertiary = accent;

  // Feature surfaces
  static const aiBackground = primary50;
  static const aiHighlight = accent;
  static const recommendedHighlight = accent;

  // Dark elevated containers
  static const surfaceContainerDark = Color(0xFF1A2438);
  static const surfaceContainerHighDark = Color(0xFF243049);

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
