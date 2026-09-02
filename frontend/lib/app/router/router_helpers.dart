import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:transit_kit/transit_kit.dart';

import '../../core/constants/app_constants.dart';

Page<T> transitPage<T>({
  required GoRouterState state,
  required Widget child,
  TransitType type = TransitType.fadeSlideRight,
}) {
  return TransitPage<T>(
    key: ValueKey<String>('transit:${state.uri}'),
    type: type,
    duration: const Duration(milliseconds: AppConstants.transitionDurationMs),
    reverseDuration:
        const Duration(milliseconds: AppConstants.transitionDurationMs),
    child: child,
  );
}
