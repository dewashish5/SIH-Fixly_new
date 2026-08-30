part of 'profile_cubit.dart';

enum ProfileStatus { initial, loading, loaded, updated, failure }

class ProfileState extends Equatable {
  const ProfileState({
    this.status = ProfileStatus.initial,
    this.name = '',
    this.phone = '',
    this.eshramUan = '',
    this.insured = false,
    this.skills = const [],
  });

  final ProfileStatus status;
  final String name;
  final String phone;
  final String eshramUan;
  final bool insured;
  final List<String> skills;

  ProfileState copyWith({
    ProfileStatus? status,
    String? name,
    String? phone,
    String? eshramUan,
    bool? insured,
    List<String>? skills,
  }) {
    return ProfileState(
      status: status ?? this.status,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      eshramUan: eshramUan ?? this.eshramUan,
      insured: insured ?? this.insured,
      skills: skills ?? this.skills,
    );
  }

  @override
  List<Object?> get props => [status, name, phone, eshramUan, insured, skills];
}
