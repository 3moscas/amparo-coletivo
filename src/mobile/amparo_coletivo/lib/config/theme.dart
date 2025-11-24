import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

class AppTheme {
  const AppTheme._();

  static const Color _seedColor = Colors.green;

  static ThemeData light({ColorScheme? dynamicScheme}) {
    final scheme = dynamicScheme ??
        ColorScheme.fromSeed(
          seedColor: _seedColor,
          brightness: Brightness.light,
        );
    return _buildTheme(scheme);
  }

  static ThemeData dark({ColorScheme? dynamicScheme}) {
    final scheme = dynamicScheme ??
        ColorScheme.fromSeed(
          seedColor: _seedColor,
          brightness: Brightness.dark,
        );
    return _buildTheme(scheme);
  }

  static ThemeData _buildTheme(ColorScheme colorScheme) {
    return ThemeData(
      colorScheme: colorScheme,
      extensions: const [SkeletonizerConfigData()],
    );
  }
}
