import 'package:flutter/material.dart';

class SettingsProvider with ChangeNotifier {
  // Default reading settings
  String _fontFamily = 'Roboto';
  double _fontSize = 18.0;
  double _lineHeight = 1.5;
  TextAlign _textAlign = TextAlign.justify;
  String _theme = 'light'; // light, sepia, dark
  double _margin = 16.0;

  // Getters
  String get fontFamily => _fontFamily;
  double get fontSize => _fontSize;
  double get lineHeight => _lineHeight;
  TextAlign get textAlign => _textAlign;
  String get theme => _theme;
  double get margin => _margin;

  // Background color based on theme
  Color get backgroundColor {
    switch (_theme) {
      case 'sepia':
        return const Color(0xFFF6F0E4);
      case 'dark':
        return const Color(0xFF303030);
      case 'light':
      default:
        return const Color(0xFFFFFFFF);
    }
  }

  // Text color based on theme
  Color get textColor {
    return _theme == 'dark' ? const Color(0xFFD8D8D8) : const Color(0xFF303030);
  }

  // Setters with notification
  void updateFontFamily(String value) {
    _fontFamily = value;
    notifyListeners();
  }

  void updateFontSize(double value) {
    _fontSize = value;
    notifyListeners();
  }

  void updateLineHeight(double value) {
    _lineHeight = value;
    notifyListeners();
  }

  void updateTextAlign(TextAlign value) {
    _textAlign = value;
    notifyListeners();
  }

  void updateTheme(String value) {
    _theme = value;
    notifyListeners();
  }

  void updateMargin(double value) {
    _margin = value;
    notifyListeners();
  }

  void resetToDefaults() {
    _fontFamily = 'Roboto';
    _fontSize = 18.0;
    _lineHeight = 1.5;
    _textAlign = TextAlign.justify;
    _theme = 'light';
    _margin = 16.0;
    notifyListeners();
  }
}