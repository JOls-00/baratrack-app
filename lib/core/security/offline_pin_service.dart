import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class OfflinePinService {
  static const String _pinKey = 'admin_offline_pin';
  static const _storage = FlutterSecureStorage();

  static Future<bool> hasPin() async {
    try {
      final pin = await _storage.read(key: _pinKey);
      return pin != null && pin.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static Future<void> setPin(String pin) async {
    await _storage.write(key: _pinKey, value: pin);
  }

  static Future<bool> verifyPin(String pin) async {
    try {
      final stored = await _storage.read(key: _pinKey);
      if (stored == null) {
        // If no PIN set yet, default PIN for offline testing is '1234'
        return pin == '1234';
      }
      return stored == pin;
    } catch (_) {
      return false;
    }
  }

  static Future<void> clearPin() async {
    await _storage.delete(key: _pinKey);
  }
}
