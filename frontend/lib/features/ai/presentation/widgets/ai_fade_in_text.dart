import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';

/// Left-aligned fade-in via animated_text_kit (LTR reading, soft fade).
class AiFadeInText extends StatelessWidget {
  const AiFadeInText({
    super.key,
    required this.text,
    this.style,
    this.maxLines,
  });

  final String text;
  final TextStyle? style;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    if (text.trim().isEmpty) return const SizedBox.shrink();

    return AnimatedTextKit(
      key: ValueKey(text),
      isRepeatingAnimation: false,
      totalRepeatCount: 1,
      displayFullTextOnTap: true,
      animatedTexts: [
        FadeAnimatedText(
          text,
          textAlign: TextAlign.left,
          textStyle: style,
          duration: Duration(
            milliseconds: (520 + text.length * 14).clamp(520, 1800),
          ),
          fadeInEnd: 0.65,
          fadeOutBegin: 1.0,
        ),
      ],
    );
  }
}
