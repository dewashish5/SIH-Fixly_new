import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/theme_x.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../auth/data/auth_api_repository.dart';
import '../../../workers/data/workers_api_repository.dart';

class WorkerReliabilityPage extends StatefulWidget {
  const WorkerReliabilityPage({super.key});

  @override
  State<WorkerReliabilityPage> createState() => _WorkerReliabilityPageState();
}

class _WorkerReliabilityPageState extends State<WorkerReliabilityPage> {
  final _auth = AuthApiRepository();
  final _workers = WorkersApiRepository();
  bool _loading = true;
  String? _error;
  int _score = 0;
  int _onTime = 0;
  int _completion = 0;
  double _rating = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final user = await _auth.fetchMe();
      final data = await _workers.fetchReliability(user.id);
      if (!mounted) return;
      setState(() {
        _score = (data['score'] as num?)?.toInt() ?? 0;
        _onTime = (data['onTimeArrival'] as num?)?.toInt() ?? 0;
        _completion = (data['completionRate'] as num?)?.toInt() ?? 0;
        _rating = (data['rating'] as num?)?.toDouble() ?? 0;
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
      title: context.l10n.reliabilityScore,
      showBack: true,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: SizedBox(
                        width: 160,
                        height: 160,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 160,
                              height: 160,
                              child: CircularProgressIndicator(
                                value: _score / 100,
                                strokeWidth: 12,
                                backgroundColor:
                                    context.scheme.surfaceContainerHighest,
                                color: AppColors.primary,
                              ),
                            ),
                            Text(
                              '$_score%',
                              style: Theme.of(context).textTheme.headlineLarge,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _MetricRow(label: 'On-time arrival', value: '$_onTime%'),
                          const SizedBox(height: 12),
                          _MetricRow(label: 'Job completion', value: '$_completion%'),
                          const SizedBox(height: 12),
                          _MetricRow(
                            label: 'Customer rating',
                            value: _rating.toStringAsFixed(1),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Higher reliability gets priority in job matching.',
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }
}
