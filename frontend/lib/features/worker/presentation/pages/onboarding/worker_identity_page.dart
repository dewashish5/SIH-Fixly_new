import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/router/route_names.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/theme_x.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/utils/input_formatters.dart';
import '../../../../../core/utils/validators.dart';
import '../../../../../core/widgets/core_widgets.dart';
import '../../cubit/worker_onboarding_cubit.dart';
import 'worker_onboarding_layout.dart';

class WorkerIdentityPage extends StatefulWidget {
  const WorkerIdentityPage({super.key});

  @override
  State<WorkerIdentityPage> createState() => _WorkerIdentityPageState();
}

class _WorkerIdentityPageState extends State<WorkerIdentityPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _aadhaarController;
  late final TextEditingController _panController;

  @override
  void initState() {
    super.initState();
    final data = context.read<WorkerOnboardingCubit>().state.formData;
    _nameController = TextEditingController(text: data.fullName);
    _aadhaarController = TextEditingController(text: data.aadhaar);
    _panController = TextEditingController(text: data.pan);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _aadhaarController.dispose();
    _panController.dispose();
    super.dispose();
  }

  void _continue() {
    final cubit = context.read<WorkerOnboardingCubit>();
    cubit
      ..updateFullName(_nameController.text)
      ..updateAadhaar(_aadhaarController.text)
      ..updatePan(_panController.text);

    if (!(_formKey.currentState?.validate() ?? false)) return;

    final error = cubit.validateStep(1);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    cubit.setStep(1);
    context.push(RouteNames.workerOnboardingWork);
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<WorkerOnboardingCubit>();

    return BlocBuilder<WorkerOnboardingCubit, WorkerOnboardingState>(
      builder: (context, state) {
        final captured = state.formData.selfieVerified;
        final imageUrl = state.formData.selfieImageUrl;

        return WorkerOnboardingLayout(
          step: 1,
          title: context.l10n.identityKyc,
          onContinue: _continue,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Name, Aadhaar, PAN, and selfie for KYC.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                OnboardingSection(
                  title: context.l10n.personalDetails,
                  child: AppTextField(
                    controller: _nameController,
                    label: 'Full name',
                    hint: 'Rajesh Kumar',
                    validator: (v) =>
                        Validators.requiredField(v, label: 'Full name'),
                    onChanged: cubit.updateFullName,
                  ),
                ),
                OnboardingSection(
                  title: context.l10n.aadhaarVerification,
                  child: Column(
                    children: [
                      AppTextField(
                        controller: _aadhaarController,
                        label: 'Aadhaar number',
                        hint: '1234 5678 9012',
                        keyboardType: TextInputType.number,
                        maxLength: 14,
                        validator: Validators.aadhaar,
                        onChanged: cubit.updateAadhaar,
                      ),
                      const SizedBox(height: 12),
                      const AppCard(
                        child: Row(
                          children: [
                            Icon(Icons.lock_outline),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Data encrypted. Used only for verification.',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                OnboardingSection(
                  title: context.l10n.panVerification,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppTextField(
                        controller: _panController,
                        label: 'PAN number',
                        hint: 'ABCDE1234F',
                        maxLength: 10,
                        textCapitalization: TextCapitalization.characters,
                        inputFormatters: const [
                          UpperCaseTextFormatter(),
                        ],
                        validator: Validators.pan,
                        onChanged: cubit.updatePan,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Format: 5 letters + 4 digits + 1 letter. '
                        '4th letter must be P for individuals.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: context.muted,
                            ),
                      ),
                    ],
                  ),
                ),
                OnboardingSection(
                  title: context.l10n.selfieVerification,
                  child: Column(
                    children: [
                      Text(
                        'Clear selfie for face match with PAN and Aadhaar.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          color: context.scheme.surfaceContainerHighest,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: captured
                                ? AppColors.success
                                : context.hairline,
                            width: 3,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: captured &&
                                imageUrl != null &&
                                imageUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.cover,
                                placeholder: (_, _) => const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                errorWidget: (_, _, _) => Icon(
                                  Icons.face_retouching_natural,
                                  size: 56,
                                  color: AppColors.textMuted,
                                ),
                              )
                            : Icon(
                                Icons.face_retouching_natural,
                                size: 56,
                                color: AppColors.textMuted,
                              ),
                      ),
                      const SizedBox(height: 16),
                      SecondaryButton(
                        label: captured ? 'Retake selfie' : 'Capture selfie',
                        onPressed: captured
                            ? cubit.clearSelfie
                            : () {
                                cubit.captureSelfie(
                                  imageUrl: AppImages.demoSelfie,
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Selfie captured (mock)'),
                                  ),
                                );
                              },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
