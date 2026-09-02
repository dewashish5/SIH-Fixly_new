part of 'profile_cubit.dart';

enum ProfileStatus { initial, loading, loaded, updated, error }

class ProfileState extends Equatable {
  const ProfileState({
    this.status = ProfileStatus.initial,
    this.name = '',
    this.phone = '',
    this.email = '',
    this.eshramUan = '',
    this.insured = false,
    this.skills = const [],
    this.errorMessage,
  });

  final ProfileStatus status;
  final String name;
  final String phone;
  final String email;
  final String eshramUan;
  final bool insured;
  final List<String> skills;
  final String? errorMessage;

  ProfileState copyWith({
    ProfileStatus? status,
    String? name,
    String? phone,
    String? email,
    String? eshramUan,
    bool? insured,
    List<String>? skills,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ProfileState(
      status: status ?? this.status,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      eshramUan: eshramUan ?? this.eshramUan,
      insured: insured ?? this.insured,
      skills: skills ?? this.skills,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props =>
      [status, name, phone, email, eshramUan, insured, skills, errorMessage];
}
