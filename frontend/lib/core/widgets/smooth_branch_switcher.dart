import 'package:flutter/material.dart';

/// Keeps shell branches alive and fades/slides between tabs without
/// [Opacity] saveLayers or rebuilding hidden branches every tick.
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
  static const _duration = Duration(milliseconds: 280);
  static const _slide = 0.04;

  late final AnimationController _controller;
  late final Animation<double> _curved;
  late int _fromIndex;
  late int _toIndex;

  @override
  void initState() {
    super.initState();
    _fromIndex = widget.currentIndex;
    _toIndex = widget.currentIndex;
    _controller = AnimationController(vsync: this, duration: _duration);
    _curved = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
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
    final incoming = Tween<Offset>(
      begin: Offset(dir * _slide, 0),
      end: Offset.zero,
    ).animate(_curved);
    final outgoing = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(-dir * _slide, 0),
    ).animate(_curved);

    return Stack(
      fit: StackFit.expand,
      children: [
        for (var i = 0; i < widget.children.length; i++)
          _slot(i, incoming, outgoing),
      ],
    );
  }

  Widget _slot(
    int i,
    Animation<Offset> incoming,
    Animation<Offset> outgoing,
  ) {
    final isTo = i == _toIndex;
    final isFrom = i == _fromIndex && _fromIndex != _toIndex;
    final child = RepaintBoundary(child: widget.children[i]);

    if (!isTo && !isFrom) {
      return Offstage(
        offstage: true,
        child: TickerMode(enabled: false, child: child),
      );
    }

    if (isTo && !isFrom) {
      return child;
    }

    if (isTo) {
      return FadeTransition(
        opacity: _curved,
        child: SlideTransition(position: incoming, child: child),
      );
    }

    return IgnorePointer(
      child: FadeTransition(
        opacity: ReverseAnimation(_curved),
        child: SlideTransition(position: outgoing, child: child),
      ),
    );
  }
}
