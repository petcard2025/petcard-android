// ============================================================
// MAIN NAV SCREEN - Contenedor con navegación inferior
// Agrupa Citas, Mis Mascotas y Perfil en una sola pantalla
// con BottomNavigationBar, para moverse entre vistas sin
// perder la sesión ni volver al login.
// ============================================================

import 'package:flutter/material.dart';
import 'citas_screen.dart';
import 'alimentacion_screen.dart';
import 'mis_mascotas_screen.dart';
import 'perfil_screen.dart';

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  static const Color kBlue = Color(0xFF3B82F6);

  // Índice de la pestaña activa. 0 = Citas (pantalla principal)
  int _indiceActual = 0;

  // Las 4 vistas principales de la app
  final List<Widget> _vistas = const [
    CitasScreen(),
    AlimentacionScreen(),
    MisMascotasScreen(),
    PerfilScreen(),
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
        onTap: (index) => setState(() => _indiceActual = index),
        selectedItemColor: kBlue,
        unselectedItemColor: Colors.black45,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            activeIcon: Icon(Icons.calendar_month),
            label: 'Citas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_outlined),
            activeIcon: Icon(Icons.restaurant),
            label: 'Alimentación',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pets_outlined),
            activeIcon: Icon(Icons.pets),
            label: 'Mis mascotas',
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