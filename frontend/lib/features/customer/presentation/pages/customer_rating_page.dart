import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../cubit/booking_flow_cubit.dart';
import '../../../reviews/data/reviews_api_repository.dart';

class CustomerRatingPage extends StatefulWidget {
  const CustomerRatingPage({super.key});

  @override
  State<CustomerRatingPage> createState() => _CustomerRatingPageState();
}

class _CustomerRatingPageState extends State<CustomerRatingPage> {
  int _rating = 0; // Starts at 0 to force interaction
  final _feedbackController = TextEditingController();
  bool _submitting = false;
  final List<String> _selectedTags = [];

  final List<String> _availableTags = [
    '⚡ On Time',
    '🛠️ Quality Work',
    '🤝 Polite & Professional',
    '🧼 Clean Work Area',
  ];

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting || _rating == 0) return;
    
    final cubit = context.read<BookingFlowCubit>();
    final booking = cubit.state.booking;
    final workerId = booking?.workerId;
    final bookingId = booking?.id;

    if (bookingId != null && workerId != null) {
      setState(() => _submitting = true);
      try {
        await ReviewsApiRepository().submit(
          bookingId: bookingId,
          workerId: workerId,
          rating: _rating,
          comment: _feedbackController.text.trim(),
          traits: _selectedTags,
        );
      } catch (e) {
        if (!mounted) return;
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
        return;
      }
      
      if (!mounted) return;
      cubit.reset();
      context.go(RouteNames.customerHome);
    }
  }

  String _getSentimentText() {
    switch (_rating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Great!';
      case 5:
        return 'Excellent! ⭐';
      default:
        return 'Tap a star to rate';
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = context.read<BookingFlowCubit>().state.booking;
    final workerName = booking?.workerName ?? 'Worker';
    final serviceTitle = booking?.serviceTitle ?? 'Service';

    return PopScope(
      canPop: false,
      child: AppScaffold(
        title: 'Rate Service',
        showBack: false,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Worker header
              CircleAvatar(
                radius: 32,
                backgroundColor: const Color(0xFFEFF4FF),
                backgroundImage: booking?.workerAvatar != null
                    ? NetworkImage(booking!.workerAvatar!)
                    : null,
                child: booking?.workerAvatar == null
                    ? Text(
                        workerName.isNotEmpty ? workerName[0] : 'W',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2563EB),
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 16),
              Text(
                workerName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                serviceTitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),
              
              // Interactive 5-star row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final star = index + 1;
                  return GestureDetector(
                    onTap: () => setState(() => _rating = star),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        star <= _rating ? Icons.star : Icons.star_border,
                        size: 44,
                        color: star <= _rating 
                            ? const Color(0xFFF59E0B) 
                            : const Color(0xFFC3C6D7),
                      ).animate(target: star <= _rating ? 1 : 0).scale(
                            begin: const Offset(1, 1),
                            end: const Offset(1.2, 1.2),
                            duration: 200.ms,
                            curve: Curves.easeOut,
                          ).then().scale(
                            begin: const Offset(1.2, 1.2),
                            end: const Offset(1, 1),
                            duration: 200.ms,
                          ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              Text(
                _getSentimentText(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _rating > 0 ? const Color(0xFF0B1C30) : Colors.grey,
                ),
              ),
              const SizedBox(height: 32),
              
              // Multi-select tag chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: _availableTags.map((tag) {
                  final isSelected = _selectedTags.contains(tag);
                  return FilterChip(
                    label: Text(tag),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedTags.add(tag);
                        } else {
                          _selectedTags.remove(tag);
                        }
                      });
                    },
                    selectedColor: const Color(0xFFEFF4FF),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFC3C6D7),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              
              // Comment box
              TextField(
                controller: _feedbackController,
                maxLines: 4,
                minLines: 3,
                decoration: InputDecoration(
                  hintText: 'Tell us about your experience...',
                  hintStyle: const TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFC3C6D7)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFC3C6D7)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF2563EB)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Optional tip row (visual only)
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Add a tip for excellent service? (Optional)',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                children: ['₹50', '₹100', '₹200', 'Custom'].map((tip) {
                  return Chip(
                    label: Text(tip),
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFFC3C6D7)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 40),
              
              PrimaryButton(
                label: 'Submit Review',
                loading: _submitting,
                onPressed: (_submitting || _rating == 0) ? null : _submit,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
