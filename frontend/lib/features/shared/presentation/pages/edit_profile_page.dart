import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/theme_x.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../cubit/profile_cubit.dart';
import '../../../../core/utils/toast_utils.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emergencyNameController;
  late final TextEditingController _emergencyPhoneController;
  late final TextEditingController _emergencyRelationController;

  // Worker specific controllers
  late final TextEditingController _workAddressController;
  late final TextEditingController _rateController;
  late final TextEditingController _experienceController;
  late final TextEditingController _bioController;
  late final TextEditingController _upiController;
  late final TextEditingController _cityController;
  late final TextEditingController _pincodeController;

  String? _selectedCategory;
  String? _gender;
  late Set<String> _skills;
  bool _initializedFromState = false;

  @override
  void initState() {
    super.initState();
    final state = context.read<ProfileCubit>().state;
    _nameController = TextEditingController(text: state.name);
    _phoneController = TextEditingController(text: state.phone);
    _emergencyNameController =
        TextEditingController(text: state.emergencyContactName);
    _emergencyPhoneController =
        TextEditingController(text: state.emergencyContactPhone);
    _emergencyRelationController =
        TextEditingController(text: state.emergencyContactRelation);

    _workAddressController = TextEditingController(text: state.workAddress);
    _rateController = TextEditingController(
      text: state.hourlyRate > 0 ? state.hourlyRate.toStringAsFixed(0) : '',
    );
    _experienceController = TextEditingController(
      text: state.experienceYears > 0 ? state.experienceYears.toString() : '',
    );
    _bioController = TextEditingController(text: state.bio);
    _upiController = TextEditingController(text: state.upiId);
    _cityController = TextEditingController(text: state.homeCity);
    _pincodeController = TextEditingController(text: state.homePincode);
    _selectedCategory = state.category.isNotEmpty ? state.category : null;
    _gender = state.gender.isNotEmpty ? state.gender : null;
    _skills = {
      ...state.skills,
      if (state.category.isNotEmpty) state.category,
    };

    if (state.name.isEmpty) {
      context.read<ProfileCubit>().load();
    } else {
      _initializedFromState = true;
    }
  }

  void _syncFromState(ProfileState state) {
    if (_initializedFromState || state.status == ProfileStatus.loading) return;
    _nameController.text = state.name;
    _phoneController.text = state.phone;
    _emergencyNameController.text = state.emergencyContactName;
    _emergencyPhoneController.text = state.emergencyContactPhone;
    _emergencyRelationController.text = state.emergencyContactRelation;
    _workAddressController.text = state.workAddress;
    _rateController.text =
        state.hourlyRate > 0 ? state.hourlyRate.toStringAsFixed(0) : '';
    _experienceController.text =
        state.experienceYears > 0 ? state.experienceYears.toString() : '';
    _bioController.text = state.bio;
    _upiController.text = state.upiId;
    _cityController.text = state.homeCity;
    _pincodeController.text = state.homePincode;
    if (_selectedCategory == null && state.category.isNotEmpty) {
      _selectedCategory = state.category;
    }
    if (_gender == null && state.gender.isNotEmpty) {
      _gender = state.gender;
    }
    if (_skills.isEmpty && state.skills.isNotEmpty) {
      _skills = state.skills.toSet();
    }
    _initializedFromState = true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _emergencyRelationController.dispose();
    _workAddressController.dispose();
    _rateController.dispose();
    _experienceController.dispose();
    _bioController.dispose();
    _upiController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _save(ProfileState state) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final rateVal = double.tryParse(_rateController.text.trim());
    final expVal = int.tryParse(_experienceController.text.trim());

    try {
      await context.read<ProfileCubit>().updateProfile(
            name: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
            emergencyContactName: _emergencyNameController.text.trim(),
            emergencyContactPhone: _emergencyPhoneController.text.trim(),
            emergencyContactRelation:
                _emergencyRelationController.text.trim(),
            category: _selectedCategory,
            categories: _selectedCategory == null
                ? null
                : [_selectedCategory!, ..._skills],
            skills: _skills.toList(),
            workAddress: _workAddressController.text.trim(),
            hourlyRate: rateVal,
            experienceYears: expVal,
            bio: _bioController.text.trim(),
            upiId: _upiController.text.trim(),
            gender: _gender,
            homeCity: _cityController.text.trim(),
            homePincode: _pincodeController.text.trim(),
          );
      if (mounted) {
        ToastUtils.showToast(context: context, message: context.l10n.profileSaved);
        context.pop();
      }
    } catch (_) {
      if (!mounted) return;
      final message = context.read<ProfileCubit>().state.errorMessage;
      ToastUtils.showError(context: context, message: message ?? 'Could not save profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return BlocConsumer<ProfileCubit, ProfileState>(
      listener: (context, state) {
        _syncFromState(state);
      },
      builder: (context, state) {
        final isWorker = state.isWorker;

        return AppScaffold(
          title: context.l10n.editProfile,
          showBack: true,
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                // Avatar & Role Card
                _ProfileAvatarHeader(
                  name: _nameController.text.isNotEmpty
                      ? _nameController.text
                      : state.name,
                  email: state.email,
                  isWorker: isWorker,
                ),
                const SizedBox(height: AppSpacing.xl),

                // Section 1: Personal Details
                _SectionTitle(
                  icon: Icons.person_outline_rounded,
                  title: 'Personal Details',
                ),
                const SizedBox(height: AppSpacing.sm),
                _FormCard(
                  children: [
                    AppTextField(
                      controller: _nameController,
                      label: 'Full Name',
                      hint: 'Enter your full name',
                      prefixIcon: const Icon(Icons.badge_outlined),
                      validator: (v) =>
                          Validators.requiredField(v, label: 'Name'),
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      hint: '+91 9876543210',
                      keyboardType: TextInputType.phone,
                      prefixIcon: const Icon(Icons.phone_outlined),
                      validator: Validators.phone,
                    ),
                    if (state.email.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Email Address',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: scheme.surfaceContainerHighest
                                  .withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              border: Border.all(
                                color: scheme.outline.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.alternate_email_rounded,
                                  size: 20,
                                  color: context.muted,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    state.email,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: context.muted,
                                        ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.success
                                        .withValues(alpha: 0.12),
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.full),
                                  ),
                                  child: Text(
                                    'Verified',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: AppColors.success,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),

                // Section 2: Worker Specific Trade & Rates
                if (isWorker) ...[
                  _SectionTitle(
                    icon: Icons.handyman_outlined,
                    title: 'Work & Trade Details',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _FormCard(
                    children: [
                      Text(
                        'Primary Trade Category',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: ServiceCategories.all
                                .any((c) => c.id == _selectedCategory)
                            ? _selectedCategory
                            : null,
                        isExpanded: true,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.category_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                        ),
                        hint: const Text('Select your trade'),
                        items: [
                          for (final cat in ServiceCategories.all)
                            DropdownMenuItem(
                              value: cat.id,
                              child: Row(
                                children: [
                                  Icon(cat.icon, size: 18, color: AppColors.primary),
                                  const SizedBox(width: 10),
                                  Text('${cat.nameEn} (${cat.nameHi})'),
                                ],
                              ),
                            ),
                        ],
                        onChanged: (val) {
                          setState(() {
                            _selectedCategory = val;
                            if (val != null) _skills.add(val);
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Skills',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final cat in ServiceCategories.all)
                            FilterChip(
                              label: Text(cat.nameEn),
                              selected: _skills.contains(cat.id),
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _skills.add(cat.id);
                                  } else {
                                    _skills.remove(cat.id);
                                  }
                                });
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: const {
                          'male',
                          'female',
                          'other',
                          'unspecified',
                        }.contains(_gender)
                            ? _gender
                            : null,
                        isExpanded: true,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.wc_outlined),
                          labelText: 'Gender',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'male',
                            child: Text('Male'),
                          ),
                          DropdownMenuItem(
                            value: 'female',
                            child: Text('Female'),
                          ),
                          DropdownMenuItem(
                            value: 'other',
                            child: Text('Other'),
                          ),
                          DropdownMenuItem(
                            value: 'unspecified',
                            child: Text('Prefer not to say'),
                          ),
                        ],
                        onChanged: (val) => setState(() => _gender = val),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              controller: _rateController,
                              label: 'Hourly Rate (₹)',
                              hint: 'e.g. 250',
                              keyboardType: TextInputType.number,
                              prefixIcon:
                                  const Icon(Icons.currency_rupee_rounded),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppTextField(
                              controller: _experienceController,
                              label: 'Experience (Years)',
                              hint: 'e.g. 5',
                              keyboardType: TextInputType.number,
                              prefixIcon:
                                  const Icon(Icons.work_history_outlined),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _workAddressController,
                        label: 'Operating City / Area',
                        hint: 'e.g. Bandra West, Mumbai',
                        prefixIcon: const Icon(Icons.location_on_outlined),
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _bioController,
                        label: 'Professional Bio / About',
                        hint:
                            'Brief description of your skills and work experience',
                        maxLines: 3,
                        prefixIcon: const Icon(Icons.description_outlined),
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _upiController,
                        label: 'UPI ID for Payouts',
                        hint: 'e.g. name@okhdfcbank',
                        prefixIcon: const Icon(
                            Icons.account_balance_wallet_outlined),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ] else ...[
                  // Customer Specific Address
                  _SectionTitle(
                    icon: Icons.home_outlined,
                    title: 'Default Service Address',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _FormCard(
                    children: [
                      AppTextField(
                        controller: _workAddressController,
                        label: 'Home / Work Address',
                        hint: 'Flat, Street, Landmark',
                        prefixIcon: const Icon(Icons.pin_drop_outlined),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              controller: _cityController,
                              label: 'City',
                              hint: 'e.g. Noida',
                              prefixIcon: const Icon(Icons.location_city_outlined),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppTextField(
                              controller: _pincodeController,
                              label: 'Pincode',
                              hint: '201301',
                              keyboardType: TextInputType.number,
                              prefixIcon: const Icon(Icons.pin_outlined),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],

                // Section 3: Emergency Contact
                _SectionTitle(
                  icon: Icons.emergency_outlined,
                  title: 'Emergency Contact',
                ),
                const SizedBox(height: AppSpacing.sm),
                _FormCard(
                  children: [
                    AppTextField(
                      controller: _emergencyNameController,
                      label: 'Contact Person Name',
                      hint: 'e.g. Ramesh Sharma',
                      prefixIcon: const Icon(Icons.contact_phone_outlined),
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _emergencyPhoneController,
                      label: 'Emergency Phone Number',
                      hint: '+91 9876543210',
                      keyboardType: TextInputType.phone,
                      prefixIcon: const Icon(Icons.phone_in_talk_outlined),
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _emergencyRelationController,
                      label: 'Relationship',
                      hint: 'e.g. Spouse, Parent, Sibling, Friend',
                      prefixIcon: const Icon(Icons.people_outline_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),

                // Save Action Button
                PrimaryButton(
                  label: 'Save Changes',
                  loading: state.status == ProfileStatus.loading,
                  onPressed: () => _save(state),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProfileAvatarHeader extends StatelessWidget {
  const _ProfileAvatarHeader({
    required this.name,
    required this.email,
    required this.isWorker,
  });

  final String name;
  final String email;
  final bool isWorker;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 46,
                backgroundColor: scheme.primary.withValues(alpha: 0.12),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    color: scheme.primary,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            name.isNotEmpty ? name : 'Fixly User',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Text(
              isWorker ? 'Fixly Worker Partner' : 'Fixly Customer',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: scheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: context.muted,
                ),
          ),
        ],
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: scheme.outline.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }
}
