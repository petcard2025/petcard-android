import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/perfil_screen.dart';
import 'screens/mis_mascotas_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/citas_screen.dart';
import 'screens/main_nav_screen.dart';
import 'screens/inicio_screen.dart';
import 'screens/alimentacion_screen.dart';
import 'screens/admin_alimentacion_screen.dart';
import 'screens/admin_servicios_screen.dart';
import 'screens/Admin_notificaciones_screen.dart';
import 'screens/Admin_usuarios_screen.dart';
import 'screens/ Admin_home_screen.dart';
import 'screens/landing_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://evaanefrbursctyosbbp.supabase.co',
    publishableKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV2YWFuZWZyYnVyc2N0eW9zYmJwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODcwMTQwNjIsImV4cCI6MjEwMjU5MDA2Mn0.c5p9ddkHTiLu5yK2VvezVxxUFvoPk16c5yzn7P_ELZc',                  // ← Reemplaza con tu anon key
  );

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
      initialRoute: '/landing',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/registro': (context) => const RegisterScreen(),
        '/perfil': (context) => const PerfilScreen(),
        '/landing': (context) => const LandingScreen(),
        '/mis-mascotas': (context) => const MisMascotasScreen(),
        '/citas': (context) => const CitasScreen(),
        // '/home' es la vista principal tras iniciar sesión: contiene la
        // barra de navegación inferior con Inicio como pestaña por defecto.
        '/home': (context) => const MainNavScreen(),
        '/inicio': (context) => const InicioScreen(),
        '/alimentacion': (context) => const AlimentacionScreen(),
        '/admin-alimentacion': (context) => const AdminAlimentacionScreen(),
        '/admin-servicios': (context) => const AdminServiciosScreen(),
        '/admin-notificaciones': (context) => const AdminNotificacionesScreen(),
        '/admin-usuarios': (context) => const AdminUsuariosScreen(),
        '/admin': (context) => const AdminHomeScreen(),
        // Pantallas referenciadas desde Inicio pero aún por implementar
        '/carnet': (context) =>
        const _ProximamenteScreen(titulo: 'Carnet de Vacunas'),
        '/notificaciones': (context) =>
        const _ProximamenteScreen(titulo: 'Recordatorios'),
      },
    );
  }
}

// Pantalla temporal para funcionalidades pendientes
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