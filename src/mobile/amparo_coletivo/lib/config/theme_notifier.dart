import 'package:flutter/material.dart';

class ThemeNotifier extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  // leitura booleana direta (usada em alguns widgets)
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  // getter compatível com MaterialApp.themeMode
  ThemeMode get themeMode => _themeMode;

  // alternativa compatível caso o código antigo use 'currentTheme'
  ThemeMode get currentTheme => _themeMode;

  // método para definir explicitamente usando ThemeMode
  void setTheme(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  // método para definir usando bool (compatibilidade com código antigo)
  void setThemeBool(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  // método para alternar (toggle)
  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}
