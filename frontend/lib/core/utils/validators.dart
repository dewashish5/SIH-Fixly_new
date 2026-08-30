abstract final class Validators {
  static final _panRegex = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$');

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final pattern = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!pattern.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 10) {
      return 'Enter a valid 10-digit phone number';
    }
    return null;
  }

  static String? otp(String? value) {
    if (value == null || value.trim().length != 6) {
      return 'Enter 6-digit OTP';
    }
    return null;
  }

  static String? requiredField(String? value, {String label = 'Field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required';
    }
    return null;
  }

  static String? pan(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'PAN is required';
    }
    final pan = value.trim().toUpperCase();
    if (!_panRegex.hasMatch(pan)) {
      return 'Invalid PAN format (e.g. ABCDE1234F)';
    }
    if (pan[3] != 'P') {
      return '4th letter must be P for individual holder';
    }
    return null;
  }

  static String? aadhaar(String? value) {
    if (value == null || value.replaceAll(' ', '').length != 12) {
      return 'Enter 12-digit Aadhaar number';
    }
    return null;
  }

  static String? upi(String? value) {
    if (value == null || !value.contains('@')) {
      return 'Enter valid UPI ID';
    }
    return null;
  }
}
