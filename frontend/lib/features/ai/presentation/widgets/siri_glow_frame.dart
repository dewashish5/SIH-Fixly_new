import 'dart:math' as math;

import 'package:flutter/material.dart';

/// iOS-Siri-style animated rainbow edge glow.
/// Intensity + speed react to listen / think / speak like Apple Siri.
enum SiriGlowMode { idle, listening, thinking, speaking }

class SiriGlowFrame extends StatefulWidget {
  const SiriGlowFrame({
    super.key,
    required this.child,
    this.active = true,
    this.mode = SiriGlowMode.idle,
    this.borderRadius = 36,
  });

  final Widget child;
  final bool active;
  final SiriGlowMode mode;
  final double borderRadius;

  @override
  State<SiriGlowFrame> createState() => _SiriGlowFrameState();
}

class _SiriGlowFrameState extends State<SiriGlowFrame>
    with TickerProviderStateMixin {
  late final AnimationController _spin;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(vsync: this, duration: _spinDuration)
      ..repeat();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  Duration get _spinDuration {
    switch (widget.mode) {
      case SiriGlowMode.speaking:
        return const Duration(milliseconds: 2200);
      case SiriGlowMode.thinking:
        return const Duration(milliseconds: 3200);
      case SiriGlowMode.listening:
        return const Duration(milliseconds: 4800);
      case SiriGlowMode.idle:
        return const Duration(milliseconds: 7000);
    }
  }

  double get _baseIntensity {
    switch (widget.mode) {
      case SiriGlowMode.speaking:
        return 1.35;
      case SiriGlowMode.thinking:
        return 1.05;
      case SiriGlowMode.listening:
        return 0.95;
      case SiriGlowMode.idle:
        return 0.55;
    }
  }

  @override
  void didUpdateWidget(covariant SiriGlowFrame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mode != widget.mode) {
      _spin.duration = _spinDuration;
      if (!_spin.isAnimating) _spin.repeat();
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return widget.child;

    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return AnimatedBuilder(
      animation: Listenable.merge([_spin, _pulse]),
      builder: (context, child) {
        final pulse = reduceMotion ? 0.5 : _pulse.value;
        final intensity = _baseIntensity * (0.82 + 0.28 * pulse);
        return CustomPaint(
          foregroundPainter: _SiriEdgeGlowPainter(
            progress: reduceMotion ? 0 : _spin.value * math.pi * 2,
            intensity: intensity,
            mode: widget.mode,
            borderRadius: widget.borderRadius,
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _SiriEdgeGlowPainter extends CustomPainter {
  _SiriEdgeGlowPainter({
    required this.progress,
    required this.intensity,
    required this.mode,
    required this.borderRadius,
  });

  final double progress;
  final double intensity;
  final SiriGlowMode mode;
  final double borderRadius;

  static const _rainbow = <Color>[
    Color(0xFFFF375F), // siri pink/red
    Color(0xFFFF9F0A), // orange
    Color(0xFFFFD60A), // yellow
    Color(0xFF30D158), // green
    Color(0xFF64D2FF), // cyan
    Color(0xFF5E5CE6), // indigo
    Color(0xFFBF5AF2), // purple
    Color(0xFFFF375F),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final inset = mode == SiriGlowMode.speaking ? 2.0 : 4.0;
    final rect = Rect.fromLTWH(
      inset,
      inset,
      size.width - inset * 2,
      size.height - inset * 2,
    );
    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(borderRadius),
    );

    // Outer soft bloom (Siri halo)
    final bloom = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = (28 + 10 * intensity)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 22 + 8 * intensity)
      ..shader = SweepGradient(
        colors: _rainbow
            .map((c) => c.withValues(alpha: 0.28 * intensity))
            .toList(),
        transform: GradientRotation(progress),
      ).createShader(rect);
    canvas.drawRRect(rrect, bloom);

    // Mid colorful ribbon
    final ribbon = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6 + 4 * intensity
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
      ..shader = SweepGradient(
        colors: _rainbow
            .map((c) => c.withValues(alpha: 0.75 * intensity.clamp(0.2, 1.4)))
            .toList(),
        transform: GradientRotation(progress + 0.4),
      ).createShader(rect);
    canvas.drawRRect(rrect, ribbon);

    // Sharp inner rim (glass edge)
    final rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..shader = SweepGradient(
        colors: _rainbow
            .map((c) => c.withValues(alpha: 0.9 * intensity.clamp(0.3, 1.2)))
            .toList(),
        transform: GradientRotation(progress * 1.15),
      ).createShader(rect);
    canvas.drawRRect(rrect, rim);

    // Extra listening “breath” vignette at corners
    if (mode == SiriGlowMode.listening || mode == SiriGlowMode.speaking) {
      final cornerPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF64D2FF).withValues(alpha: 0.22 * intensity),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(
          center: Offset(size.width * 0.08, size.height * 0.12),
          radius: size.shortestSide * 0.35,
        ));
      canvas.drawRect(Offset.zero & size, cornerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SiriEdgeGlowPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.intensity != intensity ||
      oldDelegate.mode != mode ||
      oldDelegate.borderRadius != borderRadius;
}
