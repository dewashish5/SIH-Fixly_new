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
import '../../../../../core/utils/toast_utils.dart';
import '../../../../shared/data/service_scope_data.dart';

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
  var _updatingAddress = false;
  int _scopeSelectedSkillIndex = 0;
  final _customIncludedController = TextEditingController();
  final _customExcludedController = TextEditingController();

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

    // Default to first registered federation if not chosen
    if (data.federationId == null && ServiceScopeData.federations.isNotEmpty) {
      final defaultFed = ServiceScopeData.federations.first;
      context.read<WorkerOnboardingCubit>().updateFederation(
            id: defaultFed.id,
            name: defaultFed.name,
          );
    }

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
    _customIncludedController.dispose();
    _customExcludedController.dispose();
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

  Future<void> _onMapLocationMoved(MapCoordinate coord) async {
    if (!mounted) return;
    setState(() => _updatingAddress = true);
    await LocationService.instance.updatePosition(coord.lat, coord.lng);
    if (!mounted) return;
    setState(() => _updatingAddress = false);
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
      ToastUtils.showToast(context: context, message: 'Could not read that file. Try again.');
      return;
    }
    final bytes = file.lengthSync() ?? await file.length();
    if (bytes > 5 * 1024 * 1024) {
      if (!mounted) return;
      ToastUtils.showToast(context: context, message: 'File must be 5 MB or smaller.');
      return;
    }
    if (!mounted) return;
    context.read<WorkerOnboardingCubit>().updateCertificate(
          path: path,
          fileName: file.name,
        );
  }

  Future<void> _continue() async {
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
    // Ensure scope tasks are initialized for all skills
    for (final skill in cubit.state.formData.skills) {
      final scope = ServiceScopeData.getScopeForCategory(skill);
      final inc = cubit.state.formData.includedTasks[skill] ?? scope.included;
      final exc = cubit.state.formData.excludedTasks[skill] ?? scope.excluded;
      cubit.setScopeTasksForCategory(skill, included: inc, excluded: exc);
    }
    final error = cubit.validateStep(2);
    if (error != null) {
      ToastUtils.showError(context: context, message: ApiException.userFacingMessage(error));
      return;
    }
    
    final success = await cubit.submitWorkProfile();
    if (!success) return;

    cubit.setStep(2);
    if (mounted) context.push(RouteNames.workerOnboardingPayout);
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
              if (state.errorMessage == 'NAME_MISMATCH')
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.error),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: AppColors.error),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Name mismatch between ID and Certificate.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.error,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
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
              _buildFederationSection(context, state, cubit),
              _buildScopeOfWorkSection(context, state, cubit, locale),
              OnboardingSection(
                title: l10n.serviceArea,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.serviceAreaHint,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
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
                          if (_updatingAddress)
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else
                            Icon(
                              Icons.place_outlined,
                              size: 18,
                              color: context.scheme.primary,
                            ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _updatingAddress
                                  ? 'Updating address…'
                                  : (address != null && address.isNotEmpty
                                      ? address
                                      : 'Move map or tap refresh to detect location'),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    FixlyMapView(
                      height: 280,
                      borderRadius: BorderRadius.circular(16),
                      center: mapCenter,
                      zoom: MapConstants.pickerZoom,
                      showDestinationPin: true,
                      claimGestures: true,
                      showZoomControls: true,
                      showRecenterButton: true,
                      onLocationChanged: _onMapLocationMoved,
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

  Widget _buildFederationSection(
    BuildContext context,
    WorkerOnboardingState state,
    WorkerOnboardingCubit cubit,
  ) {
    final currentFedName = state.formData.federationName ??
        (ServiceScopeData.federations.isNotEmpty
            ? ServiceScopeData.federations.first.name
            : 'National Labour Cooperative Federation (NLCF)');

    return OnboardingSection(
      title: 'Cooperative Federation',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Affiliate with a registered labour cooperative federation for fair wage protection and verified cooperative identity.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF10B981).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.groups_rounded,
                    color: Color(0xFF10B981),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SELECTED FEDERATION',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF10B981),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        currentFedName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                OutlinedButton(
                  onPressed: () => _showFederationPicker(context, state, cubit),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text('Change'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFederationPicker(
    BuildContext context,
    WorkerOnboardingState state,
    WorkerOnboardingCubit cubit,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'Select Cooperative Federation',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              const Text(
                'Choose your affiliated labour cooperative federation:',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  itemCount: ServiceScopeData.federations.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final fed = ServiceScopeData.federations[index];
                    final isSelected = state.formData.federationId == fed.id ||
                        (state.formData.federationId == null && index == 0);

                    return InkWell(
                      onTap: () {
                        cubit.updateFederation(id: fed.id, name: fed.name);
                        Navigator.of(ctx).pop();
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF10B981).withValues(alpha: 0.1)
                              : Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF10B981)
                                : Colors.grey.withValues(alpha: 0.2),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                              color: isSelected ? const Color(0xFF10B981) : Colors.grey,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    fed.name,
                                    style: TextStyle(
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${fed.state} • Reg: ${fed.regNo}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isSelected ? const Color(0xFF10B981) : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScopeOfWorkSection(
    BuildContext context,
    WorkerOnboardingState state,
    WorkerOnboardingCubit cubit,
    String locale,
  ) {
    if (state.formData.skills.isEmpty) {
      return const SizedBox.shrink();
    }

    if (_scopeSelectedSkillIndex >= state.formData.skills.length) {
      _scopeSelectedSkillIndex = 0;
    }

    final activeSkill = state.formData.skills[_scopeSelectedSkillIndex];
    final defaultScope = ServiceScopeData.getScopeForCategory(activeSkill);

    final currentIncluded = state.formData.includedTasks[activeSkill] ?? defaultScope.included;
    final currentExcluded = state.formData.excludedTasks[activeSkill] ?? defaultScope.excluded;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return OnboardingSection(
      title: 'Scope of Work & Deliverables',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select what you will do and what you will NOT do for your skills. Customers will see these transparent boundaries before booking.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),

          // Skill selector tabs if multiple skills
          if (state.formData.skills.length > 1) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(state.formData.skills.length, (index) {
                  final skill = state.formData.skills[index];
                  final isSelected = index == _scopeSelectedSkillIndex;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(_skillLabel(skill, locale)),
                      selected: isSelected,
                      onSelected: (val) {
                        if (val) setState(() => _scopeSelectedSkillIndex = index);
                      },
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // Deliverables Card matching reference design
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section 1: The expert is trained to (What is included)
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, size: 12, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'The expert is trained to (Included)',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Included tasks list with check toggle
                for (final task in defaultScope.included)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: InkWell(
                      onTap: () => cubit.toggleIncludedTask(activeSkill, task),
                      borderRadius: BorderRadius.circular(8),
                      child: Row(
                        children: [
                          Icon(
                            currentIncluded.contains(task)
                                ? Icons.check_box_rounded
                                : Icons.check_box_outline_blank_rounded,
                            color: currentIncluded.contains(task)
                                ? const Color(0xFF10B981)
                                : Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              task,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: currentIncluded.contains(task)
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: currentIncluded.contains(task)
                                    ? (isDark ? Colors.white : const Color(0xFF1E293B))
                                    : Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Custom included task field
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _customIncludedController,
                          style: const TextStyle(fontSize: 12),
                          decoration: InputDecoration(
                            hintText: 'Add another task you will do...',
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        onPressed: () {
                          final text = _customIncludedController.text.trim();
                          if (text.isNotEmpty) {
                            cubit.toggleIncludedTask(activeSkill, text);
                            _customIncludedController.clear();
                          }
                        },
                        icon: const Icon(Icons.add, size: 16),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                const Divider(height: 1),
                const SizedBox(height: 16),

                // Section 2: What is not included (Boundaries)
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, size: 12, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'What is not included (Your Boundaries)',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Excluded tasks list with check toggle
                for (final task in defaultScope.excluded)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: InkWell(
                      onTap: () => cubit.toggleExcludedTask(activeSkill, task),
                      borderRadius: BorderRadius.circular(8),
                      child: Row(
                        children: [
                          Icon(
                            currentExcluded.contains(task)
                                ? Icons.check_box_rounded
                                : Icons.check_box_outline_blank_rounded,
                            color: currentExcluded.contains(task)
                                ? const Color(0xFFEF4444)
                                : Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              task,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: currentExcluded.contains(task)
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: currentExcluded.contains(task)
                                    ? (isDark ? Colors.white70 : const Color(0xFF475569))
                                    : Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Custom excluded task field
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _customExcludedController,
                          style: const TextStyle(fontSize: 12),
                          decoration: InputDecoration(
                            hintText: 'Add another task you will NOT do...',
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        onPressed: () {
                          final text = _customExcludedController.text.trim();
                          if (text.isNotEmpty) {
                            cubit.toggleExcludedTask(activeSkill, text);
                            _customExcludedController.clear();
                          }
                        },
                        icon: const Icon(Icons.add, size: 16),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Equipment Notice
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          defaultScope.equipmentNotice,
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
