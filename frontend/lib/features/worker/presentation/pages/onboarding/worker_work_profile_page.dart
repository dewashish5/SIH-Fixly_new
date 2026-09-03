import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/router/route_names.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/theme_x.dart';
import '../../../../../app/theme/app_spacing.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/constants/map_constants.dart';
import '../../../../../core/location/app_location.dart';
import '../../../../../core/location/location_service.dart';
import '../../../../../core/network/api_exception.dart';
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
  late final TextEditingController _experienceController;
  late final TextEditingController _bioController;
  final _rateControllers = <String, TextEditingController>{};
  var _othersOpen = false;
  var _refreshingLocation = false;

  static final _categoryIds =
      ServiceCategories.all.map((c) => c.id).toSet();

  @override
  void initState() {
    super.initState();
    final data = context.read<WorkerOnboardingCubit>().state.formData;
    _experienceController = TextEditingController(
      text: data.experienceYears > 0 ? '${data.experienceYears}' : '',
    );
    _bioController = TextEditingController(text: data.bio);
    _syncRateControllers(data.skills, data.categoryRates);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureLocation();
    });
  }

  @override
  void dispose() {
    _othersController.dispose();
    _othersFocus.dispose();
    _experienceController.dispose();
    _bioController.dispose();
    for (final c in _rateControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _syncRateControllers(List<String> skills, Map<String, int> rates) {
    final stale = _rateControllers.keys
        .where((id) => !skills.contains(id))
        .toList(growable: false);
    // Never dispose during build — schedule after frame.
    if (stale.isNotEmpty) {
      final orphaned = <TextEditingController>[
        for (final id in stale) _rateControllers.remove(id)!,
      ];
      WidgetsBinding.instance.addPostFrameCallback((_) {
        for (final c in orphaned) {
          c.dispose();
        }
      });
    }
    for (final skill in skills) {
      final existing = _rateControllers[skill];
      final text = (rates[skill] ?? 0) > 0 ? '${rates[skill]}' : '';
      if (existing == null) {
        _rateControllers[skill] = TextEditingController(text: text);
      } else if (existing.text.isEmpty && text.isNotEmpty) {
        existing.text = text;
      }
    }
  }

  String _skillLabel(String skillId, String locale) {
    for (final c in ServiceCategories.all) {
      if (c.id == skillId) return c.nameFor(locale);
    }
    return skillId;
  }

  Future<void> _ensureLocation() async {
    if (!mounted) return;
    setState(() => _refreshingLocation = true);
    await LocationService.instance.refreshCurrentPosition();
    if (!mounted) return;
    setState(() => _refreshingLocation = false);
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

  Future<void> _pickCertificate() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (file == null || !mounted) return;
    final path = file.path;
    if (path == null || path.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not read that file. Try again.')),
      );
      return;
    }
    final bytes = file.lengthSync() ?? await file.length();
    if (bytes > 5 * 1024 * 1024) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File must be 5 MB or smaller.')),
      );
      return;
    }
    if (!mounted) return;
    context.read<WorkerOnboardingCubit>().updateCertificate(
          path: path,
          fileName: file.name,
        );
  }

  void _continue() {
    _commitTypedSkills(keepRemainder: false);
    final cubit = context.read<WorkerOnboardingCubit>();
    final years = int.tryParse(_experienceController.text.trim()) ?? 0;
    cubit
      ..updateExperienceYears(years)
      ..updateBio(_bioController.text.trim());
    for (final entry in _rateControllers.entries) {
      final rate = int.tryParse(entry.value.text.trim()) ?? 0;
      cubit.updateCategoryRate(entry.key, rate);
    }
    final error = cubit.validateStep(2);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ApiException.userFacingMessage(error)),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }
    cubit.setStep(2);
    context.push(RouteNames.workerOnboardingPayout);
  }

  List<String> _customSkills(List<String> skills) =>
      skills.where((s) => !_categoryIds.contains(s)).toList();

  MapCoordinate? _userMapCenter(BuildContext context) {
    final loc = AppLocation.instance;
    if (!loc.hasFix) return null;
    return MapCoordinate(
      lat: loc.lat!,
      lng: loc.lng!,
      label: context.l10n.youAreHere,
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.l10n.locale;
    final cubit = context.read<WorkerOnboardingCubit>();
    final l10n = context.l10n;

    return BlocBuilder<WorkerOnboardingCubit, WorkerOnboardingState>(
      builder: (context, state) {
        final customSkills = _customSkills(state.formData.skills);
        final mapCenter = _userMapCenter(context);
        final address = AppLocation.instance.addressLabel?.trim();
        _syncRateControllers(
          state.formData.skills,
          state.formData.categoryRates,
        );

        return WorkerOnboardingLayout(
          step: 2,
          title: l10n.workProfile,
          onContinue: _continue,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Certificate, skills, rates, and your current location.',
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
                            ? (state.formData.certificateFileName ??
                                'Certificate selected')
                            : 'PDF or JPG up to 5 MB',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      SecondaryButton(
                        label: state.formData.certificateUploaded
                            ? 'Replace file'
                            : 'Upload certificate',
                        onPressed: _pickCertificate,
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
                              padding:
                                  const EdgeInsets.only(top: AppSpacing.md),
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
                                    onSubmitted: (_) => _commitTypedSkills(
                                      keepRemainder: false,
                                    ),
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
                title: l10n.yourRates,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.yourRatesHint,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      controller: _experienceController,
                      label: l10n.experienceYears,
                      hint: '4',
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(2),
                      ],
                      onChanged: (v) {
                        cubit.updateExperienceYears(int.tryParse(v) ?? 0);
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      controller: _bioController,
                      label: l10n.workerBio,
                      hint: l10n.workerBioHint,
                      textCapitalization: TextCapitalization.sentences,
                      onChanged: cubit.updateBio,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (state.formData.skills.isEmpty)
                      Text(
                        l10n.selectSkillsFirstForRates,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: context.muted,
                            ),
                      )
                    else
                      AppCard(
                        child: Column(
                          children: [
                            for (var i = 0;
                                i < state.formData.skills.length;
                                i++) ...[
                              if (i > 0) const SizedBox(height: AppSpacing.md),
                              _CategoryRateRow(
                                label: _skillLabel(
                                  state.formData.skills[i],
                                  locale,
                                ),
                                controller:
                                    _rateControllers[state.formData.skills[i]]!,
                                rateLabel: l10n.hourlyRateLabel,
                                onChanged: (value) {
                                  cubit.updateCategoryRate(
                                    state.formData.skills[i],
                                    int.tryParse(value) ?? 0,
                                  );
                                },
                              )
                                  .animate()
                                  .fadeIn(
                                    delay: (40 * i).ms,
                                    duration: 260.ms,
                                  )
                                  .slideY(
                                    begin: 0.04,
                                    delay: (40 * i).ms,
                                    duration: 260.ms,
                                    curve: Curves.easeOutCubic,
                                  ),
                            ],
                          ],
                        ),
                      ),
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
                    if (address != null && address.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: context.scheme.primaryContainer
                              .withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                context.scheme.primary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.place_outlined,
                              size: 18,
                              color: context.scheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                address,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    FixlyMapView(
                      height: 280,
                      borderRadius: BorderRadius.circular(16),
                      center: mapCenter,
                      zoom: MapConstants.defaultZoom,
                      showDestinationPin: true,
                      claimGestures: true,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed:
                            _refreshingLocation ? null : _ensureLocation,
                        icon: _refreshingLocation
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.my_location_outlined, size: 18),
                        label: Text(l10n.refreshLocation),
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

class _CategoryRateRow extends StatelessWidget {
  const _CategoryRateRow({
    required this.label,
    required this.controller,
    required this.rateLabel,
    required this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final String rateLabel;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                rateLabel,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.muted,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 4,
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            onChanged: onChanged,
            decoration: const InputDecoration(
              prefixText: '₹ ',
              hintText: '350',
              counterText: '',
            ),
          ),
        ),
      ],
    );
  }
}
