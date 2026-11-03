import 'package:escapehub_core/escapehub_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'screens/login/login_screen.dart';
import 'screens/shell/app_shell.dart';

void main() {
  runApp(const ProviderScope(child: EscapeHubDesktopApp()));
}

class EscapeHubDesktopApp extends StatelessWidget {
  const EscapeHubDesktopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EscapeHub Staff',
      debugShowCheckedModeBanner: false,
      theme: _theme(),
      home: SessionGate(
        splash: const Scaffold(body: Center(child: CircularProgressIndicator())),
        login: const LoginScreen(),
        home: (_) => const AppShell(),
      ),
    );
  }

  ThemeData _theme() {
    final colors = ColorScheme.fromSeed(seedColor: const Color(0xFF3F5A73));
    return ThemeData(
      colorScheme: colors,
      scaffoldBackgroundColor: colors.surfaceContainerLowest,
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface,
        scrolledUnderElevation: 0,
        shape: Border(bottom: BorderSide(color: colors.outlineVariant)),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colors.outlineVariant),
        ),
      ),
      inputDecorationTheme: const InputDecorationThemeData(
        border: OutlineInputBorder(),
        isDense: true,
        errorMaxLines: 3,
        helperMaxLines: 2,
      ),
      dataTableTheme: DataTableThemeData(
        headingTextStyle: TextStyle(fontWeight: FontWeight.w600, color: colors.onSurfaceVariant),
      ),
      dialogTheme: DialogThemeData(backgroundColor: colors.surface),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating, width: 520),
    );
  }
}
