import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class UserModeStorage {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static const String _userModeKey = 'user_mode';

  static const String participantMode = 'participant';
  static const String organizerMode = 'organizer';

  static Future<void> saveUserMode(String mode) async {
    await _storage.write(key: _userModeKey, value: mode);
  }

  static Future<String?> getSavedUserMode() async {
    final mode = await _storage.read(key: _userModeKey);

    if (mode == participantMode || mode == organizerMode) {
      return mode;
    }

    return null;
  }

  static Future<void> clearUserMode() async {
    await _storage.delete(key: _userModeKey);
  }
}