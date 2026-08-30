import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/theme_x.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../../shared/data/mock/mock_repository.dart';
import '../../../../core/constants/app_strings.dart';

class CustomerHomeBookingPage extends StatefulWidget {
  const CustomerHomeBookingPage({super.key});

  @override
  State<CustomerHomeBookingPage> createState() =>
      _CustomerHomeBookingPageState();
}

class _CustomerHomeBookingPageState extends State<CustomerHomeBookingPage> {
  String _selectedCategory = ServiceCategories.all.first.id;
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController(
    text: 'Sector 12, Noida, UP',
  );

  @override
  void dispose() {
    _descriptionController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final services = MockRepository.instance.servicesByCategory(_selectedCategory);

    return AppScaffold(
      title: context.l10n.homeBookingTitle,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Book a service at home',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Select category and describe your need',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.muted,
                  ),
            ),
            const SizedBox(height: 24),
            Text(
              'Category',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: ServiceCategories.all.length,
                itemBuilder: (context, index) {
                  final cat = ServiceCategories.all[index];
                  final selected = cat.id == _selectedCategory;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Semantics(
                      button: true,
                      selected: selected,
                      label: cat.nameEn,
                      child: Material(
                        color: selected
                            ? AppColors.primary.withValues(
                                alpha: context.isDark ? 0.22 : 0.15,
                              )
                            : context.scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: () =>
                              setState(() => _selectedCategory = cat.id),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 80,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: selected
                                  ? Border.all(
                                      color: AppColors.primary,
                                      width: 2,
                                    )
                                  : Border.all(color: context.hairline),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  cat.icon,
                                  color: AppColors.primary,
                                  size: 32,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  cat.nameEn,
                                  style: Theme.of(context).textTheme.labelSmall,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            AppTextField(
              controller: _addressController,
              label: 'Address',
              prefixIcon: const Icon(Icons.home_outlined),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _descriptionController,
              label: 'Describe the issue',
              hint: 'e.g. Kitchen tap is leaking...',
            ),
            const SizedBox(height: 24),
            if (services.isNotEmpty) ...[
              Text(
                'Suggested Services',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              ...services.map(
                (s) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AppCard(
                    onTap: () =>
                        context.push('/customer/service/${s.id}'),
                    child: Row(
                      children: [
                        Expanded(child: Text(s.title)),
                        Text('₹${s.priceFrom.toInt()}+'),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            AccentButton(
              label: 'Find Best Match',
              onPressed: () => context.push(RouteNames.customerAiDiscovery),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
