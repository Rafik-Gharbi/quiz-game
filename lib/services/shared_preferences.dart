import 'package:encrypted_shared_preferences/encrypted_shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesService {
  SharedPreferences? _prefs;
  bool isReady = false;

  static final SharedPreferencesService _singleton = SharedPreferencesService._internal();

  factory SharedPreferencesService() => _singleton;

  SharedPreferencesService._internal() {
    _getSharedPreferencesInstance();
  }

  void add(String key, String value) => _prefs!.setString(key, value);

  String? get(String key) => _prefs?.getString(key);

  void removeKey(String key) => _prefs!.remove(key);

  Future<void> _getSharedPreferencesInstance() async {
    // Uses EncryptedSharedPreferences for secure storage of sensitive data.
    // If you don't need encryption, use SharedPreferences() instead.
    if (kIsWeb) {
      _prefs ??= await SharedPreferences.getInstance();
    } else {
      _prefs ??= await EncryptedSharedPreferences().getInstance();
    }
    isReady = true;
  }

  Future<void> clearAllSavedData() async {
    _prefs!.getKeys().forEach((element) => _prefs!.remove(element));
  }
}
