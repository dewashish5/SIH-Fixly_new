import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/theme_x.dart';

enum BadgeTone { primary, success, warning, error, neutral }

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    required this.label,
    super.key,
    this.tone = BadgeTone.neutral,
    this.compact = false,
  });

  final String label;
  final BadgeTone tone;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _colorsForTone(context, tone);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
              fontSize: compact ? 10 : 12,
            ),
      ),
    );
  }

  (Color, Color) _colorsForTone(BuildContext context, BadgeTone tone) {
    switch (tone) {
      case BadgeTone.primary:
        return (AppColors.primary.withValues(alpha: 0.12), AppColors.primary);
      case BadgeTone.success:
        return (AppColors.success.withValues(alpha: 0.12), AppColors.success);
      case BadgeTone.warning:
        return (AppColors.warning.withValues(alpha: 0.15), AppColors.warning);
      case BadgeTone.error:
        return (AppColors.error.withValues(alpha: 0.12), AppColors.error);
      case BadgeTone.neutral:
        return (context.scheme.surfaceContainerHighest, context.muted);
    }
  }
}
