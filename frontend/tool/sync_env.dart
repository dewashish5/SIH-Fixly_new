/// Sync `.env` → `dart_defines.json` + `assets/config/mapbox.json`.
///
/// Usage: `dart run tool/sync_env.dart`
library;

import 'dart:convert';
import 'dart:io';

void main() {
  final envFile = File('.env');
  if (!envFile.existsSync()) {
    stderr.writeln('missing .env — copy .env.example → .env and set Mapbox_api_key');
    exit(1);
  }

  final values = <String, String>{};
  for (final raw in envFile.readAsLinesSync()) {
    final line = raw.trim();
    if (line.isEmpty || line.startsWith('#')) continue;
    final i = line.indexOf('=');
    if (i <= 0) continue;
    final key = line.substring(0, i).trim();
    var val = line.substring(i + 1).trim();
    if ((val.startsWith('"') && val.endsWith('"')) ||
        (val.startsWith("'") && val.endsWith("'"))) {
      val = val.substring(1, val.length - 1);
    }
    values[key] = val;
  }

  final token = (values['Mapbox_api_key'] ?? values['ACCESS_TOKEN'] ?? '').trim();
  if (token.isEmpty) {
    stderr.writeln('Mapbox_api_key (or ACCESS_TOKEN) empty in .env');
    exit(1);
  }

  final defines = <String, String>{
    'Mapbox_api_key': token,
    'ACCESS_TOKEN': token,
  };
  File('dart_defines.json').writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(defines)}\n',
  );

  Directory('assets/config').createSync(recursive: true);
  File('assets/config/mapbox.json').writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert({'accessToken': token})}\n',
  );

  stdout.writeln('wrote dart_defines.json + assets/config/mapbox.json');
}
