import 'package:flutter/material.dart';
import 'core/constants/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'home_screen.dart';

/// Root [MaterialApp] widget for the DocuScan application.
///
/// Configures theme, routes, and the initial screen.
class App extends StatelessWidget {
  /// Creates the [App] widget.
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const HomeScreen(),
    );
  }
}
