import 'dart:convert';

import 'package:flutter/services.dart';

import 'map_token.dart';

abstract final class MapTokenLoader {
  static Future<void> configure() async {
    const accessToken = String.fromEnvironment('ACCESS_TOKEN');
    const mapboxApiKey = String.fromEnvironment('Mapbox_api_key');
    final fromDefine =
        accessToken.isNotEmpty ? accessToken : mapboxApiKey;
    if (fromDefine.isNotEmpty) {
      MapToken.configure(fromDefine);
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
