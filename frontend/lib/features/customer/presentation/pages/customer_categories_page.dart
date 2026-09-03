import 'package:flutter/material.dart';

import '../../../../core/navigation/customer_navigation.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/app_motion.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../../shared/widgets/category_icon_tile.dart';

class CustomerCategoriesPage extends StatelessWidget {
  const CustomerCategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = context.l10n.locale;
    final categories = ServiceCategories.all;

    return AppScaffold(
      title: l10n.allCategories,
      body: GridView.builder(
        padding: const EdgeInsets.only(top: 8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 20,
          crossAxisSpacing: 16,
          childAspectRatio: 0.85,
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          return Center(
            child: CategoryIconTile(
              category: cat,
              locale: locale,
              onTap: () => context.openCategorySearch(cat.id),
            ),
          ).appListEnter(context, index: index, id: cat.id);
        },
      ),
    );
  }
}
