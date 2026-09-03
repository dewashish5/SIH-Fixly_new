import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'app_motion.dart';

/// Keeps shell branches alive and fades/slides between tabs.
class SmoothBranchSwitcher extends StatefulWidget {
  const SmoothBranchSwitcher({
    required this.currentIndex,
    required this.children,
    super.key,
  });

  final int currentIndex;
  final List<Widget> children;

  @override
  State<SmoothBranchSwitcher> createState() => _SmoothBranchSwitcherState();
}

class _SmoothBranchSwitcherState extends State<SmoothBranchSwitcher>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late int _fromIndex;
  late int _toIndex;

  @override
  void initState() {
    super.initState();
    _fromIndex = widget.currentIndex;
    _toIndex = widget.currentIndex;
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.tab,
    );
    _controller.value = 1;
    _controller.addStatusListener(_onStatus);
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed &&
        mounted &&
        _fromIndex != _toIndex) {
      setState(() => _fromIndex = _toIndex);
    }
  }

  @override
  void didUpdateWidget(covariant SmoothBranchSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex != oldWidget.currentIndex) {
      _fromIndex = oldWidget.currentIndex;
      _toIndex = widget.currentIndex;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_onStatus);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dir = (_toIndex - _fromIndex).sign.toDouble();
    return Stack(
      fit: StackFit.expand,
      children: [
        for (var i = 0; i < widget.children.length; i++)
          _slot(context, i, dir),
      ],
    );
  }

  Widget _slot(BuildContext context, int i, double dir) {
    final isTo = i == _toIndex;
    final isFrom = i == _fromIndex && _fromIndex != _toIndex;
    final child = RepaintBoundary(child: widget.children[i]);

    if (!isTo && !isFrom) {
      return Offstage(
        offstage: true,
        child: TickerMode(enabled: false, child: child),
      );
    }

    if (AppMotion.reduced(context) || (isTo && !isFrom)) {
      return child;
    }

    if (isTo) {
      return Animate(
        controller: _controller,
        autoPlay: false,
        effects: [
          FadeEffect(
            begin: 0,
            end: 1,
            duration: AppMotion.tab,
            curve: Curves.easeOutCubic,
          ),
          SlideEffect(
            begin: Offset(dir * AppMotion.tabSlide, 0),
            end: Offset.zero,
            duration: AppMotion.tab,
            curve: Curves.easeOutCubic,
          ),
        ],
        child: child,
      );
    }

    return IgnorePointer(
      child: Animate(
        controller: _controller,
        autoPlay: false,
        effects: [
          FadeEffect(
            begin: 1,
            end: 0,
            duration: AppMotion.tab,
            curve: Curves.easeOutCubic,
          ),
          SlideEffect(
            begin: Offset.zero,
            end: Offset(-dir * AppMotion.tabSlide, 0),
            duration: AppMotion.tab,
            curve: Curves.easeOutCubic,
          ),
        ],
        child: child,
      ),
    );
  }
}
