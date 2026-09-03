/// API host. Override via `--dart-define=API_BASE_URL=...` or `dart_defines.json`.
/// Public Cloudflare tunnel (shared) — host must keep backend + cloudflared running.
class ApiConfig {
  ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://tulsa-michigan-proved-rap.trycloudflare.com',
  );
}
