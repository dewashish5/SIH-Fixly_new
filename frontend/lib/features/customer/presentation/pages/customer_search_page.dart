import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/theme_x.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/app_motion.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../../shared/models/models.dart';
import '../cubit/search_cubit.dart';

class CustomerSearchPage extends StatelessWidget {
  const CustomerSearchPage({
    super.key,
    this.categoryId,
    this.showBack = false,
  });

  final String? categoryId;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = SearchCubit();
        if (categoryId != null && categoryId!.isNotEmpty) {
          cubit.filterByCategory(categoryId!);
        } else {
          cubit.search('');
        }
        return cubit;
      },
      child: _CustomerSearchView(
        categoryId: categoryId,
        showBack: showBack,
      ),
    );
  }
}

class _CustomerSearchView extends StatefulWidget {
  const _CustomerSearchView({
    this.categoryId,
    required this.showBack,
  });

  final String? categoryId;
  final bool showBack;

  @override
  State<_CustomerSearchView> createState() => _CustomerSearchViewState();
}

class _CustomerSearchViewState extends State<_CustomerSearchView> {
  late final TextEditingController _controller;

  ServiceCategory? get _matchedCategory {
    final id = widget.categoryId?.toLowerCase().trim();
    if (id == null || id.isEmpty) return null;
    for (final cat in ServiceCategories.all) {
      if (cat.id == id ||
          cat.nameEn.toLowerCase() == id ||
          id.contains(cat.id)) {
        return cat;
      }
    }
    return null;
  }

  String get _categoryTitle {
    final cat = _matchedCategory;
    if (cat != null) return cat.nameFor(context.l10n.locale);
    final id = widget.categoryId;
    if (id == null || id.isEmpty) return context.l10n.search;
    return id[0].toUpperCase() + id.substring(1);
  }

  @override
  void initState() {
    super.initState();
    final query = context.read<SearchCubit>().state.query;
    _controller = TextEditingController(text: query);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await context.read<SearchCubit>().refresh();
    if (!mounted) return;
    final query = context.read<SearchCubit>().state.query;
    if (_controller.text != query) {
      _controller.text = query;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = l10n.locale;
    final isCategoryMode = widget.categoryId != null && widget.categoryId!.isNotEmpty;

    return AppScaffold(
      title: _categoryTitle,
      showBack: widget.showBack,
      body: AppRefreshIndicator(
        onRefresh: _onRefresh,
        child: CustomScrollView(
          physics: appRefreshScrollPhysics,
          slivers: [
            // 1. Hero Search & Category Intro
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (isCategoryMode) ...[
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: AppColors.primary.withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.verified_rounded,
                                    size: 14, color: AppColors.primary),
                                const SizedBox(width: 4),
                                Text(
                                  'Verified Specialists & Fixed Pricing',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],
                    AppTextField(
                      controller: _controller,
                      hint: isCategoryMode
                          ? 'Search in $_categoryTitle services or skills...'
                          : l10n.searchHint,
                      prefixIcon: const Icon(Icons.search_rounded),
                      onChanged: (q) => context.read<SearchCubit>().search(q),
                    ),
                  ],
                ),
              ),
            ),

            // 2. Top-Matching & Nearest Workers Section
            SliverToBoxAdapter(
              child: BlocBuilder<SearchCubit, SearchState>(
                builder: (context, state) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            const Icon(Icons.stars_rounded,
                                size: 20, color: AppColors.accent),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Top Matching Specialists',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                            if (state.nearbyWorkers.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${state.nearbyWorkers.length} Available',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.success,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Ranked by highest rating, skill relevance & proximity',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: context.muted,
                              ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (state.isLoadingWorkers)
                        SizedBox(
                          height: 175,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: 2,
                            separatorBuilder: (context, index) => const SizedBox(width: 12),
                            itemBuilder: (context, index) => const _WorkerSkeletonCard(),
                          ),
                        )
                      else if (state.nearbyWorkers.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                vertical: 16, horizontal: 16),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest
                                  .withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: context.hairline),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.person_search_rounded,
                                      size: 24, color: AppColors.accentDark),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Auto-Matching Active',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(fontWeight: FontWeight.w700),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Select any service package below and our smart system will auto-assign the best specialist to your doorstep.',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(color: context.muted),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        SizedBox(
                          height: 195,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: state.nearbyWorkers.length,
                            separatorBuilder: (context, index) => const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final worker = state.nearbyWorkers[index];
                              return _WorkerCard(
                                worker: worker,
                                targetCategory: widget.categoryId ?? '',
                                onTap: () => context.push(
                                    '/customer/worker/${worker.id}'),
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 24),
                    ],
                  );
                },
              ),
            ),

            // 3. Category Services Section Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Icon(Icons.home_repair_service_rounded,
                        size: 20, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Services in this Category',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 10)),

            // 4. Services List
            BlocBuilder<SearchCubit, SearchState>(
              builder: (context, state) {
                if (state.isSearching) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (state.results.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.search_off_rounded,
                                size: 42, color: context.muted),
                            const SizedBox(height: 8),
                            Text(
                              l10n.noServicesFound,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(color: context.muted),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final service = state.results[index];
                        return _ServicePackageTile(
                          service: service,
                          locale: locale,
                          onTap: () =>
                              context.push('/customer/service/${service.id}'),
                        ).appListEnter(
                          context,
                          index: index,
                          id: service.id,
                        );
                      },
                      childCount: state.results.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// WORKER CARD WIDGET (Rich, High-rated, Distance, Skill Badges)
// -------------------------------------------------------------
class _WorkerCard extends StatelessWidget {
  const _WorkerCard({
    required this.worker,
    required this.targetCategory,
    required this.onTap,
  });

  final WorkerProfile worker;
  final String targetCategory;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final normalizedCategory = targetCategory.toLowerCase().trim();

    return Container(
      width: 270,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.hairline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Row: Avatar + Name + Rating
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.primary, width: 1.5),
                          ),
                          child: ClipOval(
                            child: (worker.avatarUrl != null &&
                                    worker.avatarUrl!.isNotEmpty)
                                ? Image.network(
                                    worker.avatarUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => const Icon(
                                        Icons.person_rounded,
                                        size: 26,
                                        color: AppColors.primary),
                                  )
                                : const Icon(Icons.person_rounded,
                                    size: 26, color: AppColors.primary),
                          ),
                        ),
                        if (worker.isVerified)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: AppColors.success,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check,
                                  size: 10, color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            worker.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.star_rounded,
                                        size: 13, color: AppColors.accentDark),
                                    const SizedBox(width: 3),
                                    Text(
                                      worker.rating > 0
                                          ? worker.rating.toStringAsFixed(1)
                                          : '4.9',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.accentDark,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${worker.jobsCompleted} jobs',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(color: context.muted),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Distance & Rate row
                Row(
                  children: [
                    if (worker.distanceKm != null) ...[
                      const Icon(Icons.near_me_rounded,
                          size: 13, color: AppColors.primary),
                      const SizedBox(width: 3),
                      Text(
                        '${worker.distanceKm} km away',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const Spacer(),
                    ] else ...[
                      const Icon(Icons.bolt_rounded,
                          size: 14, color: AppColors.accent),
                      const SizedBox(width: 2),
                      Text(
                        'Fast dispatch',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: context.muted,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      const Spacer(),
                    ],
                    Text(
                      worker.hourlyRate != null
                          ? '₹${worker.hourlyRate!.toInt()}/hr'
                          : 'Top Rated',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Skills matching chips
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: (worker.skills.isNotEmpty
                          ? worker.skills.take(3)
                          : ['General Service', 'Verified'])
                      .map((skill) {
                    final isMatching = normalizedCategory.isNotEmpty &&
                        (skill.toLowerCase().contains(normalizedCategory) ||
                            normalizedCategory.contains(skill.toLowerCase()));

                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: isMatching
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : (context.isDark
                                ? Colors.white10
                                : const Color(0xfff1f5f9)),
                        borderRadius: BorderRadius.circular(6),
                        border: isMatching
                            ? Border.all(
                                color: AppColors.primary.withValues(alpha: 0.3))
                            : null,
                      ),
                      child: Text(
                        skill,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight:
                              isMatching ? FontWeight.w700 : FontWeight.w500,
                          color: isMatching
                              ? AppColors.primary
                              : (context.isDark ? Colors.white70 : Colors.black87),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WorkerSkeletonCard extends StatelessWidget {
  const _WorkerSkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 100,
                      height: 12,
                      color: Colors.grey.withValues(alpha: 0.15),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 60,
                      height: 10,
                      color: Colors.grey.withValues(alpha: 0.12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// SERVICE PACKAGE TILE (With Image, Details & Action)
// -------------------------------------------------------------
class _ServicePackageTile extends StatelessWidget {
  const _ServicePackageTile({
    required this.service,
    required this.locale,
    required this.onTap,
  });

  final ServiceItem service;
  final String locale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasImage = service.imageUrl != null && service.imageUrl!.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Service Image / Icon
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  colors: AppColors.primaryGradient,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: hasImage
                    ? Image.network(
                        service.imageUrl!.trim(),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.home_repair_service_rounded,
                            color: Colors.white,
                            size: 32),
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return const Center(
                            child: Icon(Icons.home_repair_service_rounded,
                                color: Colors.white, size: 28),
                          );
                        },
                      )
                    : const Icon(Icons.home_repair_service_rounded,
                        color: Colors.white, size: 32),
              ),
            ),
            const SizedBox(width: 14),

            // Service details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.titleFor(locale),
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    service.descriptionFor(locale),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.muted,
                          fontSize: 12,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'From ₹${service.priceFrom.toInt()}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                      if (service.estimatedTime != null &&
                          service.estimatedTime!.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: (context.isDark
                                ? Colors.white10
                                : const Color(0xfff1f5f9)),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.access_time_rounded,
                                  size: 11, color: AppColors.outline),
                              const SizedBox(width: 3),
                              Text(
                                service.estimatedTime!,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.outline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded, color: AppColors.outline),
          ],
        ),
      ),
    );
  }
}
