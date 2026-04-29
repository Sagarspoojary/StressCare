import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'screens/login_screen.dart';

void main() => runApp(const StressCareApp());

class StressCareApp extends StatelessWidget {
  const StressCareApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StressCare',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const LoginScreen(),
    );
  }
}