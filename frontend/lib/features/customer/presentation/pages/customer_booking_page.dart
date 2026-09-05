import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/location/app_location.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../../shared/models/models.dart';
import '../../../home/data/home_api_repository.dart';
import '../cubit/booking_flow_cubit.dart';

class CustomerBookingPage extends StatefulWidget {
  const CustomerBookingPage({
    super.key,
    this.workerId,
    this.serviceId,
    this.categoryId,
  });

  final String? workerId;
  final String? serviceId;
  final String? categoryId;

  @override
  State<CustomerBookingPage> createState() => _CustomerBookingPageState();
}

class _CustomerBookingPageState extends State<CustomerBookingPage> {
  static const _maxMedia = 5;

  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _picker = ImagePicker();
  final _photos = <XFile>[];
  final _videos = <XFile>[];
  bool _pickingMedia = false;
  bool _resolvingService = false;
  List<ServiceItem> _services = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadServices());
  }

  Future<void> _loadServices() async {
    final cubit = context.read<BookingFlowCubit>();
    final requestedServiceId = widget.serviceId?.trim();
    final category = widget.categoryId?.toLowerCase().trim();
    setState(() => _resolvingService = true);
    try {
      final services = await HomeApiRepository().fetchAllServices();
      if (!mounted) return;
      setState(() => _services = services);
      if (cubit.state.service != null) return;
      ServiceItem? service;
      if (requestedServiceId != null && requestedServiceId.isNotEmpty) {
        for (final item in services) {
          if (item.id == requestedServiceId) {
            service = item;
            break;
          }
        }
      }
      service ??= category == null || category.isEmpty
          ? null
          : services.cast<ServiceItem?>().firstWhere((item) {
              final id = item!.categoryId.toLowerCase();
              return id == category ||
                  id.contains(category) ||
                  category.contains(id) ||
                  (category.startsWith('plum') && id.startsWith('plum'));
            }, orElse: () => null);
      if (service != null) cubit.selectService(service);
    } finally {
      if (mounted) setState(() => _resolvingService = false);
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickPhotos({ImageSource source = ImageSource.gallery}) async {
    final remaining = _maxMedia - _photos.length - _videos.length;
    if (remaining <= 0) return;
    setState(() => _pickingMedia = true);
    try {
      final List<XFile> picked;
      if (source == ImageSource.gallery) {
        picked = await _picker.pickMultiImage(imageQuality: 85);
      } else {
        final image = await _picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 85,
        );
        picked = image == null ? const [] : [image];
      }
      if (!mounted) return;
      setState(() => _photos.addAll(picked.take(remaining)));
    } finally {
      if (mounted) setState(() => _pickingMedia = false);
    }
  }

  Future<void> _pickVideo({ImageSource source = ImageSource.gallery}) async {
    if (_photos.length + _videos.length >= _maxMedia) return;
    setState(() => _pickingMedia = true);
    try {
      final picked = await _picker.pickVideo(source: source);
      if (!mounted || picked == null) return;
      setState(() => _videos.add(picked));
    } finally {
      if (mounted) setState(() => _pickingMedia = false);
    }
  }

  Future<void> _chooseMediaType() async {
    if (_photos.length + _videos.length >= _maxMedia) return;
    final type = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose photos'),
              onTap: () => Navigator.pop(context, 'photo'),
            ),
            ListTile(
              leading: const Icon(Icons.video_library_outlined),
              title: const Text('Choose a video'),
              onTap: () => Navigator.pop(context, 'video'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || type == null) return;
    final source = await _chooseMediaSource();
    if (!mounted || source == null) return;
    if (type == 'photo') await _pickPhotos(source: source);
    if (type == 'video') await _pickVideo(source: source);
  }

  Future<ImageSource?> _chooseMediaSource() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Use camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
  }

  void _removePhoto(int index) => setState(() => _photos.removeAt(index));
  void _removeVideo(int index) => setState(() => _videos.removeAt(index));

  Future<void> _continue() async {
    if (!_formKey.currentState!.validate()) return;
    final bookingCubit = context.read<BookingFlowCubit>();
    await bookingCubit.submitBookingDetails(
      address: AppLocation.instance.addressLabel?.trim() ?? '',
      problemDescription: _descriptionController.text.trim(),
      workerId: widget.workerId,
      photoPaths: _photos.map((file) => file.path).toList(),
      videoPaths: _videos.map((file) => file.path).toList(),
    );
    if (!mounted) return;
    if (bookingCubit.state.errorMessage == null) {
      context.push(RouteNames.customerBookingConfirmation);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(bookingCubit.state.errorMessage!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = context.read<BookingFlowCubit>().state.service;
    final selectedService = service;
    final address = AppLocation.instance.addressLabel?.trim() ?? '';

    return AppScaffold(
      title: context.l10n.bookService,
      body: Form(
        key: _formKey,
        child: ListView(
          children: [
            if (service != null)
              StepProgressHeader(
                currentStep: 1,
                totalSteps: 5,
                title: service.title,
              ),
            DropdownButtonFormField<ServiceItem>(
              initialValue: _services.contains(selectedService)
                  ? selectedService
                  : null,
              decoration: const InputDecoration(
                labelText: 'Service',
                prefixIcon: Icon(Icons.home_repair_service_outlined),
              ),
              items: _services
                  .map(
                    (item) => DropdownMenuItem<ServiceItem>(
                      value: item,
                      child: Text(item.title, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: _resolvingService
                  ? null
                  : (item) {
                      if (item != null) {
                        context.read<BookingFlowCubit>().selectService(item);
                        setState(() {});
                      }
                    },
              validator: (item) =>
                  item == null ? 'Please select a service' : null,
            ),
            const SizedBox(height: 20),
            Text(
              'Describe the issue',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              minLines: 5,
              maxLines: 7,
              textInputAction: TextInputAction.newline,
              decoration: const InputDecoration(
                hintText: 'Tell us what needs to be fixed...',
                alignLabelWithHint: true,
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Please describe the issue'
                  : null,
            ),
            const SizedBox(height: 24),
            _MediaSection(
              title: 'Photos & videos',
              count: _photos.length + _videos.length,
              limit: _maxMedia,
              icon: Icons.perm_media_outlined,
              onAdd: _pickingMedia ? null : _chooseMediaType,
              children: [
                for (var i = 0; i < _videos.length; i++)
                  _MediaPreview(
                    path: _videos[i].path,
                    isVideo: true,
                    onRemove: () => _removeVideo(i),
                  ),
                for (var i = 0; i < _photos.length; i++)
                  _MediaPreview(
                    path: _photos[i].path,
                    onRemove: () => _removePhoto(i),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Service address',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            AppCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      address.isEmpty
                          ? 'Current location unavailable'
                          : address,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            BlocBuilder<BookingFlowCubit, BookingFlowState>(
              builder: (context, state) => PrimaryButton(
                label: 'Continue to book',
                loading: state.isLoading,
                onPressed: _resolvingService ? null : _continue,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _MediaSection extends StatelessWidget {
  const _MediaSection({
    required this.title,
    required this.count,
    required this.limit,
    required this.icon,
    required this.onAdd,
    required this.children,
  });

  final String title;
  final int count;
  final int limit;
  final IconData icon;
  final VoidCallback? onAdd;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              '$title ($count/$limit)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (children.isNotEmpty)
          Wrap(spacing: 10, runSpacing: 10, children: children),
        if (onAdd != null && count < limit) ...[
          if (children.isNotEmpty) const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: Text(count == 0 ? 'Upload $title' : 'Upload more'),
          ),
        ],
      ],
    );
  }
}

class _MediaPreview extends StatelessWidget {
  const _MediaPreview({
    required this.path,
    required this.onRemove,
    this.isVideo = false,
  });

  final String path;
  final VoidCallback onRemove;
  final bool isVideo;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 92,
          height: 92,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
          ),
          clipBehavior: Clip.antiAlias,
          child: isVideo
              ? const Center(
                  child: Icon(
                    Icons.play_circle_fill,
                    size: 40,
                    color: AppColors.primary,
                  ),
                )
              : Image.file(File(path), fit: BoxFit.cover),
        ),
        Positioned(
          top: 3,
          right: 3,
          child: IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.close, size: 16),
            style: IconButton.styleFrom(
              backgroundColor: Colors.black54,
              foregroundColor: Colors.white,
              minimumSize: const Size(28, 28),
              padding: EdgeInsets.zero,
            ),
          ),
        ),
      ],
    );
  }
}
