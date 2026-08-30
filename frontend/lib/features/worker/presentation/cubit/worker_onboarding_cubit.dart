import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/data/mock/mock_repository.dart';
import '../../../../shared/models/models.dart';

part 'worker_onboarding_state.dart';

class WorkerOnboardingCubit extends Cubit<WorkerOnboardingState> {
  WorkerOnboardingCubit({MockRepository? repository})
      : _repo = repository ?? MockRepository.instance,
        super(
          WorkerOnboardingState(
            formData: (repository ?? MockRepository.instance).onboardingData,
          ),
        );

  final MockRepository _repo;

  static const totalSteps = AppConstants.onboardingTotalSteps;

  void updateFullName(String value) {
    _emitForm(state.formData.copyWith(fullName: value));
  }

  void updateAadhaar(String value) {
    _emitForm(state.formData.copyWith(aadhaar: value));
  }

  void updatePan(String value) {
    _emitForm(state.formData.copyWith(pan: value.toUpperCase()));
  }

  void captureSelfie({required String imageUrl}) {
    _emitForm(
      state.formData.copyWith(
        selfieVerified: true,
        selfieImageUrl: imageUrl,
      ),
    );
  }

  void clearSelfie() {
    _emitForm(
      state.formData.copyWith(
        selfieVerified: false,
        selfieImageUrl: null,
      ),
    );
  }

  void updateCertificateUploaded(bool uploaded) {
    _emitForm(state.formData.copyWith(certificateUploaded: uploaded));
  }

  void toggleSkill(String skillId) {
    final skills = List<String>.from(state.formData.skills);
    if (skills.contains(skillId)) {
      skills.remove(skillId);
    } else {
      skills.add(skillId);
    }
    _emitForm(state.formData.copyWith(skills: skills));
  }

  void addCustomSkill(String raw) {
    final skill = raw.trim();
    if (skill.isEmpty) return;
    final skills = List<String>.from(state.formData.skills);
    final exists = skills.any((s) => s.toLowerCase() == skill.toLowerCase());
    if (exists) return;
    skills.add(skill);
    _emitForm(state.formData.copyWith(skills: skills));
  }

  void removeSkill(String skill) {
    final skills = List<String>.from(state.formData.skills)..remove(skill);
    _emitForm(state.formData.copyWith(skills: skills));
  }

  void updateServiceRadius(double km) {
    _emitForm(state.formData.copyWith(serviceRadiusKm: km));
  }

  void updateHasEshram(bool value) {
    _emitForm(state.formData.copyWith(hasEshram: value));
  }

  void updateEshramUan(String value) {
    _emitForm(state.formData.copyWith(eshramUan: value));
  }

  void setPayoutMethod(PayoutMethod method) {
    _emitForm(state.formData.copyWith(payoutMethod: method));
  }

  void updateBankAccount(String value) {
    _emitForm(
      state.formData.copyWith(
        bankAccount: value,
        bankVerified: false,
      ),
    );
  }

  void updateIfscCode(String value) {
    _emitForm(
      state.formData.copyWith(
        ifscCode: value.toUpperCase(),
        bankVerified: false,
      ),
    );
  }

  void updateUpiId(String value) {
    _emitForm(
      state.formData.copyWith(
        upiId: value.trim(),
        upiVerified: false,
      ),
    );
  }

  Future<String?> verifyBankAccount() async {
    final data = state.formData;
    final error = Validators.bankAccount(data.bankAccount) ??
        Validators.ifsc(data.ifscCode);
    if (error != null) return error;

    emit(state.copyWith(verifyingPayout: true));
    await Future<void>.delayed(const Duration(milliseconds: 700));
    // Mock: reject obviously fake accounts.
    if (data.bankAccount.replaceAll(RegExp(r'\D'), '').startsWith('000')) {
      emit(state.copyWith(verifyingPayout: false));
      return 'Could not verify this account. Check details and try again.';
    }
    _emitForm(state.formData.copyWith(bankVerified: true));
    emit(state.copyWith(verifyingPayout: false));
    return null;
  }

  Future<String?> verifyUpiId() async {
    final error = Validators.upi(state.formData.upiId);
    if (error != null) return error;

    emit(state.copyWith(verifyingPayout: true));
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (state.formData.upiId.toLowerCase().contains('invalid')) {
      emit(state.copyWith(verifyingPayout: false));
      return 'UPI ID not found. Please check and try again.';
    }
    _emitForm(state.formData.copyWith(upiVerified: true));
    emit(state.copyWith(verifyingPayout: false));
    return null;
  }

  void setStep(int step) {
    emit(state.copyWith(currentStep: step.clamp(1, totalSteps)));
  }

  String? validateStep(int step) {
    final data = state.formData;
    switch (step) {
      case 1:
        return Validators.requiredField(data.fullName, label: 'Full name') ??
            Validators.aadhaar(data.aadhaar) ??
            Validators.pan(data.pan) ??
            (data.selfieVerified ? null : 'Please capture a selfie');
      case 2:
        if (!data.certificateUploaded) {
          return 'Please upload your certificate';
        }
        if (data.skills.isEmpty) return 'Select at least one skill';
        if (data.serviceRadiusKm < 1) return 'Set a service radius';
        return null;
      case 3:
        if (data.payoutMethod == PayoutMethod.bank) {
          return Validators.bankAccount(data.bankAccount) ??
              Validators.ifsc(data.ifscCode) ??
              (data.bankVerified ? null : 'Please verify your bank account');
        }
        return Validators.upi(data.upiId) ??
            (data.upiVerified ? null : 'Please verify your UPI ID');
      default:
        return null;
    }
  }

  bool canProceedFromStep(int step) => validateStep(step) == null;

  Future<void> submitOnboarding() async {
    emit(state.copyWith(status: WorkerOnboardingStatus.loading));
    await _repo.mockDelay();
    _repo.onboardingData = state.formData;
    _repo.kycReviewStatus = KycReviewStatus.submitted;
    emit(
      state.copyWith(
        status: WorkerOnboardingStatus.submitted,
        kycStatus: KycReviewStatus.submitted,
      ),
    );
  }

  Future<void> refreshKycStatus() async {
    emit(state.copyWith(status: WorkerOnboardingStatus.loading));
    await _repo.mockDelay();
    final next = _repo.advanceKycReview();
    emit(
      state.copyWith(
        status: WorkerOnboardingStatus.loaded,
        kycStatus: next,
      ),
    );
  }

  void _emitForm(OnboardingFormData data) {
    _repo.onboardingData = data;
    emit(state.copyWith(formData: data, status: WorkerOnboardingStatus.loaded));
  }
}
