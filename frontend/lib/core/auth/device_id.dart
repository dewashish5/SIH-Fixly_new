import 'dart:math';

import 'token_storage.dart';

/// Stable device id for backend single-device sessions.
class DeviceId {
  DeviceId(this._storage);

  final TokenStorage _storage;

  String? _cached;

  Future<String> getOrCreate() async {
    if (_cached != null && _cached!.isNotEmpty) return _cached!;
    final existing = await _storage.deviceId;
    if (existing != null && existing.isNotEmpty) {
      _cached = existing;
      return existing;
    }
    final id = _uuidV4();
    await _storage.saveDeviceId(id);
    _cached = id;
    return id;
  }

  static String _uuidV4() {
    final r = Random.secure();
    final bytes = List<int>.generate(16, (_) => r.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    String h(int b) => b.toRadixString(16).padLeft(2, '0');
    final s = bytes.map(h).join();
    return '${s.substring(0, 8)}-${s.substring(8, 12)}-'
        '${s.substring(12, 16)}-${s.substring(16, 20)}-${s.substring(20)}';
  }
}
