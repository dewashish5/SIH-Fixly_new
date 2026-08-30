import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

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
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.secondary.withValues(alpha: 0.15),
            AppColors.primary.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.health_and_safety_outlined,
            size: compact ? 14 : 16,
            color: AppColors.secondary,
          ),
          if (showLabel) ...[
            const SizedBox(width: 6),
            Text(
              'PMSBY',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.secondary,
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
                      color: AppColors.onSurfaceVariant,
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
