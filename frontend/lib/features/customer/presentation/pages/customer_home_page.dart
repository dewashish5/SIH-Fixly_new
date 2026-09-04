import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/theme_x.dart';
import '../../../../core/navigation/customer_navigation.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/l10n/locale_scope.dart';
import '../../../../core/location/app_location.dart';
import '../../../../core/location/location_service.dart';
import '../../../../core/widgets/app_motion.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../../core/widgets/location_picker_sheet.dart';
import '../../../../core/widgets/fixly_map_view.dart';
import '../../../../core/constants/map_constants.dart';
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

class _CustomerHomeView extends StatefulWidget {
  const _CustomerHomeView();

  @override
  State<_CustomerHomeView> createState() => _CustomerHomeViewState();
}

class _CustomerHomeViewState extends State<_CustomerHomeView> {
  bool _locating = false;

  String get _locationLabel {
    final label = AppLocation.instance.addressLabel?.trim();
    if (label != null && label.isNotEmpty) return label;
    if (AppLocation.instance.hasFix) {
      return '${AppLocation.instance.lat!.toStringAsFixed(4)}, '
          '${AppLocation.instance.lng!.toStringAsFixed(4)}';
    }
    return 'Location not set';
  }

  Future<void> _refreshLocation() async {
    if (_locating) return;
    setState(() => _locating = true);
    try {
      final ok = await LocationService.instance.ensureOnAppOpen(context);
      if (!mounted) return;
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not get current location')),
        );
      }
      setState(() {});
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _openLocationPicker() async {
    final changed = await LocationPickerSheet.show(context);
    if (changed == true && mounted) {
      setState(() {});
      context.read<CustomerHomeCubit>().load(forceNetwork: true);
    }
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      _refreshLocation(),
      context.read<CustomerHomeCubit>().load(forceNetwork: true),
    ]);
  }

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
          if (state.status == CustomerHomeStatus.loading &&
              state.categories.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          return AppRefreshIndicator(
            onRefresh: _refreshAll,
            child: ListView(
              physics: appRefreshScrollPhysics,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
              _LocationBar(
                label: _locationLabel,
                loading: _locating,
                onRefresh: _refreshLocation,
                onTap: _openLocationPicker,
              ),
              const SizedBox(height: 10),
              // ── Mini map preview ──
              _HomeMapPreview(
                onTap: _openLocationPicker,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.categories,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(48, 40),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () =>
                        context.push(RouteNames.customerCategories),
                    child: Text(l10n.viewAll),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (state.categories.isNotEmpty)
                _CategoryGrid(
                  categories: state.categories
                      .take(AppConstants.homeCategoryPreviewCount)
                      .toList(),
                  locale: locale,
                  onCategoryTap: context.openCategorySearch,
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: context.hairline),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.category_outlined,
                          size: 32, color: context.muted),
                      const SizedBox(height: 6),
                      Text(
                        'No categories available',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: context.muted,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.popularServices,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(48, 40),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () => context.goCustomerTab(2),
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
            ),
          );
        },
      ),
    );
  }
}

class _LocationBar extends StatelessWidget {
  const _LocationBar({
    required this.label,
    required this.loading,
    required this.onRefresh,
    required this.onTap,
  });

  final String label;
  final bool loading;
  final VoidCallback onRefresh;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: context.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
          child: Row(
            children: [
              Icon(Icons.location_on_rounded, color: scheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Your location',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: context.muted,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 16,
                          color: context.muted,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                tooltip: 'Use current location',
                onPressed: loading ? null : onRefresh,
                style: IconButton.styleFrom(
                  backgroundColor: scheme.primary.withValues(alpha: 0.12),
                  foregroundColor: scheme.primary,
                  minimumSize: const Size(48, 48),
                ),
                icon: loading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: scheme.primary,
                        ),
                      )
                    : const Icon(Icons.my_location_rounded),
              ),
            ],
          ),
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
        crossAxisCount: 4,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        childAspectRatio: 0.92,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final cat = categories[index];
        return CategoryIconTile(
          category: cat,
          locale: locale,
          onTap: () => onCategoryTap(cat.id),
        ).appListEnter(context, index: index, id: cat.id);
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
    final title = service.titleFor(locale);
    final description = service.descriptionFor(locale);
    final hasImage = service.imageUrl != null && service.imageUrl!.trim().isNotEmpty;
    final estimatedTime = service.estimatedTime?.trim();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: AppColors.primaryGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.18),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: hasImage
                    ? Image.network(
                        service.imageUrl!.trim(),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Center(
                          child: Icon(Icons.handyman_rounded, color: Colors.white, size: 28),
                        ),
                        loadingBuilder: (_, child, progress) {
                          if (progress == null) return child;
                          return const Center(
                            child: Icon(Icons.handyman_rounded,
                                color: Colors.white, size: 24),
                          );
                        },
                      )
                    : const Center(
                        child: Icon(Icons.handyman_rounded, color: Colors.white, size: 28),
                      ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: context.muted,
                            height: 1.3,
                          ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (estimatedTime != null && estimatedTime.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: context.scheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.schedule_rounded,
                                size: 12,
                                color: context.muted,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                estimatedTime,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: context.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const Spacer(),
                      Text(
                        '₹${service.priceFrom.toInt()}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: context.scheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: context.muted, size: 22),
          ],
        ),
      ),
    ).appListEnter(context, index: index, id: service.id);
  }
}

/// Small interactive map preview on the home screen.
/// Tapping it opens the full LocationPickerSheet.
class _HomeMapPreview extends StatelessWidget {
  const _HomeMapPreview({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final center = MapConstants.current;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            IgnorePointer(
              child: center != null
                  ? FixlyMapView(
                      height: 148,
                      borderRadius: BorderRadius.circular(16),
                      center: center,
                      zoom: MapConstants.defaultZoom,
                      showDestinationPin: true,
                      claimGestures: false,
                      showZoomControls: false,
                      showRecenterButton: false,
                    )
                  : Container(
                      height: 148,
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.location_searching,
                                size: 28, color: scheme.primary.withValues(alpha: 0.5)),
                            const SizedBox(height: 6),
                            Text(
                              'Tap to set your location',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: scheme.primary.withValues(alpha: 0.6),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
            // Tap-to-edit overlay pill
            Positioned(
              right: 10,
              bottom: 10,
              child: Material(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(20),
                elevation: 2,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit_location_alt_rounded,
                            size: 15, color: scheme.primary),
                        const SizedBox(width: 5),
                        Text(
                          'Change',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: scheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
