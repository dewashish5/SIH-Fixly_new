import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../../core/utils/toast_utils.dart';
import '../../../shared/presentation/cubit/profile_cubit.dart';
import '../../../workers/data/workers_api_repository.dart';

class WorkerRateSettingsPage extends StatefulWidget {
  const WorkerRateSettingsPage({super.key});

  @override
  State<WorkerRateSettingsPage> createState() => _WorkerRateSettingsPageState();
}

class _WorkerRateSettingsPageState extends State<WorkerRateSettingsPage> {
  final Map<String, TextEditingController> _controllers = {};
  bool _isLoading = false;
  final double _minWage = 300.0;

  @override
  void initState() {
    super.initState();
    final profile = context.read<ProfileCubit>().state;
    if (profile != null) {
      final defaultRate = profile.hourlyRate ?? 300.0;
      for (final cat in profile.categories) {
        _controllers[cat] = TextEditingController(text: defaultRate.toStringAsFixed(0));
      }
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    bool hasError = false;
    final rates = <Map<String, dynamic>>[];
    for (final entry in _controllers.entries) {
      final rate = double.tryParse(entry.value.text) ?? 0;
      if (rate < _minWage) {
        hasError = true;
        break;
      }
      rates.add({
        'category': entry.key,
        'rate': rate,
      });
    }

    if (hasError) {
      ToastUtils.showError(context: context, message: 'All rates must be at least ₹${_minWage.toStringAsFixed(0)}/visit');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final repo = WorkersApiRepository();
      await repo.updateWorkerRates(rates);
      if (mounted) {
        ToastUtils.showSuccess(context: context, message: 'Rates updated successfully');
        context.read<ProfileCubit>().load();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.showError(context: context, message: e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileCubit>().state;

    return AppScaffold(
      title: 'Rate Settings',
      body: profile == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.blue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Minimum allowed rate: ₹${_minWage.toStringAsFixed(0)}/visit to comply with federation standards.',
                          style: const TextStyle(color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    children: _controllers.entries.map((e) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: AppTextField(
                          label: '${e.key} Rate (₹)',
                          controller: e.value,
                          keyboardType: TextInputType.number,
                          prefixIcon: Icon(Icons.currency_rupee),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                PrimaryButton(
                  label: 'Save Changes',
                  loading: _isLoading,
                  onPressed: _save,
                ),
              ],
            ),
    );
  }
}
