import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../../core/constants/app_strings.dart';

class CustomerAddPartsPage extends StatefulWidget {
  const CustomerAddPartsPage({super.key});

  @override
  State<CustomerAddPartsPage> createState() => _CustomerAddPartsPageState();
}

class _CustomerAddPartsPageState extends State<CustomerAddPartsPage> {
  final _parts = <_PartItem>[
    const _PartItem(name: 'Switch (Modular)', price: 120, qty: 1),
    const _PartItem(name: 'Wire (2m)', price: 80, qty: 2),
  ];

  double get _total =>
      _parts.fold(0, (sum, p) => sum + p.price * p.qty);

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: context.l10n.addParts,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _parts.add(
              _PartItem(
                name: 'New Part ${_parts.length + 1}',
                price: 100,
                qty: 1,
              ),
            );
          });
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Parts added by worker',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.outline,
                ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _parts.length,
              itemBuilder: (context, index) {
                final part = _parts[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                part.name,
                                style:
                                    Theme.of(context).textTheme.titleSmall,
                              ),
                              Text('₹${part.price} × ${part.qty}'),
                            ],
                          ),
                        ),
                        Text(
                          '₹${part.price * part.qty}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: _parts.length > 1
                              ? () => setState(() => _parts.removeAt(index))
                              : null,
                        ),
                      ],
                    ),
                  ).animate(delay: (index * 60).ms).fadeIn(),
                );
              },
            ),
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Parts Total',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                '₹${_total.toInt()}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.primary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Approve & Pay',
            onPressed: () => context.push(RouteNames.customerPayment),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _PartItem {
  const _PartItem({
    required this.name,
    required this.price,
    required this.qty,
  });

  final String name;
  final int price;
  final int qty;
}
