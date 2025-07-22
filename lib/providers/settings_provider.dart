import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  static const String _fontFamilyKey = 'font_family';
  static const String _fontSizeKey = 'font_size';
  static const String _lineHeightKey = 'line_height';
  static const String _textAlignKey = 'text_align';
  static const String _themeKey = 'theme';
  static const String _marginKey = 'margin';

  // Default values
  String _fontFamily = 'Roboto';
  double _fontSize = 18.0;
  double _lineHeight = 1.5;
  TextAlign _textAlign = TextAlign.justify;
  String _theme = 'light';
  double _margin = 16.0;

  SharedPreferences? _prefs;

  // Getters
  String get fontFamily => _fontFamily;
  double get fontSize => _fontSize;
  double get lineHeight => _lineHeight;
  TextAlign get textAlign => _textAlign;
  String get theme => _theme;
  double get margin => _margin;

  // Available options
  List<String> get availableFonts => [
    'Roboto',
    'Open Sans',
    'Lato',
    'Montserrat',
    'Source Sans Pro',
    'Noto Sans'
  ];

  List<String> get availableThemes => ['light', 'sepia', 'dark'];

  // Colors based on theme
  Color get backgroundColor {
    switch (_theme) {
      case 'sepia':
        return const Color(0xFFF6F0E4);
      case 'dark':
        return const Color(0xFF1E1E1E);
      default:
        return Colors.white;
    }
  }

  Color get textColor {
    switch (_theme) {
      case 'dark':
        return const Color(0xFFE0E0E0);
      case 'sepia':
        return const Color(0xFF2C1810);
      default:
        return const Color(0xFF212121);
    }
  }

  // Initialize and load settings
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadSettings();
  }

  Future<void> _loadSettings() async {
    if (_prefs == null) return;

    _fontFamily = _prefs!.getString(_fontFamilyKey) ?? 'Roboto';
    _fontSize = _prefs!.getDouble(_fontSizeKey) ?? 18.0;
    _lineHeight = _prefs!.getDouble(_lineHeightKey) ?? 1.5;
    _textAlign = _getTextAlignFromString(_prefs!.getString(_textAlignKey) ?? 'justify');
    _theme = _prefs!.getString(_themeKey) ?? 'light';
    _margin = _prefs!.getDouble(_marginKey) ?? 16.0;

    notifyListeners();
  }

  TextAlign _getTextAlignFromString(String value) {
    switch (value) {
      case 'left':
        return TextAlign.left;
      case 'center':
        return TextAlign.center;
      case 'right':
        return TextAlign.right;
      case 'justify':
      default:
        return TextAlign.justify;
    }
  }

  String _getStringFromTextAlign(TextAlign align) {
    switch (align) {
      case TextAlign.left:
        return 'left';
      case TextAlign.center:
        return 'center';
      case TextAlign.right:
        return 'right';
      case TextAlign.justify:
      default:
        return 'justify';
    }
  }

  // Update methods
  Future<void> updateFontFamily(String value) async {
    _fontFamily = value;
    await _prefs?.setString(_fontFamilyKey, value);
    notifyListeners();
  }

  Future<void> updateFontSize(double value) async {
    _fontSize = value;
    await _prefs?.setDouble(_fontSizeKey, value);
    notifyListeners();
  }

  Future<void> updateLineHeight(double value) async {
    _lineHeight = value;
    await _prefs?.setDouble(_lineHeightKey, value);
    notifyListeners();
  }

  Future<void> updateTextAlign(TextAlign value) async {
    _textAlign = value;
    await _prefs?.setString(_textAlignKey, _getStringFromTextAlign(value));
    notifyListeners();
  }

  Future<void> updateTheme(String value) async {
    _theme = value;
    await _prefs?.setString(_themeKey, value);
    notifyListeners();
  }

  Future<void> updateMargin(double value) async {
    _margin = value;
    await _prefs?.setDouble(_marginKey, value);
    notifyListeners();
  }

  Future<void> resetToDefaults() async {
    _fontFamily = 'Roboto';
    _fontSize = 18.0;
    _lineHeight = 1.5;
    _textAlign = TextAlign.justify;
    _theme = 'light';
    _margin = 16.0;

    if (_prefs != null) {
      await _prefs!.setString(_fontFamilyKey, _fontFamily);
      await _prefs!.setDouble(_fontSizeKey, _fontSize);
      await _prefs!.setDouble(_lineHeightKey, _lineHeight);
      await _prefs!.setString(_textAlignKey, _getStringFromTextAlign(_textAlign));
      await _prefs!.setString(_themeKey, _theme);
      await _prefs!.setDouble(_marginKey, _margin);
    }

    notifyListeners();
  }
}