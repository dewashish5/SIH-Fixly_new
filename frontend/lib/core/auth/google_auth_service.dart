import 'package:firebase_auth/firebase_auth.dart';
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
    final account = await GoogleSignIn.instance.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw StateError('Google sign-in did not return an ID token');
    }

    final credential = GoogleAuthProvider.credential(idToken: idToken);
    final userCredential =
        await FirebaseAuth.instance.signInWithCredential(credential);
    final user = userCredential.user;
    if (user == null) {
      throw StateError('Firebase sign-in failed');
    }

    return GoogleAuthProfile(
      email: (user.email ?? account.email).trim(),
      name: (user.displayName ?? account.displayName ?? 'Fixly User').trim(),
      phone: (user.phoneNumber ?? '').trim(),
      avatar: user.photoURL ?? account.photoUrl,
    );
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn.instance.signOut();
  }

  Future<void> ensureReady() async {
    if (FirebaseBootstrap.webClientId == null) {
      await FirebaseBootstrap.init();
    }
  }
}
