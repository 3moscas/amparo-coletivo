import 'package:flutter/material.dart';

class ThemeNotifier extends ChangeNotifier {
  bool _isDarkMode = false;

  // leitura booleana direta (usada em alguns widgets)
  bool get isDarkMode => _isDarkMode;

  // getter compatível com MaterialApp.themeMode
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  // alternativa compatível caso o código antigo use 'currentTheme'
  ThemeMode get currentTheme => themeMode;

  // método para definir explicitamente (compatível com setTheme)
  void setTheme(bool isDark) {
    _isDarkMode = isDark;
    notifyListeners();
  }

  // método para alternar (toggle)
  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }
}
