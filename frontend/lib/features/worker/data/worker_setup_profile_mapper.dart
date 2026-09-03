import '../../../core/constants/app_constants.dart';
import '../../../core/location/app_location.dart';
import '../../../shared/models/models.dart';

/// Builds PUT `/api/workers/setup-profile` body from onboarding form.
abstract final class WorkerSetupProfileMapper {
  static final _categoryIds = ServiceCategories.all.map((c) => c.id).toSet();

  static Map<String, dynamic> toBody(OnboardingFormData data) {
    final categories = data.skills
        .where(_categoryIds.contains)
        .toList(growable: false);
    final primaryCategory = categories.isNotEmpty
        ? categories.first
        : (data.skills.isNotEmpty ? data.skills.first : null);
    final loc = AppLocation.instance;
    final dob = data.dateOfBirth;
    final dobStr = dob == null
        ? null
        : '${dob.year.toString().padLeft(4, '0')}-'
              '${dob.month.toString().padLeft(2, '0')}-'
              '${dob.day.toString().padLeft(2, '0')}';

    return {
      'step1_identity': {
        'fullName': data.fullName.trim(),
        'dateOfBirth': dobStr,
        'gender': data.gender?.name,
        'phone': data.phone.trim(),
        'email': data.email.trim(),
        'aadhaarNumber': data.aadhaar.replaceAll(' ', ''),
        'aadhaarFrontPhoto': data.aadhaarFrontPath,
        'aadhaarBackPhoto': data.aadhaarBackPath,
        'panNumber': data.pan.trim().toUpperCase(),
        'panFrontPhoto': data.panFrontPath,
        'panBackPhoto': data.panBackPath,
        'selfieVerified': data.selfieVerified,
        'selfieImageUrl': data.selfieImageUrl,
        'govermentIdType': 'Aadhaar Card',
        'govermentIdNumber': data.aadhaar.replaceAll(' ', ''),
      },
      'step2_workProfile': {
        'certificateUploaded': data.certificateUploaded,
        'certifications': data.certificateUploaded
            ? <String>[
                data.certificateFileName ??
                    data.certificatePath?.split('/').last ??
                    'certificate',
              ]
            : <String>[],
        if (data.certificatePath != null && data.certificatePath!.isNotEmpty)
          'certificateFile': data.certificatePath,
        'categories': categories,
        'category': primaryCategory,
        'skills': data.skills,
        'experienceYears': data.experienceYears,
        'bio': data.bio.trim(),
        'rate': data.primaryRate,
        'categoryRates': data.categoryRatesPayload,
        'location': loc.hasFix
            ? {
                'type': 'Point',
                'coordinates': [loc.requireLng, loc.requireLat],
                if (loc.addressLabel != null && loc.addressLabel!.isNotEmpty)
                  'address': loc.addressLabel,
              }
            : null,
      },
      'step3_payoutWelfare': {
        'hasEshram': data.hasEshram,
        'eshramUan': data.hasEshram ? data.eshramUan.trim() : '',
        'payoutMethod': data.payoutMethod.name,
        'bank': {
          'accountHolderName': data.accountHolderName.trim(),
          'accountNumber': data.bankAccount.trim(),
          'confirmAccountNumber': data.bankAccount.trim(),
          'ifscCode': data.ifscCode.trim().toUpperCase(),
          'bankVerified': data.bankVerified,
        },
        'upi': {'upiId': data.upiId.trim(), 'upiVerified': data.upiVerified},
      },
    };
  }
}
