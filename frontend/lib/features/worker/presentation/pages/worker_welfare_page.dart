import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/theme_x.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../cubit/welfare_cubit.dart';

class WorkerWelfarePage extends StatelessWidget {
  const WorkerWelfarePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => WelfareCubit()..load(),
      child: const _WorkerWelfareView(),
    );
  }
}

class _WorkerWelfareView extends StatelessWidget {
  const _WorkerWelfareView();

  Future<void> _launchUrl(String urlString) async {
    final url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.inAppBrowserView)) {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Welfare & Insurance',
      body: BlocBuilder<WelfareCubit, WelfareState>(
        builder: (context, state) {
          if (state.isLoading && state.resources.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return AppRefreshIndicator(
            onRefresh: () => context.read<WelfareCubit>().load(),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                // Welfare Balance Card
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primaryDark, AppColors.primary],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Welfare Fund Balance',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '₹${state.balance.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                
                // e-Shram Card
                Text(
                  'e-Shram / Insurance Status',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                AppCard(
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: (state.hasUan ? AppColors.success : AppColors.warning).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            state.hasUan ? Icons.verified : Icons.info_outline,
                            color: state.hasUan ? AppColors.success : AppColors.warning,
                          ),
                        ),
                        title: Text(state.hasUan ? 'UAN Registered' : 'Registration Pending'),
                        subtitle: Text(
                          state.hasUan 
                            ? 'Your insurance is active.' 
                            : 'Register to access insurance benefits.',
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: PrimaryButton(
                          label: state.hasUan ? 'View Insurance' : 'Register for e-Shram',
                          onPressed: () {
                            if (state.hasUan) {
                              _launchUrl('https://eshram.gov.in/');
                            } else {
                              _launchUrl('https://eshram.gov.in/registration');
                            }
                          },
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Resources
                Text(
                  'Welfare Resources',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ...state.resources.map((res) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: AppCard(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(res['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(res['description'] ?? ''),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          if (res['url'] != null) {
                            _launchUrl(res['url']);
                          }
                        },
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}
