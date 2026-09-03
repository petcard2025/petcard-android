import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:petcard/screens/prueba_screen.dart';
import 'package:petcard/screens/perfil_screen.dart';
import 'package:petcard/screens/mis_mascotas_screen.dart';
import 'package:petcard/screens/login_screen.dart';
import 'package:petcard/screens/register_screen.dart';
import 'package:petcard/screens/citas_screen.dart';
import 'package:petcard/screens/main_nav_screen.dart';
import 'package:petcard/screens/inicio_screen.dart';
import 'package:petcard/screens/alimentacion_screen.dart';
import 'package:petcard/screens/landing_screen.dart';
import 'package:petcard/screens/gestion_servicios.dart';
import 'package:petcard/screens/carnet_digital.dart';
import 'package:petcard/screens/notificaciones_screen.dart';

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


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://evaanefrbursctyosbbp.supabase.co',
    publishableKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV2YWFuZWZyYnVyc2N0eW9zYmJwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODcwMTQwNjIsImV4cCI6MjEwMjU5MDA2Mn0.c5p9ddkHTiLu5yK2VvezVxxUFvoPk16c5yzn7P_ELZc',
  );

  // Inicializa el idioma español para fechas (usado en las pantallas de veterinario)
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
        '/carnet': (context) => const CarnetDigitalScreen(),
        '/gestion-servicios': (context) => const GestionServiciosScreen(),
        '/notificaciones': (context) => const NotificacionesScreen(),
        '/prueba': (context) => const PruebaScreen(),

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