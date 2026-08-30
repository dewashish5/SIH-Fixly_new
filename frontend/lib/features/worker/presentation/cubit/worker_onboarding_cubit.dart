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

  void updateServiceRadius(double km) {
    _emitForm(state.formData.copyWith(serviceRadiusKm: km));
  }

  void updateHasEshram(bool value) {
    _emitForm(state.formData.copyWith(hasEshram: value));
  }

  void updateEshramUan(String value) {
    _emitForm(state.formData.copyWith(eshramUan: value));
  }

  void updateBankAccount(String value) {
    _emitForm(state.formData.copyWith(bankAccount: value));
  }

  void updateUpiId(String value) {
    _emitForm(state.formData.copyWith(upiId: value));
  }

  void setStep(int step) {
    emit(state.copyWith(currentStep: step.clamp(1, totalSteps)));
  }

  String? validateStep(int step) {
    final data = state.formData;
    switch (step) {
      case 1:
        return Validators.requiredField(data.fullName, label: 'Full name');
      case 2:
        return Validators.aadhaar(data.aadhaar);
      case 3:
        return Validators.pan(data.pan);
      case 4:
        return data.selfieVerified ? null : 'Please capture a selfie';
      case 5:
        return data.certificateUploaded
            ? null
            : 'Please upload your certificate';
      case 6:
        return data.skills.isEmpty ? 'Select at least one skill' : null;
      case 7:
        return data.serviceRadiusKm < 1 ? 'Set a service radius' : null;
      case 8:
        return null;
      case 9:
        if (data.bankAccount.trim().isEmpty && data.upiId.trim().isEmpty) {
          return 'Enter bank account or UPI ID';
        }
        if (data.upiId.isNotEmpty) {
          return Validators.upi(data.upiId);
        }
        return null;
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
