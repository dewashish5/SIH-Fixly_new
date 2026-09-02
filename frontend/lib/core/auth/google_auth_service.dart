import 'package:google_sign_in/google_sign_in.dart';

import '../firebase/firebase_bootstrap.dart';

class GoogleAuthProfile {
  const GoogleAuthProfile({
    required this.email,
    required this.name,
    required this.phone,
    this.avatar,
  });

  final String email;
  final String name;
  final String phone;
  final String? avatar;
}

class GoogleAuthService {
  GoogleAuthService._();

  static final GoogleAuthService instance = GoogleAuthService._();

  Future<GoogleAuthProfile> signIn() async {
    await ensureReady();

    final account = await GoogleSignIn.instance.authenticate();
    final email = account.email.trim();
    if (email.isEmpty) {
      throw StateError('Google account did not return an email address.');
    }

    return GoogleAuthProfile(
      email: email,
      name: (account.displayName ?? 'Fixly User').trim(),
      phone: '',
      avatar: account.photoUrl,
    );
  }

  Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
  }

  Future<void> ensureReady() async {
    await FirebaseBootstrap.init();
  }
}
