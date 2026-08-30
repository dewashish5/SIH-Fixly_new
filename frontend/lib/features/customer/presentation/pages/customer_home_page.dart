import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/theme_x.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/l10n/locale_scope.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../../shared/data/mock/mock_repository.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/widgets/category_icon_tile.dart';
import '../cubit/customer_home_cubit.dart';

class CustomerHomePage extends StatelessWidget {
  const CustomerHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CustomerHomeCubit()..load(),
      child: const _CustomerHomeView(),
    );
  }
}

class _CustomerHomeView extends StatelessWidget {
  const _CustomerHomeView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = LocaleScope.of(context).locale;

    final userName =
        MockRepository.instance.currentUser?.name ?? l10n.guestUser;

    return AppScaffold(
      titleWidget: GreetingAppBarTitle(userName: userName),
      showBack: false,
      padding: EdgeInsets.zero,
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          tooltip: l10n.notifications,
          onPressed: () => context.push(RouteNames.sharedNotifications),
        ),
      ],
      body: BlocBuilder<CustomerHomeCubit, CustomerHomeState>(
        builder: (context, state) {
          if (state.status == CustomerHomeStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _SearchBar(
                hint: l10n.searchHint,
                onTap: () => context.go(RouteNames.customerSearch),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.categories,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              _CategoryGrid(
                categories: state.categories,
                locale: locale,
                onCategoryTap: (id) => context.push(
                  RouteNames.customerSearch,
                  extra: id,
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () =>
                      context.push(RouteNames.customerCategories),
                  child: Text(l10n.viewAll),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.popularServices,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  TextButton(
                    onPressed: () => context.go(RouteNames.customerAiHelper),
                    child: Text(
                    l10n.aiHelper,
                    style: const TextStyle(color: AppColors.accent),
                  ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...state.popularServices.asMap().entries.map(
                    (entry) => _ServiceTile(
                      service: entry.value,
                      locale: locale,
                      index: entry.key,
                      onTap: () => context.push(
                        '/customer/service/${entry.value.id}',
                      ),
                    ),
                  ),
              const SizedBox(height: 16),
              SecondaryButton(
                label: l10n.homeBooking,
                onPressed: () =>
                    context.push(RouteNames.customerHomeBooking),
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.hint, required this.onTap});

  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: context.scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.hairline),
        ),
        child: Row(
          children: [
            Icon(Icons.search_rounded, color: context.scheme.primary),
            const SizedBox(width: 12),
            Text(hint, style: TextStyle(color: context.muted)),
            const Spacer(),
            Icon(
              Icons.auto_awesome_rounded,
              size: 18,
              color: AppColors.accent.withValues(alpha: 0.9),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({
    required this.categories,
    required this.locale,
    required this.onCategoryTap,
  });

  final List<ServiceCategory> categories;
  final String locale;
  final ValueChanged<String> onCategoryTap;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 10,
        crossAxisSpacing: 4,
        childAspectRatio: 0.72,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final cat = categories[index];
        return CategoryIconTile(
          category: cat,
          locale: locale,
          onTap: () => onCategoryTap(cat.id),
        );
      },
    );
  }
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({
    required this.service,
    required this.locale,
    required this.index,
    required this.onTap,
  });

  final ServiceItem service;
  final String locale;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: AppColors.primaryGradient,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(Icons.handyman_rounded, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.titleFor(locale),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    service.descriptionFor(locale),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 14, color: AppColors.accent),
                      const SizedBox(width: 4),
                      Text('${service.rating}'),
                      if (index == 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: context.isDark
                                ? AppColors.accent900
                                : AppColors.accent50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Recommended',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: context.isDark
                                  ? AppColors.accent100
                                  : AppColors.accentDark,
                            ),
                          ),
                        ),
                      ],
                      const Spacer(),
                      Text(
                        '₹${service.priceFrom.toInt()}+',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: context.muted),
          ],
        ),
      ),
    );
  }
}
