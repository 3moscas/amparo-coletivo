import 'package:flutter/material.dart';

class SettingsController extends ChangeNotifier with WidgetsBindingObserver {
  SettingsController();

  ThemeMode _themeMode = ThemeMode.system;
  late Brightness _platformBrightness;

  ThemeMode get themeMode => _themeMode;
  Brightness get platformBrightness => _platformBrightness;

  Future<void> init() async {
    final binding = WidgetsBinding.instance;
    _platformBrightness = binding.platformDispatcher.platformBrightness;
    binding.addObserver(this);
  }

  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) {
      return;
    }
    _themeMode = mode;
    notifyListeners();
  }

  @override
  void didChangePlatformBrightness() {
    final binding = WidgetsBinding.instance;
    final newBrightness = binding.platformDispatcher.platformBrightness;
    if (newBrightness == _platformBrightness) {
      return;
    }
    _platformBrightness = newBrightness;
    if (_themeMode == ThemeMode.system) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
