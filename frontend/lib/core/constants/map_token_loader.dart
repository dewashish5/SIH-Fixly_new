import 'dart:convert';

import 'package:flutter/services.dart';

import 'map_token.dart';

abstract final class MapTokenLoader {
  static Future<void> configure() async {
    const envToken = String.fromEnvironment('ACCESS_TOKEN');
    if (envToken.isNotEmpty) {
      MapToken.configure(envToken);
      return;
    }

    try {
      final raw = await rootBundle.loadString('assets/config/mapbox.json');
      final data = jsonDecode(raw) as Map<String, dynamic>;
      MapToken.configure(data['accessToken'] as String?);
    } catch (_) {
      MapToken.configure(null);
    }
  }
}
