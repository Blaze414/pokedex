import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  static const String _darkModeKey = 'dark_mode';
  static const String _useCacheKey = 'use_cache';

  bool _isDarkMode = false;
  bool _useCache = true;

  bool get isDarkMode => _isDarkMode;
  bool get useCache => _useCache;
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_darkModeKey) ?? false;
    _useCache = prefs.getBool(_useCacheKey) ?? true;
    notifyListeners();
  }

  Future<void> toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, _isDarkMode);
    notifyListeners();
  }

  Future<void> setUseCache(bool value) async {
    _useCache = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_useCacheKey, value);
    notifyListeners();
  }

  static Future<bool> shouldUseCache() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_useCacheKey) ?? true;
  }
}
