import 'package:escapehub_core/escapehub_core.dart';
import 'package:flutter/material.dart';

import 'screens/auth/client_only_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/shell/home_shell.dart';
import 'screens/splash/splash_screen.dart';
import 'theme.dart';

class EscapeHubApp extends StatelessWidget {
  const EscapeHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EscapeHub',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: SessionGate(
        splash: const SplashScreen(),
        login: const LoginScreen(),
        home: (user) => user.isClient ? const HomeShell() : const ClientOnlyScreen(),
      ),
    );
  }
}
