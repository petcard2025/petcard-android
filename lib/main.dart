import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PetCard',
      theme: ThemeData(
        primaryColor: const Color(0xFF3B82F6),
        fontFamily: 'Roboto',
      ),
      home: const LoginScreen(),
    );
  }
}