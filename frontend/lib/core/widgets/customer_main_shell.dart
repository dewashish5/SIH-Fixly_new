import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_strings.dart';
import '../../features/auth/presentation/cubit/app_session_cubit.dart';
import 'animated_bottom_nav_bar.dart';

class CustomerMainShell extends StatelessWidget {
  const CustomerMainShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppSessionCubit, AppSessionState>(
      buildWhen: (prev, curr) => prev.locale != curr.locale,
      builder: (context, session) {
        final l10n = AppStrings(session.locale);
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: navigationShell,
          bottomNavigationBar: AnimatedBottomNavBar(
            currentIndex: navigationShell.currentIndex,
            onTap: _onTap,
            items: [
              NavBarItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: l10n.navHome,
              ),
              NavBarItem(
                icon: Icons.search_outlined,
                activeIcon: Icons.search_rounded,
                label: l10n.navSearch,
              ),
              NavBarItem(
                icon: Icons.auto_awesome_outlined,
                activeIcon: Icons.auto_awesome_rounded,
                label: l10n.navAi,
                isAccent: true,
              ),
              NavBarItem(
                icon: Icons.receipt_long_outlined,
                activeIcon: Icons.receipt_long_rounded,
                label: l10n.navBookings,
              ),
              NavBarItem(
                icon: Icons.person_outline,
                activeIcon: Icons.person_rounded,
                label: l10n.navProfile,
              ),
            ],
          ),
        );
      },
    );
  }
}
