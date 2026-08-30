import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/theme_x.dart';

class InsuranceBadge extends StatelessWidget {
  const InsuranceBadge({
    super.key,
    this.compact = false,
    this.showLabel = true,
  });

  final bool compact;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final isDark = context.isDark;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [scheme.primaryContainer, scheme.surfaceContainerHigh]
              : [AppColors.primary50, AppColors.primary100],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: scheme.primary.withValues(alpha: isDark ? 0.4 : 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.health_and_safety_outlined,
            size: compact ? 14 : 16,
            color: isDark ? scheme.onPrimaryContainer : AppColors.primary,
          ),
          if (showLabel) ...[
            const SizedBox(width: 6),
            Text(
              'PMSBY',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: isDark ? scheme.onPrimaryContainer : AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: compact ? 10 : 12,
                    letterSpacing: 0.5,
                  ),
            ),
            if (!compact) ...[
              const SizedBox(width: 4),
              Text(
                'Insured',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
