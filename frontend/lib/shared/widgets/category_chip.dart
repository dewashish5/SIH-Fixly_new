import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

class CategoryChip extends StatelessWidget {
  const CategoryChip({
    required this.label,
    super.key,
    this.imageUrl,
    this.fallbackIcon,
    this.selected = false,
    this.onTap,
  });

  final String label;
  final String? imageUrl;
  final IconData? fallbackIcon;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bgColor =
        selected ? AppColors.primary.withValues(alpha: 0.12) : Colors.white;
    final borderColor = selected ? AppColors.primary : AppColors.outlineVariant;
    final textColor = selected ? AppColors.primary : AppColors.onSurface;

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
              if (imageUrl != null)
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CachedNetworkImage(
                    imageUrl: imageUrl!,
                    fit: BoxFit.contain,
                    errorWidget: (_, _, _) => Icon(
                      fallbackIcon ?? Icons.category_rounded,
                      size: 18,
                      color: textColor,
                    ),
                  ),
                )
              else if (fallbackIcon != null)
                Icon(fallbackIcon, size: 18, color: textColor),
              const SizedBox(width: 8),
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
