import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/constants/app_constants.dart';

class CategoryIconTile extends StatelessWidget {
  const CategoryIconTile({
    required this.category,
    required this.locale,
    required this.onTap,
    this.animationIndex = 0,
    super.key,
  });

  final ServiceCategory category;
  final String locale;
  final VoidCallback onTap;
  final int animationIndex;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: category.gradient,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: category.gradient.last.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.8),
                  blurRadius: 0,
                  offset: const Offset(-2, -2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: CachedNetworkImage(
                imageUrl: category.imageUrl,
                fit: BoxFit.contain,
                memCacheWidth: 112,
                memCacheHeight: 112,
                placeholder: (_, _) => const SizedBox.shrink(),
                errorWidget: (_, _, _) => Icon(
                  category.fallbackIcon,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            category.nameFor(locale),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    )
        .animate(delay: (animationIndex * 40).ms)
        .fadeIn()
        .scale(begin: const Offset(0.88, 0.88));
  }
}
