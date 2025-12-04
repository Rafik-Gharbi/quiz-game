import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../utils/constants/constants.dart';

import '../../../utils/constants/shared_preferences_keys.dart';
import '../../../utils/helper.dart';
import '../shared_preferences.dart';

class ThemeService {
  Rx<ThemeMode> currentTheme = ThemeMode.light.obs;

  static final ThemeService _singleton = ThemeService._internal();

  factory ThemeService() => _singleton;

  ThemeService._internal() {
    _init();
  }

  bool get isDark => currentTheme.value == ThemeMode.dark;

  /// Toggles the app theme between light and dark mode.
  /// It updates the current theme and saves the preference in shared preferences for future sessions.
  void toggleTheme() {
    if (currentTheme.value == ThemeMode.dark) {
      _setTheme(ThemeMode.light);
    } else {
      _setTheme(ThemeMode.dark);
    }
  }

  Future<void> _init() async {
    // Set the app theme based on the saved preference.
    // If no preference is saved, use the default theme. Change it in constants.dart regarding your needs.
    await Helper.waitAndExecute(
      () => SharedPreferencesService().isReady,
      () => _setTheme(
        ThemeMode.values.cast<ThemeMode?>().singleWhere((element) => element?.name == SharedPreferencesService().get(currentThemeKey), orElse: () => null) ?? defaultTheme,
      ),
    );
  }

  Future<void> _setTheme(ThemeMode theme) async {
    currentTheme.value = theme;
    Get.changeThemeMode(theme);
    SharedPreferencesService().add(currentThemeKey, theme == ThemeMode.dark ? 'dark' : 'light');
    Future.delayed(Durations.long1, () => Get.forceAppUpdate());
  }
}
