import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends GetxController {
  static const String _themeKey = 'is_dark_theme';

  final Rx<ThemeMode> themeMode = ThemeMode.light.obs;

  bool get isDarkMode => themeMode.value == ThemeMode.dark;

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_themeKey) ?? false;
    themeMode.value = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> setLightTheme() async {
    themeMode.value = ThemeMode.light;
    Get.changeThemeMode(ThemeMode.light);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, false);
  }

  Future<void> setDarkTheme() async {
    themeMode.value = ThemeMode.dark;
    Get.changeThemeMode(ThemeMode.dark);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, true);
  }
}
