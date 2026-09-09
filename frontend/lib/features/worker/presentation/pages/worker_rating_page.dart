import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../core/utils/toast_utils.dart';
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
  int _rating = 5;
  final TextEditingController _commentCtrl = TextEditingController();
  final Set<String> _selectedTraits = {};
  final List<String> _photos = [];
  final ImagePicker _picker = ImagePicker();

  final List<String> _traits = [
    '👍 Polite & Respectful',
    '🏠 Clean & Accessible Site',
    '📝 Accurate Work Description',
    '⏰ Present on Time',
    '💰 Fair Expectations',
    '⚡ Quick Approval',
  ];

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_photos.length >= 3) {
      ToastUtils.showToast(context: context, message: 'Maximum 3 photos allowed');
      return;
    }
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 80,
      );
      if (picked != null && mounted) {
        setState(() {
          _photos.add(picked.path);
        });
      }
    } catch (_) {
      if (mounted) {
        ToastUtils.showError(context: context, message: 'Could not select photo');
      }
    }
  }

  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Attach Job / Site Photo (Optional)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFEFF6FF),
                  child: Icon(Icons.camera_alt_rounded, color: Colors.blue),
                ),
                title: const Text('Take Photo with Camera'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFF0FDF4),
                  child: Icon(Icons.photo_library_rounded, color: Colors.green),
                ),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (_rating == 0) {
      ToastUtils.showToast(context: context, message: 'Please select a star rating');
      return;
    }

    final cId = widget.customerId ?? '';

    context.read<ActiveJobCubit>().submitWorkerReview(
      bookingId: widget.bookingId,
      customerId: cId,
      rating: _rating,
      comment: _commentCtrl.text.trim(),
      traits: _selectedTraits.toList(),
      photoPaths: _photos,
    );
  }

  String _ratingLabel(int r) {
    switch (r) {
      case 1:
        return '1 / 5 - Poor Experience';
      case 2:
        return '2 / 5 - Below Average';
      case 3:
        return '3 / 5 - Good & Decent';
      case 4:
        return '4 / 5 - Very Good';
      case 5:
        return '5 / 5 - Excellent Customer!';
      default:
        return 'Tap stars to rate';
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ActiveJobCubit>().state;
    final job = state.job;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      child: BlocListener<ActiveJobCubit, ActiveJobState>(
        listener: (context, state) {
          if (state.status == ActiveJobStatus.reviewSubmitted) {
            ToastUtils.showSuccess(
              context: context,
              message: 'Review submitted! Great work on completing this job.',
            );
            context.go(RouteNames.workerDashboard);
          } else if (state.status == ActiveJobStatus.failure) {
            ToastUtils.showError(
              context: context,
              message: state.error ?? 'Failed to submit review',
            );
          }
        },
        child: AppScaffold(
          title: 'Rate Customer & Finish',
          showBack: false,
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Customer Info Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                        backgroundImage: (job?.customerAvatar != null && job!.customerAvatar!.isNotEmpty)
                            ? NetworkImage(job.customerAvatar!)
                            : null,
                        child: (job?.customerAvatar == null || job!.customerAvatar!.isEmpty)
                            ? Text(
                                (job?.customerName.isNotEmpty == true)
                                    ? job!.customerName[0].toUpperCase()
                                    : 'C',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.check_circle, color: Color(0xFF10B981), size: 14),
                                SizedBox(width: 4),
                                Text(
                                  'Work Complete',
                                  style: TextStyle(
                                    color: Color(0xFF10B981),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              job?.customerName ?? 'Customer',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              job?.title ?? 'Service Booking',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).hintColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 2. Interactive Star Rating
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'How was your experience?',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          final star = index + 1;
                          return IconButton(
                            iconSize: 38,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            icon: Icon(
                              star <= _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                              color: const Color(0xFFF59E0B),
                            ),
                            onPressed: () {
                              setState(() {
                                _rating = star;
                              });
                            },
                          );
                        }),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _ratingLabel(_rating),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD97706),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 3. Customer Positive Traits
                const Text(
                  'Compliments & Traits (Optional)',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _traits.map((trait) {
                    final isSelected = _selectedTraits.contains(trait);
                    return FilterChip(
                      label: Text(trait),
                      selected: isSelected,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? AppColors.primary : null,
                      ),
                      selectedColor: AppColors.primary.withValues(alpha: 0.12),
                      checkmarkColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedTraits.add(trait);
                          } else {
                            _selectedTraits.remove(trait);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // 4. Detailed Description & Feedback (Optional)
                Row(
                  children: [
                    const Text(
                      'Review Description',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '(Optional)',
                      style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _commentCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Share notes about site conditions, customer cooperation, or remarks...',
                    hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 5. Work Completion / Site Photos (Optional)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Work / Site Photos',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '(Optional, max 3)',
                          style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
                        ),
                      ],
                    ),
                    if (_photos.length < 3)
                      TextButton.icon(
                        onPressed: _showImageSourcePicker,
                        icon: const Icon(Icons.add_a_photo_rounded, size: 16),
                        label: const Text('Add Photo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                // Photo Thumbnails Row
                if (_photos.isEmpty)
                  InkWell(
                    onTap: _showImageSourcePicker,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 90,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.withValues(alpha: 0.25),
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.camera_enhance_rounded, color: Colors.grey.shade400, size: 22),
                            const SizedBox(width: 8),
                            Text(
                              'Tap to attach proof of work / completed site',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  Row(
                    children: [
                      for (int i = 0; i < _photos.length; i++) ...[
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                File(_photos[i]),
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 2,
                              right: 2,
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _photos.removeAt(i);
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(
                                    color: Colors.black87,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 10),
                      ],
                      if (_photos.length < 3)
                        InkWell(
                          onTap: _showImageSourcePicker,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                            ),
                            child: const Center(
                              child: Icon(Icons.add, color: Colors.grey, size: 28),
                            ),
                          ),
                        ),
                    ],
                  ),
                const SizedBox(height: 32),

                // 6. Submit Button
                ElevatedButton(
                  onPressed: state.status == ActiveJobStatus.loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    elevation: 3,
                  ),
                  child: state.status == ActiveJobStatus.loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Submit Review & Finish',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
