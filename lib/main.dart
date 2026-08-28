import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/prueba_screen.dart';
import 'screens/perfil_screen.dart';
import 'screens/mis_mascotas_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/vet_dashboard_screen.dart';
import 'screens/vet_citas_screen.dart';
import 'screens/vet_alimentacion_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Inicializa el idioma español para fechas
  await initializeDateFormatting('es', null);
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
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
        useMaterial3: true,
      ),
      // RUTAS
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/registro': (context) => const RegisterScreen(),
        '/prueba': (context) => const PruebaScreen(),
        '/perfil': (context) => const PerfilScreen(),
        '/mis-mascotas': (context) => const MisMascotasScreen(),
      },
    );
  }
}