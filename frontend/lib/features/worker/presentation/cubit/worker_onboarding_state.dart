part of 'worker_onboarding_cubit.dart';

enum WorkerOnboardingStatus { initial, loading, loaded, failure, submitted }

class WorkerOnboardingState extends Equatable {
  const WorkerOnboardingState({
    this.currentStep = 1,
    required this.formData,
    this.status = WorkerOnboardingStatus.initial,
    this.kycStatus = KycReviewStatus.submitted,
    this.errorMessage,
  });

  final int currentStep;
  final OnboardingFormData formData;
  final WorkerOnboardingStatus status;
  final KycReviewStatus kycStatus;
  final String? errorMessage;

  WorkerOnboardingState copyWith({
    int? currentStep,
    OnboardingFormData? formData,
    WorkerOnboardingStatus? status,
    KycReviewStatus? kycStatus,
    String? errorMessage,
  }) {
    return WorkerOnboardingState(
      currentStep: currentStep ?? this.currentStep,
      formData: formData ?? this.formData,
      status: status ?? this.status,
      kycStatus: kycStatus ?? this.kycStatus,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [currentStep, formData, status, kycStatus, errorMessage];
}
