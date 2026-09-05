import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../cubit/active_job_cubit.dart';

class WorkerRatingPage extends StatefulWidget {
  const WorkerRatingPage({super.key, required this.bookingId, this.customerId});

  final String bookingId;
  final String? customerId;

  @override
  State<WorkerRatingPage> createState() => _WorkerRatingPageState();
}

class _WorkerRatingPageState extends State<WorkerRatingPage> {
  int _rating = 0;
  final TextEditingController _commentCtrl = TextEditingController();
  final Set<String> _selectedTraits = {};

  final List<String> _traits = [
    '👍 Polite',
    '🏠 Clean Location',
    '📝 Accurate Description',
    '⏰ Was Available',
    '💰 Fair Expectations',
  ];

  void _submit() {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating')),
      );
      return;
    }
    
    // In actual implementation, customerId might be non-null if passed
    // Here we provide a fallback
    final cId = widget.customerId ?? 'unknown_customer';

    context.read<ActiveJobCubit>().submitWorkerReview(
      bookingId: widget.bookingId,
      customerId: cId,
      rating: _rating,
      comment: _commentCtrl.text.trim(),
      traits: _selectedTraits.toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ActiveJobCubit>().state;
    final job = state.job;
    
    return PopScope(
      canPop: false,
      child: BlocListener<ActiveJobCubit, ActiveJobState>(
        listener: (context, state) {
          if (state.status == ActiveJobStatus.reviewSubmitted) {
            context.go(RouteNames.workerDashboard);
          } else if (state.status == ActiveJobStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error ?? 'Failed to submit review')),
            );
          }
        },
        child: AppScaffold(
          title: 'Rate Customer',
          showBack: false,
          body: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 24),
                if (job != null) ...[
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: job.customerAvatar != null ? NetworkImage(job.customerAvatar!) : null,
                    child: job.customerAvatar == null ? Text(job.customerName[0].toUpperCase(), style: const TextStyle(fontSize: 32)) : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    job.customerName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < _rating ? Icons.star : Icons.star_border,
                        size: 40,
                        color: AppColors.warning,
                      ),
                      onPressed: () {
                        setState(() {
                          _rating = index + 1;
                        });
                      },
                    );
                  }),
                ),
                const SizedBox(height: 32),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _traits.map((trait) {
                    final isSelected = _selectedTraits.contains(trait);
                    return FilterChip(
                      label: Text(trait),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedTraits.add(trait);
                          } else {
                            _selectedTraits.remove(trait);
                          }
                        });
                      },
                      selectedColor: AppColors.primary100,
                      checkmarkColor: AppColors.primary,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),
                AppTextField(
                  controller: _commentCtrl,
                  hint: 'Optional comment about the customer',
                  maxLines: 3,
                ),
                const SizedBox(height: 32),
                PrimaryButton(
                  label: 'Submit & Finish',
                  loading: state.status == ActiveJobStatus.loading,
                  onPressed: _submit,
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
