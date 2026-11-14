import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'services/notificaciones.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GymApp());
  Notificaciones.instancia.iniciar();
}

class GymApp extends StatelessWidget {
  const GymApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gym Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}