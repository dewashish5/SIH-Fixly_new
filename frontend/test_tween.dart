import 'package:flutter/material.dart';

Widget buildAppBar(bool isExpanded) {
  return TweenAnimationBuilder<double>(
    tween: Tween<double>(begin: 124, end: isExpanded ? 500 : 124),
    duration: const Duration(milliseconds: 300),
    builder: (context, height, child) {
      return SliverAppBar(
        expandedHeight: height,
        // ...
      );
    },
  );
}
