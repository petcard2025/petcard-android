// ============================================================
// MAIN NAV SCREEN - Contenedor con navegación inferior
// Agrupa Inicio, Citas, Mis Mascotas, Alimentación y Perfil en
// una sola pantalla con BottomNavigationBar, para moverse entre
// vistas sin perder la sesión ni volver al login.
// ============================================================

import 'package:flutter/material.dart';
import 'inicio_screen.dart';
import 'citas_screen.dart';
import 'mis_mascotas_screen.dart';
import 'alimentacion_screen.dart';
import 'perfil_screen.dart';
import 'gestion_servicios.dart';
import 'carnet_digital.dart';

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  static const Color kBlue = Color(0xFF2563EB);

  // Índice de la pestaña activa. 0 = Inicio (pantalla principal
  // que se muestra justo después de iniciar sesión)
  int _indiceActual = 0;

  // Cambia de pestaña desde cualquier vista hija (p.ej. los accesos
  // rápidos de Inicio) sin perder la barra de navegación inferior.
  void _cambiarTab(int index) => setState(() => _indiceActual = index);

  // Las 7 vistas principales de la app
  late final List<Widget> _vistas = [
    InicioScreen(onIrATab: _cambiarTab),
    const CitasScreen(),
    const MisMascotasScreen(),
    const AlimentacionScreen(),
    const GestionServiciosScreen(),
    const CarnetDigitalScreen(),
    const PerfilScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack mantiene el estado de cada pantalla al cambiar de pestaña
      body: IndexedStack(
        index: _indiceActual,
        children: _vistas,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indiceActual,
        onTap: _cambiarTab,
        selectedItemColor: kBlue,
        unselectedItemColor: Colors.black45,
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        iconSize: 22,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            activeIcon: Icon(Icons.calendar_month),
            label: 'Citas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pets_outlined),
            activeIcon: Icon(Icons.pets),
            label: 'Mascotas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_outlined),
            activeIcon: Icon(Icons.restaurant),
            label: 'Alimentación',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            activeIcon: Icon(Icons.assignment),
            label: 'Servicios',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.medical_services_outlined),
            activeIcon: Icon(Icons.medical_services),
            label: 'Vacunas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}