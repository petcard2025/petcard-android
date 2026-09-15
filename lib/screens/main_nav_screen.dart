// ============================================================
// MAIN NAV SCREEN - Contenedor con navegación inferior
// ============================================================

import 'package:flutter/material.dart';
import 'inicio_screen.dart';
import 'citas_screen.dart';
import 'mis_mascotas_screen.dart';
import 'alimentacion_screen.dart';
import 'perfil_screen.dart';
import 'gestion_servicios.dart';

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  static const Color kBlue = Color(0xFF2563EB);
  static const Color kGrey = Color(0xFF9CA3AF);

  int _indiceActual = 0;

  void _cambiarTab(int index) => setState(() => _indiceActual = index);

  late final List<Widget> _vistas = [
    InicioScreen(onIrATab: _cambiarTab),
    const GestionServiciosScreen(),
    const MisMascotasScreen(),
    const CitasScreen(),
    const AlimentacionScreen(),
    PerfilScreen(onIrATab: _cambiarTab),
  ];

  void _mostrarMenuMas() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Más opciones',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                ),
                const Divider(height: 1),
                _opcionMenu(
                  icon: Icons.calendar_month_outlined,
                  iconActive: Icons.calendar_month,
                  label: 'Citas',
                  index: 3,
                ),
                _opcionMenu(
                  icon: Icons.restaurant_outlined,
                  iconActive: Icons.restaurant,
                  label: 'Alimentación',
                  index: 4,
                ),
                _opcionMenu(
                  icon: Icons.person_outline,
                  iconActive: Icons.person,
                  label: 'Perfil',
                  index: 5,
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _opcionMenu({
    required IconData icon,
    required IconData iconActive,
    required String label,
    required int index,
  }) {
    final seleccionado = _indiceActual == index;
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: seleccionado ? kBlue.withValues(alpha: 0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          seleccionado ? iconActive : icon,
          color: seleccionado ? kBlue : Colors.grey[700],
          size: 22,
        ),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: seleccionado ? FontWeight.bold : FontWeight.w500,
          color: seleccionado ? kBlue : const Color(0xFF1A1A2E),
        ),
      ),
      trailing: seleccionado
          ? const Icon(Icons.check_circle, color: kBlue, size: 20)
          : const Icon(Icons.arrow_forward_ios, size: 14, color: kGrey),
      onTap: () {
        Navigator.pop(context);
        _cambiarTab(index);
      },
    );
  }

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
      },
      child: Scaffold(
        body: IndexedStack(
          index: _indiceActual,
          children: _vistas,
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: _indiceActual.clamp(0, 3),
            onTap: (index) {
              if (index == 3) {
                _mostrarMenuMas();
              } else {
                _cambiarTab(index);
              }
            },
            selectedItemColor: kBlue,
            unselectedItemColor: kGrey,
            type: BottomNavigationBarType.fixed,
            selectedFontSize: 10,
            unselectedFontSize: 10,
            iconSize: 22,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
            elevation: 0,
            backgroundColor: Colors.white,
            selectedIconTheme: const IconThemeData(size: 22),
            unselectedIconTheme: const IconThemeData(size: 20),
            landscapeLayout: BottomNavigationBarLandscapeLayout.centered,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Inicio',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.assignment_outlined),
                activeIcon: Icon(Icons.assignment),
                label: 'Servicios',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.pets_outlined),
                activeIcon: Icon(Icons.pets),
                label: 'Mascotas',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.more_horiz),
                activeIcon: Icon(Icons.more_horiz),
                label: 'Más',
              ),
            ],
          ),
        ),
      ),
    );
  }
}