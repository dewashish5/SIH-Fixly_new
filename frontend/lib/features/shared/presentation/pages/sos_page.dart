import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme/app_radius.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../../core/utils/toast_utils.dart';
import '../../../auth/presentation/cubit/app_session_cubit.dart';
import '../../../worker/presentation/widgets/worker_sos_sheet.dart';
import '../cubit/sos_cubit.dart';

class SosPage extends StatelessWidget {
  const SosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SosCubit()..loadContacts(),
      child: const _SosPageView(),
    );
  }
}

class _SosPageView extends StatelessWidget {
  const _SosPageView();

  Future<void> _dialNumber(String number) async {
    final url = Uri.parse('tel:$number');
    if (!await launchUrl(url)) {
      debugPrint('Could not launch $url');
    }
  }

  void _showBookingSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => BlocProvider.value(
        value: context.read<SosCubit>(),
        child: const _EmergencyBookingSheet(),
      ),
    );
  }

  IconData _getIconForContact(String type) {
    switch (type) {
      case 'police':
        return Icons.local_police;
      case 'ambulance':
        return Icons.medical_services;
      case 'fire':
        return Icons.local_fire_department;
      case 'women':
        return Icons.pregnant_woman;
      default:
        return Icons.phone;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Emergency SOS',
      body: BlocConsumer<SosCubit, SosState>(
        listener: (context, state) {
          if (state.error.isNotEmpty) {
            ToastUtils.showToast(context: context, message: state.error);
          }
        },
        builder: (context, state) {
          if (state.isLoadingContacts) {
            return const Center(child: CircularProgressIndicator(color: Colors.red));
          }

          if (state.isBroadcasting) {
            return _buildPulsingAnimation(context);
          }

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              const Text(
                'Emergency Contacts',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: state.contacts.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemBuilder: (context, index) {
                  final contact = state.contacts[index];
                  return _buildContactCard(
                    context,
                    contact['name'] ?? '',
                    contact['number'] ?? '',
                    _getIconForContact(contact['icon'] ?? ''),
                  );
                },
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(Icons.warning_amber_rounded, size: 48, color: Colors.white),
                    const SizedBox(height: 12),
                    Builder(
                      builder: (ctx) {
                        final isWorker = ctx.watch<AppSessionCubit>().state.role == 'worker';
                        return Column(
                          children: [
                            Text(
                              isWorker ? 'Worker Safety Support' : 'Need Immediate Help?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isWorker
                                  ? 'Connect directly with the Federation Safety Response Cell or National Emergency 112.'
                                  : 'Broadcast an emergency booking to all nearby workers. They will be alerted instantly.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: isWorker
                                  ? () => WorkerSosSheet.show(context)
                                  : () => _showBookingSheet(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.red,
                                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppRadius.full),
                                ),
                              ),
                              child: Text(
                                isWorker ? 'Open Worker Safety Helplines' : 'Create Emergency Booking',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              )
            ],
          );
        },
      ),
    );
  }

  Widget _buildContactCard(BuildContext context, String title, String number, IconData icon) {
    return AppCard(
      child: InkWell(
        onTap: () => _dialNumber(number),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 36, color: Colors.red),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                number,
                style: TextStyle(color: Theme.of(context).hintColor, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPulsingAnimation(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 32),
          const Text(
            'Broadcasting Emergency...',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Alerting all nearby professionals',
            style: TextStyle(color: Theme.of(context).hintColor),
          ),
        ],
      ),
    );
  }
}

class _EmergencyBookingSheet extends StatefulWidget {
  const _EmergencyBookingSheet();

  @override
  State<_EmergencyBookingSheet> createState() => _EmergencyBookingSheetState();
}

class _EmergencyBookingSheetState extends State<_EmergencyBookingSheet> {
  String _selectedCategory = 'Plumbing';
  final _descController = TextEditingController();
  final _priceController = TextEditingController();

  final List<String> _categories = ['Plumbing', 'Electrical', 'Carpentry', 'Other'];

  void _submit() {
    final desc = _descController.text.trim();
    final price = double.tryParse(_priceController.text) ?? 500.0;
    if (desc.isEmpty) {
      ToastUtils.showToast(context: context, message: 'Please describe the issue');
      return;
    }
    
    context.read<SosCubit>().broadcastEmergencyBooking(_selectedCategory, desc, price).then((_) {
      if (mounted) {
        Navigator.pop(context);
        ToastUtils.showToast(context: context, message: 'Emergency broadcast successful!');
        context.pop(); // Close SOS page
      }
    });
  }

  @override
  void dispose() {
    _descController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Emergency Booking',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (v) => setState(() => _selectedCategory = v!),
            decoration: const InputDecoration(labelText: 'Category'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descController,
            decoration: const InputDecoration(
              labelText: 'Describe the emergency',
              hintText: 'Water pipe burst, short circuit...',
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _priceController,
            decoration: const InputDecoration(
              labelText: 'Offer Price (₹)',
              hintText: 'e.g. 1000',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Broadcast Now',
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
