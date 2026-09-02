import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/route_names.dart';

extension CustomerNavigation on BuildContext {
  StatefulNavigationShellState? get _customerShell {
    try {
      return StatefulNavigationShell.of(this);
    } catch (_) {
      return null;
    }
  }

  /// Switch customer bottom-nav tab without corrupting the shell stack.
  void goCustomerTab(int index) {
    final shell = _customerShell;
    if (shell != null) {
      shell.goBranch(
        index,
        initialLocation: index == shell.currentIndex,
      );
      return;
    }
    const routes = [
      RouteNames.customerHome,
      RouteNames.customerSearch,
      RouteNames.customerAiHelper,
      RouteNames.customerOrders,
      RouteNames.customerProfileTab,
    ];
    if (index >= 0 && index < routes.length) {
      go(routes[index]);
    }
  }

  /// Open filtered services for a category with a back button.
  void openCategorySearch(String categoryId) {
    final path = RouteNames.customerCategorySearchPath(categoryId);
    final location = GoRouterState.of(this).uri.toString();
    if (location.contains('/categories')) {
      pushReplacement(path);
      return;
    }
    push(path);
  }
}
