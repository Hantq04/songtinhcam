import 'package:flutter/material.dart';
import 'screens/steam_calculator_screen.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService.instance.init();
  runApp(const SteamApp());
}

class SteamApp extends StatelessWidget {
  const SteamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Steam Calculator - SteamDB',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F141D),
        primaryColor: const Color(0xFF1B62C0),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF1B62C0),
          surface: Color(0xFF141C28),
        ),
        fontFamily: 'Segoe UI',
        useMaterial3: true,
      ),
      home: const SteamCalculatorScreen(),
    );
  }
}
