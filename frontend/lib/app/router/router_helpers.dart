import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/app_motion.dart';

Page<T> transitPage<T>({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    transitionDuration: AppMotion.route,
    reverseTransitionDuration: AppMotion.routeReverse,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return RouteMotion(animation: animation, child: child);
    },
  );
}
