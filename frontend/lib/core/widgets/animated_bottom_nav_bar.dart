import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

class NavBarItem {
  const NavBarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.isAccent = false,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isAccent;
}

class AnimatedBottomNavBar extends StatelessWidget {
  const AnimatedBottomNavBar({
    required this.currentIndex,
    required this.onTap,
    required this.items,
    super.key,
  });

  static const _barHeight = 66.0;
  static const _horizontalPadding = 20.0;

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<NavBarItem> items;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Material(
      color: Colors.transparent,
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          _horizontalPadding,
          0,
          _horizontalPadding,
          bottomInset > 0 ? 10 : 16,
        ),
        child: Container(
          height: _barHeight,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.35),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.onSurface.withValues(alpha: 0.07),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final slotWidth = constraints.maxWidth / items.length;

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    left: currentIndex * slotWidth + (slotWidth - 44) / 2,
                    top: 8,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: items[currentIndex].isAccent
                            ? AppColors.primary.withValues(alpha: 0.14)
                            : AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  Row(
                    children: List.generate(items.length, (index) {
                      return SizedBox(
                        width: slotWidth,
                        child: _NavSlot(
                          item: items[index],
                          selected: index == currentIndex,
                          onTap: () => onTap(index),
                        ),
                      );
                    }),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _NavSlot extends StatelessWidget {
  const _NavSlot({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final NavBarItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final activeColor = item.isAccent ? AppColors.primary : AppColors.primary;
    final inactiveColor = AppColors.onSurfaceVariant;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: AppColors.primary.withValues(alpha: 0.08),
        highlightColor: AppColors.primary.withValues(alpha: 0.04),
        child: SizedBox(
          height: AnimatedBottomNavBar._barHeight,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _NavIcon(
                item: item,
                selected: selected,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
              ),
              const SizedBox(height: 5),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10.5,
                  height: 1,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? activeColor : inactiveColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({
    required this.item,
    required this.selected,
    required this.activeColor,
    required this.inactiveColor,
  });

  final NavBarItem item;
  final bool selected;
  final Color activeColor;
  final Color inactiveColor;

  @override
  Widget build(BuildContext context) {
    if (item.isAccent) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF6366F1), Color(0xFF2563EB)],
                )
              : null,
          color: selected ? null : AppColors.surfaceContainer,
          shape: BoxShape.circle,
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.28),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Icon(
          selected ? item.activeIcon : item.icon,
          size: 20,
          color: selected ? Colors.white : AppColors.primary,
        ),
      );
    }

    return AnimatedScale(
      scale: selected ? 1.05 : 1,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      child: Icon(
        selected ? item.activeIcon : item.icon,
        size: 23,
        color: selected ? activeColor : inactiveColor,
      ),
    );
  }
}
