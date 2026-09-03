import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../constants/app_constants.dart';

abstract final class AppMotion {
  static const route = Duration(
    milliseconds: AppConstants.transitionDurationMs,
  );
  static const routeReverse = Duration(
    milliseconds: AppConstants.transitionDurationMs ~/ 2,
  );
  static const tab = Duration(milliseconds: 280);
  static const list = Duration(milliseconds: 280);
  static const staggerMs = 40;
  static const maxStaggerIndex = 8;
  static const tabSlide = 0.04;
  static const listSlide = 0.08;
  static const routeSlide = 0.06;

  static bool reduced(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context);
}

class RouteMotion extends StatefulWidget {
  const RouteMotion({
    required this.animation,
    required this.child,
    super.key,
  });

  final Animation<double> animation;
  final Widget child;

  @override
  State<RouteMotion> createState() => _RouteMotionState();
}

class _RouteMotionState extends State<RouteMotion> {
  late final ValueNotifier<double> _progress;

  @override
  void initState() {
    super.initState();
    _progress = ValueNotifier(widget.animation.value);
    widget.animation.addListener(_sync);
  }

  void _sync() => _progress.value = widget.animation.value;

  @override
  void didUpdateWidget(covariant RouteMotion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animation != widget.animation) {
      oldWidget.animation.removeListener(_sync);
      widget.animation.addListener(_sync);
      _progress.value = widget.animation.value;
    }
  }

  @override
  void dispose() {
    widget.animation.removeListener(_sync);
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (AppMotion.reduced(context)) return widget.child;
    return widget.child
        .animate(adapter: ValueNotifierAdapter(_progress))
        .fadeIn(duration: AppMotion.route, curve: Curves.easeOutCubic)
        .slideX(
          begin: AppMotion.routeSlide,
          duration: AppMotion.route,
          curve: Curves.easeOutCubic,
        );
  }
}

extension AppMotionWidgetX on Widget {
  Widget appListEnter(
    BuildContext context, {
    required int index,
    Object? id,
  }) {
    if (AppMotion.reduced(context)) return this;
    final delayMs =
        index.clamp(0, AppMotion.maxStaggerIndex) * AppMotion.staggerMs;
    return animate(
      key: ValueKey<Object>(id ?? index),
      delay: delayMs.ms,
    )
        .fadeIn(duration: AppMotion.list, curve: Curves.easeOutCubic)
        .slideY(
          begin: AppMotion.listSlide,
          curve: Curves.easeOutCubic,
        );
  }
}
