import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';

class ReaderSettingsProvider extends ChangeNotifier {
  double _fontSize = AppConstants.defaultFontSize;
  double _lineSpacing = AppConstants.defaultLineSpacing;
  String _fontFamily = AppConstants.defaultFontFamily;
  bool _isSerifFont = false;
  Color _backgroundColor = const Color(0xFF0F0E17);
  Color _textColor = const Color(0xFFF8F7FF);
  int _readerThemeIndex = 0; // 0: dark, 1: light, 2: sepia, 3: amoled
  bool _showToolbar = true;

  // Getters
  double get fontSize => _fontSize;
  double get lineSpacing => _lineSpacing;
  String get fontFamily => _fontFamily;
  bool get isSerifFont => _isSerifFont;
  Color get backgroundColor => _backgroundColor;
  Color get textColor => _textColor;
  int get readerThemeIndex => _readerThemeIndex;
  bool get showToolbar => _showToolbar;

  // Reader theme presets
  static const List<Map<String, Color>> readerThemes = [
    {'bg': Color(0xFF0F0E17), 'text': Color(0xFFF8F7FF)}, // Dark
    {'bg': Color(0xFFFFFFFF), 'text': Color(0xFF1A1A2E)}, // Light
    {'bg': Color(0xFFF5E6CA), 'text': Color(0xFF3E2723)}, // Sepia
    {'bg': Color(0xFF000000), 'text': Color(0xFFE0E0E0)}, // AMOLED
  ];

  static const List<String> readerThemeNames = [
    'Dark',
    'Light',
    'Sepia',
    'AMOLED',
  ];

  ReaderSettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _fontSize = prefs.getDouble(AppConstants.keyFontSize) ?? AppConstants.defaultFontSize;
    _lineSpacing = prefs.getDouble(AppConstants.keyLineSpacing) ?? AppConstants.defaultLineSpacing;
    _fontFamily = prefs.getString(AppConstants.keyFontFamily) ?? AppConstants.defaultFontFamily;
    _readerThemeIndex = prefs.getInt('reader_theme_index') ?? 0;
    _applyReaderTheme(_readerThemeIndex);
    notifyListeners();
  }

  Future<void> setFontSize(double size) async {
    _fontSize = size.clamp(AppConstants.minFontSize, AppConstants.maxFontSize);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(AppConstants.keyFontSize, _fontSize);
    notifyListeners();
  }

  void increaseFontSize() {
    setFontSize(_fontSize + 2);
  }

  void decreaseFontSize() {
    setFontSize(_fontSize - 2);
  }

  Future<void> setLineSpacing(double spacing) async {
    _lineSpacing = spacing.clamp(1.0, 3.0);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(AppConstants.keyLineSpacing, _lineSpacing);
    notifyListeners();
  }

  Future<void> setFontFamily(String family) async {
    _fontFamily = family;
    _isSerifFont = family == 'Georgia' || family == 'Merriweather';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyFontFamily, _fontFamily);
    notifyListeners();
  }

  Future<void> setReaderTheme(int index) async {
    _readerThemeIndex = index;
    _applyReaderTheme(index);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('reader_theme_index', index);
    notifyListeners();
  }

  void _applyReaderTheme(int index) {
    if (index >= 0 && index < readerThemes.length) {
      _backgroundColor = readerThemes[index]['bg']!;
      _textColor = readerThemes[index]['text']!;
    }
  }

  void toggleToolbar() {
    _showToolbar = !_showToolbar;
    notifyListeners();
  }
}
