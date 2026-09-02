import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_strings.dart';
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

  String? get _categoryTitle {
    final id = widget.categoryId;
    if (id == null || id.isEmpty) return null;
    for (final cat in ServiceCategories.all) {
      if (cat.id == id) {
        return cat.nameFor(context.l10n.locale);
      }
    }
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
    final title = _categoryTitle ?? l10n.search;

    return AppScaffold(
      title: title,
      showBack: widget.showBack,
      body: AppRefreshIndicator(
        onRefresh: _onRefresh,
        child: CustomScrollView(
          physics: appRefreshScrollPhysics,
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.categoryId != null) ...[
                    Text(
                      l10n.servicesInCategory,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.outline,
                          ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  AppTextField(
                    controller: _controller,
                    hint: l10n.searchHint,
                    prefixIcon: const Icon(Icons.search),
                    onChanged: (q) => context.read<SearchCubit>().search(q),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            BlocBuilder<SearchCubit, SearchState>(
              builder: (context, state) {
                if (state.isSearching) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (state.results.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Text(
                        l10n.noServicesFound,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppColors.outline,
                            ),
                      ),
                    ),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final service = state.results[index];
                      return _SearchResultTile(
                        service: service,
                        locale: locale,
                        onTap: () =>
                            context.push('/customer/service/${service.id}'),
                      );
                    },
                    childCount: state.results.length,
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

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({
    required this.service,
    required this.locale,
    required this.onTap,
  });

  final ServiceItem service;
  final String locale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppStrings(locale);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        onTap: onTap,
        child: Row(
          children: [
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
                  const SizedBox(height: 8),
                  Text(
                    l10n.fromPrice.replaceFirst(
                      '%s',
                      '${service.priceFrom.toInt()}',
                    ),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }
}
