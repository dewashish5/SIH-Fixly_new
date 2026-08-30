/// Runtime Mapbox public token (`pk.*`) set during app startup.
abstract final class MapToken {
  static String? _value;

  static String get accessToken => _value ?? '';

  static bool get hasToken => accessToken.isNotEmpty;

  static void configure(String? token) {
    final trimmed = token?.trim();
    _value = (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }
}
