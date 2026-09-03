part of 'worker_onboarding_cubit.dart';

enum WorkerOnboardingStatus { initial, loading, loaded, failure, submitted }

class WorkerOnboardingState extends Equatable {
  const WorkerOnboardingState({
    this.currentStep = 1,
    required this.formData,
    this.status = WorkerOnboardingStatus.initial,
    this.kycStatus = KycReviewStatus.submitted,
    this.declineReason,
    this.verifyingPayout = false,
    this.errorMessage,
  });

  final int currentStep;
  final OnboardingFormData formData;
  final WorkerOnboardingStatus status;
  final KycReviewStatus kycStatus;
  /// Admin message when [kycStatus] is [KycReviewStatus.rejected].
  final String? declineReason;
  final bool verifyingPayout;
  final String? errorMessage;

  WorkerOnboardingState copyWith({
    int? currentStep,
    OnboardingFormData? formData,
    WorkerOnboardingStatus? status,
    KycReviewStatus? kycStatus,
    String? declineReason,
    bool clearDeclineReason = false,
    bool? verifyingPayout,
    String? errorMessage,
  }) {
    return WorkerOnboardingState(
      currentStep: currentStep ?? this.currentStep,
      formData: formData ?? this.formData,
      status: status ?? this.status,
      kycStatus: kycStatus ?? this.kycStatus,
      declineReason:
          clearDeclineReason ? null : (declineReason ?? this.declineReason),
      verifyingPayout: verifyingPayout ?? this.verifyingPayout,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        currentStep,
        formData,
        status,
        kycStatus,
        declineReason,
        verifyingPayout,
        errorMessage,
      ];
}
