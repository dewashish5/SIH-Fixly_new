import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_motion.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../payments/data/payments_api_repository.dart';

class WorkerEarningsPage extends StatefulWidget {
  const WorkerEarningsPage({super.key});

  @override
  State<WorkerEarningsPage> createState() => _WorkerEarningsPageState();
}

class _WorkerEarningsPageState extends State<WorkerEarningsPage> {
  final _payments = PaymentsApiRepository();
  bool _loading = true;
  String? _error;
  double _today = 0;
  double _month = 0;
  List<Map<String, dynamic>> _txs = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final summary = await _payments.workerEarningsSummary();
      final wallet = await _payments.workerWallet();
      if (!mounted) return;
      setState(() {
        _today = (summary['today'] as num?)?.toDouble() ?? 0;
        _month = (summary['thisMonth'] as num?)?.toDouble() ?? 0;
        _txs = wallet.history;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: context.l10n.earnings,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Today',
                              style: Theme.of(context).textTheme.labelMedium),
                          Text(
                            '₹${_today.toStringAsFixed(0)}',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('This month',
                              style: Theme.of(context).textTheme.labelMedium),
                          Text(
                            '₹${_month.toStringAsFixed(0)}',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('Recent payouts',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    Expanded(
                      child: _txs.isEmpty
                          ? const Center(child: Text('No transactions yet'))
                          : AppRefreshIndicator(
                              onRefresh: _load,
                              child: ListView.builder(
                                physics: appRefreshScrollPhysics,
                                itemCount: _txs.length,
                                itemBuilder: (context, index) {
                                final tx = _txs[index];
                                final amount =
                                    (tx['amount'] as num?)?.toDouble() ?? 0;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: AppCard(
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            (tx['status'] ?? 'Transaction')
                                                .toString(),
                                          ),
                                        ),
                                        Text(
                                          '+₹${amount.toStringAsFixed(0)}',
                                          style: const TextStyle(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ).appListEnter(
                                  context,
                                  index: index,
                                  id: tx['id'] ?? index,
                                );
                              },
                            ),
                          ),
                    ),
                  ],
                ),
    );
  }
}
