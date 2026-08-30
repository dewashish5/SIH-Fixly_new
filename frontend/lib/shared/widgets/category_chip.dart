import 'package:flutter/material.dart';

import '../../app/theme/theme_x.dart';

class CategoryChip extends StatelessWidget {
  const CategoryChip({
    required this.label,
    super.key,
    this.icon,
    this.selected = false,
    this.onTap,
  });

  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final bgColor = selected
        ? scheme.primary.withValues(alpha: context.isDark ? 0.22 : 0.12)
        : scheme.surface;
    final borderColor = selected ? scheme.primary : scheme.outline;
    final textColor = selected ? scheme.primary : scheme.onSurface;

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) Icon(icon, size: 18, color: textColor),
              if (icon != null) const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: textColor,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
