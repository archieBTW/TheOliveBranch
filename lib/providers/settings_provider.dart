
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;
  Color _primaryColor = Colors.deepPurple; // Lavender-ish default
  
  // Enabled sources
  Map<String, bool> _enabledSources = {
    'Sojo': true,
    'Red Letter': true,
    'BNG': true,
    'Christian Century': true,
    'Good Faith Media': true,
    'RNS': true,
    'NCR': true,
    'JFH': true,
    'IVM': true,
    'HM Mag': true,
    'Relevant': true,
  };

  SettingsProvider() {
    _loadFromPrefs();
  }

  ThemeMode get themeMode => _themeMode;
  Color get primaryColor => _primaryColor;
  Map<String, bool> get enabledSources => _enabledSources;

  bool isSourceEnabled(String sourceName) {
    return _enabledSources[sourceName] ?? true;
  }

  void toggleTheme(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    _saveTheme();
  }

  void setPrimaryColor(Color color) {
    _primaryColor = color;
    notifyListeners();
    _saveColor();
  }

  void toggleSource(String sourceName, bool isEnabled) {
    if (_enabledSources.containsKey(sourceName)) {
      _enabledSources[sourceName] = isEnabled;
      notifyListeners();
      _saveSources();
    }
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load Theme
    final isDark = prefs.getBool('isDark') ?? true;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;

    // Load Color
    final colorValue = prefs.getInt('primaryColor');
    if (colorValue != null) {
      _primaryColor = Color(colorValue);
    }

    // Load Sources
    final sourcesString = prefs.getString('enabledSources');
    if (sourcesString != null) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(sourcesString);
        // Merge with defaults to ensure new sources appear
        decoded.forEach((key, value) {
          if (_enabledSources.containsKey(key) && value is bool) {
            _enabledSources[key] = value;
          }
        });
      } catch (e) {
        debugPrint('Error loading sources: $e');
      }
    }
    
    notifyListeners();
  }

  Future<void> _saveTheme() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDark', _themeMode == ThemeMode.dark);
  }

  Future<void> _saveColor() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('primaryColor', _primaryColor.value);
  }

  Future<void> _saveSources() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(_enabledSources);
    await prefs.setString('enabledSources', encoded);
  }
}
