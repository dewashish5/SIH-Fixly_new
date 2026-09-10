import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Soft Siri-like animated glow around the AI screen edges.
class SiriGlowFrame extends StatefulWidget {
  const SiriGlowFrame({
    super.key,
    required this.child,
    this.active = true,
    this.intensity = 1,
  });

  final Widget child;
  final bool active;
  final double intensity;

  @override
  State<SiriGlowFrame> createState() => _SiriGlowFrameState();
}

class _SiriGlowFrameState extends State<SiriGlowFrame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return widget.child;
    final primary = Theme.of(context).colorScheme.primary;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value * math.pi * 2;
        return CustomPaint(
          foregroundPainter: _GlowCornerPainter(
            progress: t,
            primary: primary,
            intensity: widget.intensity,
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _GlowCornerPainter extends CustomPainter {
  _GlowCornerPainter({
    required this.progress,
    required this.primary,
    required this.intensity,
  });

  final double progress;
  final Color primary;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18 * intensity
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);

    final colors = [
      primary.withValues(alpha: 0.55 * intensity),
      const Color(0xFF60A5FA).withValues(alpha: 0.45 * intensity),
      const Color(0xFFA78BFA).withValues(alpha: 0.4 * intensity),
      primary.withValues(alpha: 0.55 * intensity),
    ];

    glow.shader = SweepGradient(
      colors: colors,
      transform: GradientRotation(progress),
    ).createShader(rect);

    final rrect = RRect.fromRectAndRadius(
      rect.deflate(6),
      const Radius.circular(28),
    );
    canvas.drawRRect(rrect, glow);

    final soft = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = primary.withValues(alpha: 0.35 * intensity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawRRect(rrect, soft);
  }

  @override
  bool shouldRepaint(covariant _GlowCornerPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.intensity != intensity ||
      oldDelegate.primary != primary;
}
