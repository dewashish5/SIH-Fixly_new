import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'app/app.dart';
import 'core/firebase/firebase_bootstrap.dart';
import 'core/network/api_client.dart';
import 'core/preferences/app_preferences.dart';

Future<void> main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await AppPreferences.instance.init();
  try {
    await FirebaseBootstrap.init();
  } catch (e) {
    debugPrint('Firebase init skipped: $e');
  }
  await ApiServices.init();
  runApp(const App());
}
