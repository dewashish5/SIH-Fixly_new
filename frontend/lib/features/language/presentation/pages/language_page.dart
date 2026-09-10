import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/theme_x.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../auth/presentation/cubit/app_session_cubit.dart';

class LanguagePage extends StatelessWidget {
  const LanguagePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppSessionCubit, AppSessionState>(
      builder: (context, state) {
        final strings = context.strings(state.locale);

        return AppScaffold(
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Text(
                strings.selectLanguage,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                strings.choosePreferredLanguage,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: context.muted,
                    ),
              ),
              const SizedBox(height: 28),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _LanguageCard(
                      code: 'EN',
                      label: 'English',
                      subtitle: 'Continue in English',
                      selected: state.locale == 'en',
                      onTap: () => context.read<AppSessionCubit>().setLocale('en'),
                    ),
                    const SizedBox(height: 12),
                    _LanguageCard(
                      code: 'हिन्दी',
                      label: 'Hindi',
                      subtitle: 'हिन्दी में जारी रखें',
                      selected: state.locale == 'hi',
                      onTap: () => context.read<AppSessionCubit>().setLocale('hi'),
                    ),
                    const SizedBox(height: 12),
                    _LanguageCard(
                      code: 'தமிழ்',
                      label: 'Tamil',
                      subtitle: 'தமிழில் தொடரவும்',
                      selected: state.locale == 'ta',
                      onTap: () => context.read<AppSessionCubit>().setLocale('ta'),
                    ),
                    const SizedBox(height: 12),
                    _LanguageCard(
                      code: 'తెలుగు',
                      label: 'Telugu',
                      subtitle: 'తెలుగులో కొనసాగండి',
                      selected: state.locale == 'te',
                      onTap: () => context.read<AppSessionCubit>().setLocale('te'),
                    ),
                    const SizedBox(height: 12),
                    _LanguageCard(
                      code: 'ಕನ್ನಡ',
                      label: 'Kannada',
                      subtitle: 'ಕನ್ನಡದಲ್ಲಿ ಮುಂದುವರಿಯಿರಿ',
                      selected: state.locale == 'kn',
                      onTap: () => context.read<AppSessionCubit>().setLocale('kn'),
                    ),
                    const SizedBox(height: 12),
                    _LanguageCard(
                      code: 'বাংলা',
                      label: 'Bengali',
                      subtitle: 'বাংলায় চালিয়ে যান',
                      selected: state.locale == 'bn',
                      onTap: () => context.read<AppSessionCubit>().setLocale('bn'),
                    ),
                    const SizedBox(height: 12),
                    _LanguageCard(
                      code: 'मराठी',
                      label: 'Marathi',
                      subtitle: 'मराठीत पुढे जा',
                      selected: state.locale == 'mr',
                      onTap: () => context.read<AppSessionCubit>().setLocale('mr'),
                    ),
                    const SizedBox(height: 12),
                    _LanguageCard(
                      code: 'ગુજરાતી',
                      label: 'Gujarati',
                      subtitle: 'ગુજરાતીમાં ચાલુ રાખો',
                      selected: state.locale == 'gu',
                      onTap: () => context.read<AppSessionCubit>().setLocale('gu'),
                    ),
                    const SizedBox(height: 12),
                    _LanguageCard(
                      code: 'ਪੰਜਾਬੀ',
                      label: 'Punjabi',
                      subtitle: 'ਪੰਜਾਬੀ ਵਿੱਚ ਜਾਰੀ ਰੱਖੋ',
                      selected: state.locale == 'pa',
                      onTap: () => context.read<AppSessionCubit>().setLocale('pa'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                label: strings.continueLabel,
                onPressed: () async {
                  await context
                      .read<AppSessionCubit>()
                      .completeLanguageSelection();
                  if (context.mounted) {
                    context.go(RouteNames.login);
                  }
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}

class _LanguageCard extends StatelessWidget {
  const _LanguageCard({
    required this.code,
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String code;
  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Row(
        children: [
          Text(
            code,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: context.muted,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            selected ? Icons.check_circle : Icons.circle_outlined,
            color: selected ? AppColors.primary : context.hairline,
          ),
        ],
      ),
    );
  }
}
