import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_strings.dart';
import '../../features/auth/presentation/cubit/app_session_cubit.dart';
import '../network/worker_realtime_service.dart';
import 'animated_bottom_nav_bar.dart';

class WorkerMainShell extends StatefulWidget {
  const WorkerMainShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  State<WorkerMainShell> createState() => _WorkerMainShellState();
}

class _WorkerMainShellState extends State<WorkerMainShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AppSessionCubit>().currentUser;
      if (user != null && user.id.isNotEmpty) {
        WorkerRealtimeService.instance.initForWorker(user.id);
      }
    });
  }

  void _onTap(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
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
          body: widget.navigationShell,
          bottomNavigationBar: AnimatedBottomNavBar(
            currentIndex: widget.navigationShell.currentIndex,
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
