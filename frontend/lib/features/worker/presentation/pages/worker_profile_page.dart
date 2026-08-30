import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../../shared/presentation/cubit/profile_cubit.dart';
import '../../../../core/constants/app_strings.dart';

class WorkerProfilePage extends StatefulWidget {
  const WorkerProfilePage({super.key});

  @override
  State<WorkerProfilePage> createState() => _WorkerProfilePageState();
}

class _WorkerProfilePageState extends State<WorkerProfilePage> {
  @override
  void initState() {
    super.initState();
    context.read<ProfileCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        return AppScaffold(
          title: context.l10n.myProfile,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => context.push(RouteNames.sharedSettings),
            ),
          ],
          body: state.status == ProfileStatus.loading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: AppColors.surfaceContainer,
                        child: Text(
                          state.name.isNotEmpty
                              ? state.name[0].toUpperCase()
                              : '?',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        state.name,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    Center(child: Text(state.phone)),
                    const SizedBox(height: 12),
                    if (state.insured)
                      const Center(child: InsuranceBadge()),
                    const SizedBox(height: 24),
                    if (state.skills.isNotEmpty) ...[
                      Text('Skills', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          for (final id in state.skills)
                            Chip(
                              label: Text(_skillLabel(id)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                    SecondaryButton(
                      label: 'Reliability score',
                      onPressed: () => context.push(RouteNames.workerReliability),
                    ),
                    const SizedBox(height: 12),
                    SecondaryButton(
                      label: 'Edit profile',
                      onPressed: () => context.push(RouteNames.sharedEditProfile),
                    ),
                    const SizedBox(height: 12),
                    SecondaryButton(
                      label: 'Support',
                      onPressed: () => context.push(RouteNames.sharedSupportChat),
                    ),
                  ],
                ),
        );
      },
    );
  }

  String _skillLabel(String id) {
    for (final c in ServiceCategories.all) {
      if (c.id == id) return c.nameEn;
    }
    return id;
  }
}
