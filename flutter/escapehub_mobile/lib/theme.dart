import 'package:flutter/material.dart';

const _accent = Color(0xFF3B6378);

ThemeData buildTheme() {
  final colors = ColorScheme.fromSeed(seedColor: _accent, dynamicSchemeVariant: DynamicSchemeVariant.tonalSpot);
  final shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
    side: BorderSide(color: colors.outlineVariant),
  );
  return ThemeData(
    colorScheme: colors,
    scaffoldBackgroundColor: colors.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: colors.surface,
      foregroundColor: colors.onSurface,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(elevation: 0, color: colors.surfaceContainerLow, shape: shape, margin: EdgeInsets.zero),
    inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder(), errorMaxLines: 3),
    navigationBarTheme: NavigationBarThemeData(backgroundColor: colors.surfaceContainer),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}
