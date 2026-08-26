import 'package:flutter/material.dart';
import 'package:petcard/screens/perfil_screen.dart';
import 'package:petcard/screens/mis_mascotas_screen.dart';
import 'package:petcard/screens/login_screen.dart';
import 'package:petcard/screens/register_screen.dart';
import 'package:petcard/screens/citas_screen.dart';
import 'package:petcard/screens/main_nav_screen.dart';
import 'package:petcard/screens/inicio_screen.dart';
import 'package:petcard/screens/alimentacion_screen.dart';
import 'package:petcard/screens/landing_screen.dart';

// ============================================================
// IMPORTS DE ADMIN
// ============================================================
import 'package:petcard/admin_screens/Admin_home_screen.dart';
import 'package:petcard/admin_screens/Admin_alimentacion_screen.dart';
import 'package:petcard/admin_screens/Admin_servicios_screen.dart';
import 'package:petcard/admin_screens/Admin_notificaciones_screen.dart';
import 'package:petcard/admin_screens/Admin_usuarios_screen.dart';
import 'package:petcard/admin_screens/Admin_citas_screen.dart';
import 'package:petcard/admin_screens/Admin_mascotas_screen.dart';
import 'package:petcard/admin_screens/Admin_vacunas_screen.dart';


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
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
        useMaterial3: true,
      ),
      initialRoute: '/landing',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/registro': (context) => const RegisterScreen(),
        '/perfil': (context) => const PerfilScreen(),
        '/landing': (context) => const LandingScreen(),
        '/mis-mascotas': (context) => const MisMascotasScreen(),
        '/citas': (context) => const CitasScreen(),
        '/home': (context) => const MainNavScreen(),
        '/inicio': (context) => const InicioScreen(),
        '/alimentacion': (context) => const AlimentacionScreen(),
        '/carnet': (context) =>
        const _ProximamenteScreen(titulo: 'Carnet de Vacunas'),
        '/notificaciones': (context) =>
        const _ProximamenteScreen(titulo: 'Recordatorios'),

        // ============================================================
        // RUTAS DE ADMIN
        // ============================================================
        '/admin': (context) => const AdminHomeScreen(),
        '/admin-alimentacion': (context) => const AdminAlimentacionScreen(),
        '/admin-servicios': (context) => const AdminServiciosScreen(),
        '/admin-notificaciones': (context) => const AdminNotificacionesScreen(),
        '/admin-usuarios': (context) => const AdminUsuariosScreen(),
        '/admin-citas': (context) => const AdminCitasScreen(),
        '/admin-mascotas': (context) => const AdminMascotasScreen(),
        '/admin-vacunas': (context) => const AdminVacunasScreen(),
      },
    );
  }
}

class _ProximamenteScreen extends StatelessWidget {
  final String titulo;
  const _ProximamenteScreen({required this.titulo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2563EB),
        elevation: 0,
        title: const Text(
          'PETCARD',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.construction, size: 64, color: Color(0xFF2563EB)),
            const SizedBox(height: 16),
            Text(
              titulo,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Próximamente',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}