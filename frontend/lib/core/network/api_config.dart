/// API host. Override via `--dart-define=API_BASE_URL=...` or `dart_defines.json`.
/// Public Cloudflare tunnel — host must keep backend + cloudflared running.
class ApiConfig {
  ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://hardware-tried-transcripts-profit.trycloudflare.com',
  );
}
