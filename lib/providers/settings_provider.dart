import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class SettingsProvider with ChangeNotifier {
  static const String _boxName = 'readmile_settings';

  // Theme settings
  String _theme = 'light';
  Color _backgroundColor = Colors.white;
  Color _textColor = Colors.black;

  // Reading settings
  double _fontSize = 16.0;
  String _fontFamily = 'Georgia';
  double _lineHeight = 1.5;
  double _margin = 16.0;
  TextAlign _textAlign = TextAlign.left;

  // App settings
  bool _autoSave = true;
  bool _nightMode = false;
  double _brightness = 1.0;

  // Getters
  String get theme => _theme;
  Color get backgroundColor => _backgroundColor;
  Color get textColor => _textColor;
  double get fontSize => _fontSize;
  String get fontFamily => _fontFamily;
  double get lineHeight => _lineHeight;
  double get margin => _margin;
  TextAlign get textAlign => _textAlign;
  bool get autoSave => _autoSave;
  bool get nightMode => _nightMode;
  double get brightness => _brightness;

  /// Initialize settings from storage
  Future<void> init() async {
    try {
      final box = await Hive.openBox(_boxName);

      _theme = box.get('theme', defaultValue: 'light');
      _fontSize = box.get('fontSize', defaultValue: 16.0);
      _fontFamily = box.get('fontFamily', defaultValue: 'Georgia');
      _lineHeight = box.get('lineHeight', defaultValue: 1.5);
      _margin = box.get('margin', defaultValue: 16.0);
      _autoSave = box.get('autoSave', defaultValue: true);
      _nightMode = box.get('nightMode', defaultValue: false);
      _brightness = box.get('brightness', defaultValue: 1.0);

      // Set text alignment from stored value
      final alignValue = box.get('textAlign', defaultValue: 'left');
      _textAlign = _parseTextAlign(alignValue);

      // Update colors based on theme
      _updateThemeColors();

      print('✅ SettingsProvider initialized');
    } catch (e) {
      print('❌ Error initializing SettingsProvider: $e');
    }
  }

  /// Update theme and colors
  Future<void> setTheme(String newTheme) async {
    _theme = newTheme;
    _updateThemeColors();
    await _saveSettings();
    notifyListeners();
  }

  /// Update font size
  Future<void> setFontSize(double size) async {
    _fontSize = size;
    await _saveSettings();
    notifyListeners();
  }

  /// Update font family
  Future<void> setFontFamily(String family) async {
    _fontFamily = family;
    await _saveSettings();
    notifyListeners();
  }

  /// Update line height
  Future<void> setLineHeight(double height) async {
    _lineHeight = height;
    await _saveSettings();
    notifyListeners();
  }

  /// Update margin
  Future<void> setMargin(double newMargin) async {
    _margin = newMargin;
    await _saveSettings();
    notifyListeners();
  }

  /// Update text alignment
  Future<void> setTextAlign(TextAlign align) async {
    _textAlign = align;
    await _saveSettings();
    notifyListeners();
  }

  /// Toggle night mode
  Future<void> toggleNightMode() async {
    _nightMode = !_nightMode;
    _theme = _nightMode ? 'dark' : 'light';
    _updateThemeColors();
    await _saveSettings();
    notifyListeners();
  }

  /// Update brightness
  Future<void> setBrightness(double newBrightness) async {
    _brightness = newBrightness;
    await _saveSettings();
    notifyListeners();
  }

  /// Update theme colors based on current theme
  void _updateThemeColors() {
    switch (_theme) {
      case 'dark':
        _backgroundColor = const Color(0xFF1A1A1A);
        _textColor = Colors.white;
        break;
      case 'sepia':
        _backgroundColor = const Color(0xFFF4ECD8);
        _textColor = const Color(0xFF5D4E37);
        break;
      case 'night':
        _backgroundColor = Colors.black;
        _textColor = const Color(0xFFE0E0E0);
        break;
      default: // light
        _backgroundColor = Colors.white;
        _textColor = Colors.black;
    }
  }

  /// Save settings to Hive storage
  Future<void> _saveSettings() async {
    try {
      final box = await Hive.openBox(_boxName);
      await box.putAll({
        'theme': _theme,
        'fontSize': _fontSize,
        'fontFamily': _fontFamily,
        'lineHeight': _lineHeight,
        'margin': _margin,
        'textAlign': _textAlign.toString().split('.').last,
        'autoSave': _autoSave,
        'nightMode': _nightMode,
        'brightness': _brightness,
      });
    } catch (e) {
      print('❌ Error saving settings: $e');
    }
  }

  /// Parse TextAlign from string
  TextAlign _parseTextAlign(String value) {
    switch (value) {
      case 'center':
        return TextAlign.center;
      case 'right':
        return TextAlign.right;
      case 'justify':
        return TextAlign.justify;
      default:
        return TextAlign.left;
    }
  }

  /// Get available themes
  List<String> get availableThemes => ['light', 'dark', 'sepia', 'night'];

  /// Get available font families
  List<String> get availableFontFamilies => [
    'Georgia',
    'Times New Roman',
    'Arial',
    'Helvetica',
    'Verdana',
    'Calibri',
    'Open Sans',
  ];

  /// Reset to default settings
  Future<void> resetToDefaults() async {
    _theme = 'light';
    _fontSize = 16.0;
    _fontFamily = 'Georgia';
    _lineHeight = 1.5;
    _margin = 16.0;
    _textAlign = TextAlign.left;
    _autoSave = true;
    _nightMode = false;
    _brightness = 1.0;

    _updateThemeColors();
    await _saveSettings();
    notifyListeners();
  }
}
