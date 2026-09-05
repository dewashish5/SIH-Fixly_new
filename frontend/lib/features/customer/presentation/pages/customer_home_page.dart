import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/theme_x.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/map_constants.dart';
import '../../../../core/l10n/locale_scope.dart';
import '../../../../core/location/app_location.dart';
import '../../../../core/location/location_service.dart';
import '../../../../core/navigation/customer_navigation.dart';
import '../../../../core/widgets/app_motion.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../../core/widgets/fixly_map_view.dart';
import '../../../../core/widgets/location_picker_sheet.dart';
import '../../../../shared/data/mock/mock_repository.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/widgets/category_icon_tile.dart';
import '../cubit/customer_home_cubit.dart';
import '../../../../core/utils/toast_utils.dart';

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
        ToastUtils.showToast(context: context, message: 'Could not get current location');
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
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusBarH = MediaQuery.of(context).padding.top;

    final userName =
        MockRepository.instance.currentUser?.name ?? l10n.guestUser;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: scheme.surface,
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF080F1E), // Keeps map/pull-down gradient dark
        body: BlocBuilder<CustomerHomeCubit, CustomerHomeState>(
          builder: (context, state) {
            return AppRefreshIndicator(
              onRefresh: _refreshAll,
              child: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverAppBar(
                      pinned: true,
                      expandedHeight: statusBarH + 280,
                      toolbarHeight: 90,
                      backgroundColor: scheme.surface,
                      elevation: 0,
                      flexibleSpace: FlexibleSpaceBar(
                        collapseMode: CollapseMode.pin, // Keeps blur at the very top
                        background: _HomeMapHero(
                          statusBarH: statusBarH,
                          onOpenLocationPicker: _openLocationPicker,
                        ),
                      ),
                      title: Padding(
                        padding: const EdgeInsets.only(left: 0, right: 0, bottom: 8),
                        child: _AppBarTitleContent(
                          userName: userName,
                          locationLabel: _locationLabel,
                          locating: _locating,
                          onOpenLocationPicker: _openLocationPicker,
                          onNotificationsTap: () =>
                              context.push(RouteNames.sharedNotifications),
                        ),
                      ),
                      bottom: PreferredSize(
                        preferredSize: const Size.fromHeight(24),
                        child: Container(
                          height: 24,
                          decoration: BoxDecoration(
                            color: scheme.surface,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(24),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ];
                },
                body: Container(
                  color: scheme.surface,
                  child: Column(
                    children: [
                      // Pinned Categories & Popular Services Header
                      _buildCategoriesAndHeader(context, state, l10n, locale),
                      // Scrollable Services List
                      Expanded(
                        child: state.status == CustomerHomeStatus.loading &&
                                state.popularServices.isEmpty
                            ? _buildShimmerList()
                            : ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.only(top: 8, bottom: 32),
                                itemCount: state.popularServices.length,
                                itemBuilder: (context, index) {
                                  final service = state.popularServices[index];
                                  return _ServiceTile(
                                    service: service,
                                    locale: locale,
                                    index: index,
                                    onTap: () => context.push(
                                      '/customer/service/${service.id}',
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCategoriesAndHeader(
    BuildContext context,
    CustomerHomeState state,
    dynamic l10n,
    String locale,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
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
                onPressed: () => context.push(RouteNames.customerCategories),
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
            _buildEmptyCategories(context),
          const SizedBox(height: 16),
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
        ],
      ),
    );
  }

  Widget _buildEmptyCategories(BuildContext context) {
    return Container(
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
          Icon(Icons.category_outlined, size: 32, color: context.muted),
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
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 8, bottom: 32),
      itemCount: 4,
      itemBuilder: (context, index) {
        return const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: _ShimmerServiceTile(),
        );
      },
    );
  }
}

class _AppBarTitleContent extends StatelessWidget {
  const _AppBarTitleContent({
    required this.userName,
    required this.locationLabel,
    required this.locating,
    required this.onOpenLocationPicker,
    required this.onNotificationsTap,
  });

  final String userName;
  final String locationLabel;
  final bool locating;
  final VoidCallback onOpenLocationPicker;
  final VoidCallback onNotificationsTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.timeGreeting(DateTime.now().hour),
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 1),
              Text(
                userName,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                  letterSpacing: -0.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              InkWell(
                onTap: onOpenLocationPicker,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        color: AppColors.primary400,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          locationLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurface.withValues(alpha: 0.95),
                          ),
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 16,
                        color: scheme.onSurface.withValues(alpha: 0.85),
                      ),
                      if (locating) ...[
                        const SizedBox(width: 8),
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: AppColors.primary400,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: scheme.onSurface.withValues(alpha: 0.08),
            shape: BoxShape.circle,
            border: Border.all(
              color: scheme.onSurface.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: IconButton(
            icon: Icon(
              Icons.notifications_outlined,
              color: scheme.onSurface,
              size: 22,
            ),
            tooltip: l10n.notifications,
            onPressed: onNotificationsTap,
            padding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }
}

class _HomeMapHero extends StatelessWidget {
  const _HomeMapHero({
    required this.statusBarH,
    required this.onOpenLocationPicker,
  });

  final double statusBarH;
  final VoidCallback onOpenLocationPicker;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final center = MapConstants.current;

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. The Map
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onOpenLocationPicker,
          child: center != null
              ? IgnorePointer(
                  child: FixlyMapView(
                    expand: true,
                    borderRadius: BorderRadius.zero,
                    center: center,
                    zoom: MapConstants.defaultZoom,
                    showDestinationPin: true,
                    claimGestures: false,
                    showZoomControls: false,
                    showRecenterButton: false,
                  ),
                )
              : Container(
                  color: const Color(0xFF0A1428),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.location_searching,
                          size: 32,
                          color: AppColors.primary400.withValues(alpha: 0.7),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap to set your location',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: Colors.white70,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),

        // 2. Blur and subtle gradient at the top (Ensures text/status bar is readable)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: statusBarH + 160,
          child: IgnorePointer(
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        scheme.surface.withValues(alpha: 0.8),
                        scheme.surface.withValues(alpha: 0.3),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.6, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
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
      padding: EdgeInsets.zero,
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
    final hasImage =
        service.imageUrl != null && service.imageUrl!.trim().isNotEmpty;
    final estimatedTime = service.estimatedTime?.trim();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
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
                        errorBuilder: (context, error, stackTrace) =>
                            const Center(
                          child: Icon(Icons.handyman_rounded,
                              color: Colors.white, size: 28),
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
                        child: Icon(Icons.handyman_rounded,
                            color: Colors.white, size: 28),
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
                      if (estimatedTime != null &&
                          estimatedTime.isNotEmpty) ...[
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

class _ShimmerServiceTile extends StatefulWidget {
  const _ShimmerServiceTile();

  @override
  State<_ShimmerServiceTile> createState() => _ShimmerServiceTileState();
}

class _ShimmerServiceTileState extends State<_ShimmerServiceTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: 0.4 + (_controller.value * 0.6),
          child: AppCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 120,
                        height: 16,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        height: 12,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: 60,
                        height: 16,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
