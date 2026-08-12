import 'package:flutter/material.dart';
import 'screens/perfil_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PetCard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Segoe UI',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7C3AED),
        ),
        useMaterial3: true,
      ),
      initialRoute: '/perfil',
      routes: {
        '/perfil': (context) => const PerfilScreen(),
        // Agrega aquí tus otras rutas
      },
    );
  }
}