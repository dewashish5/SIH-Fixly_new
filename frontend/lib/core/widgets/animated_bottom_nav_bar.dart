import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/theme_x.dart';
import 'app_motion.dart';

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
  static const _anim = Duration(milliseconds: 280);

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<NavBarItem> items;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final scheme = context.scheme;

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
            color: scheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: scheme.outline.withValues(alpha: 0.9),
            ),
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withValues(alpha: context.isDark ? 0.35 : 0.06),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: List.generate(items.length, (index) {
              final item = items[index];
              final selected = index == currentIndex;
              return Expanded(
                child: Semantics(
                  button: true,
                  selected: selected,
                  label: item.label,
                  child: _NavSlot(
                    item: item,
                    selected: selected,
                    onTap: () {
                      if (index != currentIndex) {
                        HapticFeedback.selectionClick();
                      }
                      onTap(index);
                    },
                  ),
                ),
              );
            }),
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
    final scheme = context.scheme;
    final target = selected
        ? (item.isAccent ? AppColors.accent : scheme.primary)
        : scheme.onSurfaceVariant;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        height: AnimatedBottomNavBar._barHeight,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _NavIcon(selected: selected, item: item, color: target),
            const SizedBox(height: 5),
            AnimatedDefaultTextStyle(
              duration: AnimatedBottomNavBar._anim,
              curve: Curves.easeOutCubic,
              style: TextStyle(
                fontSize: selected ? 11 : 10.5,
                height: 1,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: target,
              ),
              child: Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({
    required this.selected,
    required this.item,
    required this.color,
  });

  final bool selected;
  final NavBarItem item;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final icon = Icon(
      selected ? item.activeIcon : item.icon,
      size: 24,
      color: color,
    );
    if (AppMotion.reduced(context)) return icon;
    return icon
        .animate(target: selected ? 1 : 0)
        .scaleXY(
          begin: 1,
          end: 1.12,
          duration: AnimatedBottomNavBar._anim,
          curve: Curves.easeOutCubic,
        );
  }
}
