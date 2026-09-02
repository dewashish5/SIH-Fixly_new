/// API host. Override: `--dart-define=API_BASE_URL=http://10.0.2.2:8000`
class ApiConfig {
  ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://shirt-phentermine-promising-price.trycloudflare.com',
  );
}
