import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/router/route_names.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/theme_x.dart';
import '../../../../../app/theme/app_spacing.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/constants/map_constants.dart';
import '../../../../../core/widgets/core_widgets.dart';
import '../../../../../core/widgets/fixly_map_view.dart';
import '../../../../../shared/widgets/category_chip.dart';
import '../../cubit/worker_onboarding_cubit.dart';
import 'worker_onboarding_layout.dart';

class WorkerWorkProfilePage extends StatefulWidget {
  const WorkerWorkProfilePage({super.key});

  @override
  State<WorkerWorkProfilePage> createState() => _WorkerWorkProfilePageState();
}

class _WorkerWorkProfilePageState extends State<WorkerWorkProfilePage> {
  final _othersController = TextEditingController();
  final _othersFocus = FocusNode();
  var _othersOpen = false;

  static final _categoryIds =
      ServiceCategories.all.map((c) => c.id).toSet();

  @override
  void dispose() {
    _othersController.dispose();
    _othersFocus.dispose();
    super.dispose();
  }

  void _commitTypedSkills({required bool keepRemainder}) {
    final cubit = context.read<WorkerOnboardingCubit>();
    final text = _othersController.text;

    if (keepRemainder) {
      if (!text.contains(',')) return;
      final parts = text.split(',');
      final leftover = parts.removeLast();
      for (final part in parts) {
        cubit.addCustomSkill(part);
      }
      _othersController.value = TextEditingValue(
        text: leftover,
        selection: TextSelection.collapsed(offset: leftover.length),
      );
      return;
    }

    for (final part in text.split(',')) {
      cubit.addCustomSkill(part);
    }
    _othersController.clear();
  }

  void _onOthersChanged(String value) {
    if (!value.contains(',')) return;
    _commitTypedSkills(keepRemainder: true);
  }

  void _continue() {
    _commitTypedSkills(keepRemainder: false);
    final cubit = context.read<WorkerOnboardingCubit>();
    final error = cubit.validateStep(2);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    cubit.setStep(2);
    context.push(RouteNames.workerOnboardingPayout);
  }

  List<String> _customSkills(List<String> skills) =>
      skills.where((s) => !_categoryIds.contains(s)).toList();

  @override
  Widget build(BuildContext context) {
    final locale = context.l10n.locale;
    final cubit = context.read<WorkerOnboardingCubit>();
    final l10n = context.l10n;

    return BlocBuilder<WorkerOnboardingCubit, WorkerOnboardingState>(
      builder: (context, state) {
        final radius = state.formData.serviceRadiusKm;
        final customSkills = _customSkills(state.formData.skills);

        return WorkerOnboardingLayout(
          step: 2,
          title: l10n.workProfile,
          onContinue: _continue,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Certificate, skills, and how far you travel.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.xl),
              OnboardingSection(
                title: l10n.skillCertificate,
                child: AppCard(
                  child: Column(
                    children: [
                      Icon(
                        state.formData.certificateUploaded
                            ? Icons.task_outlined
                            : Icons.upload_file_outlined,
                        size: 48,
                        color: state.formData.certificateUploaded
                            ? AppColors.success
                            : AppColors.primary,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        state.formData.certificateUploaded
                            ? 'certificate.pdf uploaded'
                            : 'PDF or JPG up to 5 MB',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      SecondaryButton(
                        label: state.formData.certificateUploaded
                            ? 'Replace file'
                            : 'Upload certificate',
                        onPressed: () {
                          cubit.updateCertificateUploaded(true);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Certificate uploaded (mock)'),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              OnboardingSection(
                title: l10n.selectSkills,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose all categories you can serve. Select at least one.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final category in ServiceCategories.all)
                          CategoryChip(
                            label: category.nameFor(locale),
                            icon: category.icon,
                            selected:
                                state.formData.skills.contains(category.id),
                            onTap: () => cubit.toggleSkill(category.id),
                          ),
                        CategoryChip(
                          label: l10n.otherSkills,
                          icon: Icons.add_rounded,
                          selected: _othersOpen || customSkills.isNotEmpty,
                          onTap: () {
                            setState(() => _othersOpen = !_othersOpen);
                            if (_othersOpen) {
                              _othersFocus.requestFocus();
                            }
                          },
                        ),
                      ],
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeInOut,
                      alignment: Alignment.topCenter,
                      child: _othersOpen
                          ? Padding(
                              padding: const EdgeInsets.only(top: AppSpacing.md),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppTextField(
                                    controller: _othersController,
                                    focusNode: _othersFocus,
                                    label: l10n.otherSkills,
                                    hint: 'painting, cooking, gardener',
                                    textInputAction: TextInputAction.done,
                                    onChanged: _onOthersChanged,
                                    onSubmitted: (_) =>
                                        _commitTypedSkills(keepRemainder: false),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    l10n.otherSkillsHint,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: context.muted,
                                        ),
                                  ),
                                ],
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                    if (customSkills.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final skill in customSkills)
                            InputChip(
                              label: Text(skill),
                              selected: true,
                              selectedColor:
                                  AppColors.primary.withValues(alpha: 0.12),
                              checkmarkColor: AppColors.primary,
                              deleteIconColor: AppColors.primary,
                              onDeleted: () => cubit.removeSkill(skill),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              OnboardingSection(
                title: l10n.serviceArea,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.serviceAreaHint,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    FixlyMapView(
                      height: 220,
                      borderRadius: BorderRadius.circular(16),
                      center: MapConstants.noidaSector12,
                      zoom: MapConstants.serviceAreaZoom,
                      serviceRadiusKm: radius,
                      showDestinationPin: true,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Center(
                      child: Text(
                        '${radius.toStringAsFixed(0)} km',
                        style:
                            Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  color: AppColors.primary,
                                ),
                      ),
                    ),
                    Slider(
                      value: radius,
                      min: 1,
                      max: 25,
                      divisions: 24,
                      label: '${radius.toStringAsFixed(0)} km',
                      onChanged: cubit.updateServiceRadius,
                    ),
                    Text(
                      l10n.largerRadiusHint,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: context.muted,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
