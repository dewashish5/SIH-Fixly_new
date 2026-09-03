import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/theme_x.dart';
import '../../../../../shared/models/models.dart';

/// Cream guidelines card for ID photo tips.
class PhotoGuidelinesCard extends StatelessWidget {
  const PhotoGuidelinesCard({super.key});

  static const _tips = [
    'Ensure all text and your photo are clearly visible.',
    'Avoid glare, shadows, and blurry images.',
    'Place the document on a flat, well-lit surface.',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final bg = isDark
        ? context.scheme.primaryContainer.withValues(alpha: 0.35)
        : const Color(0xFFFDF5F2);
    final accent = isDark ? context.scheme.primary : AppColors.primaryDark;
    final border = isDark
        ? context.scheme.outline.withValues(alpha: 0.4)
        : const Color(0xFFE8DCD6);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 20, color: accent),
              const SizedBox(width: 8),
              Text(
                'Photo Guidelines',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final tip in _tips) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_circle_outline, size: 18, color: accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tip,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: context.ink.withValues(alpha: 0.85),
                          height: 1.35,
                        ),
                  ),
                ),
              ],
            ),
            if (tip != _tips.last) const SizedBox(height: 10),
          ],
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 320.ms, curve: Curves.easeOutCubic)
        .slideY(begin: 0.06, duration: 320.ms, curve: Curves.easeOutCubic);
  }
}

/// Front/back document upload tile with camera or gallery.
class DocumentPhotoSlot extends StatelessWidget {
  const DocumentPhotoSlot({
    required this.label,
    required this.imagePath,
    required this.onPicked,
    super.key,
  });

  final String label;
  final String? imagePath;
  final ValueChanged<String> onPicked;

  bool get _hasImage => imagePath != null && imagePath!.isNotEmpty;

  Future<void> _pick(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Take photo'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from gallery'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (source == null || !context.mounted) return;

    final file = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (file == null || !context.mounted) return;
    onPicked(file.path);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _pick(context),
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          height: 112,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _hasImage ? AppColors.success : context.hairline,
              width: _hasImage ? 1.5 : 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: _hasImage
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(File(imagePath!), fit: BoxFit.cover),
                      Positioned(
                        left: 8,
                        right: 8,
                        bottom: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            label,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(color: Colors.white),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_a_photo_outlined,
                        color: scheme.primary,
                        size: 28,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        label,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: scheme.primary,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Tap to add',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: context.muted,
                            ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    )
        .animate(target: _hasImage ? 1 : 0)
        .scale(
          begin: const Offset(0.98, 0.98),
          end: const Offset(1, 1),
          duration: 220.ms,
          curve: Curves.easeOutCubic,
        );
  }
}

class DocumentPhotoPair extends StatelessWidget {
  const DocumentPhotoPair({
    required this.frontPath,
    required this.backPath,
    required this.onFrontPicked,
    required this.onBackPicked,
    super.key,
  });

  final String? frontPath;
  final String? backPath;
  final ValueChanged<String> onFrontPicked;
  final ValueChanged<String> onBackPicked;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: DocumentPhotoSlot(
            label: 'Front',
            imagePath: frontPath,
            onPicked: onFrontPicked,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DocumentPhotoSlot(
            label: 'Back',
            imagePath: backPath,
            onPicked: onBackPicked,
          ),
        ),
      ],
    );
  }
}

class GenderSelector extends StatelessWidget {
  const GenderSelector({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final WorkerGender? value;
  final ValueChanged<WorkerGender> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: WorkerGender.values.map((g) {
        final selected = value == g;
        return ChoiceChip(
          label: Text(g.label),
          selected: selected,
          onSelected: (_) => onChanged(g),
          selectedColor: context.scheme.primaryContainer,
          labelStyle: TextStyle(
            color: selected
                ? context.scheme.onPrimaryContainer
                : context.scheme.onSurface,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
          side: BorderSide(
            color: selected ? context.scheme.primary : context.hairline,
          ),
          showCheckmark: false,
          materialTapTargetSize: MaterialTapTargetSize.padded,
        );
      }).toList(),
    );
  }
}

