import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_strings.dart';
import '../../features/auth/presentation/cubit/app_session_cubit.dart';
import 'animated_bottom_nav_bar.dart';

class WorkerMainShell extends StatelessWidget {
  const WorkerMainShell({required this.navigationShell, super.key});

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
                icon: Icons.dashboard_outlined,
                activeIcon: Icons.dashboard_rounded,
                label: l10n.navHome,
              ),
              NavBarItem(
                icon: Icons.work_outline,
                activeIcon: Icons.work_rounded,
                label: l10n.navJobs,
              ),
              NavBarItem(
                icon: Icons.account_balance_wallet_outlined,
                activeIcon: Icons.account_balance_wallet_rounded,
                label: l10n.navWallet,
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
