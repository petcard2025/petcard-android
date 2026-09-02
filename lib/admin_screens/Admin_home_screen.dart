// ============================================================
// ADMIN · HOME / MENÚ
// Punto de entrada al panel de administrador en móvil.
// ============================================================

import 'package:flutter/material.dart';
import 'Admin_alimentacion_screen.dart';
import 'Admin_servicios_screen.dart';
import 'Admin_notificaciones_screen.dart';
import 'Admin_usuarios_screen.dart';
import 'Admin_citas_screen.dart';
import 'Admin_mascotas_screen.dart';
import 'Admin_vacunas_screen.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  static const Color kAzul = Color(0xFF2563EB);

  @override
  Widget build(BuildContext context) {
    final opciones = <_OpcionAdmin>[
      _OpcionAdmin(
        titulo: 'Citas',
        subtitulo: 'Gestionar todas las citas',
        icono: Icons.calendar_today,
        color: const Color(0xFF2563EB),
        builder: (_) => const AdminCitasScreen(),
      ),
      _OpcionAdmin(
        titulo: 'Mascotas',
        subtitulo: 'Gestionar todas las mascotas',
        icono: Icons.pets,
        color: const Color(0xFF10B981),
        builder: (_) => const AdminMascotasScreen(),
      ),
      _OpcionAdmin(
        titulo: 'Vacunas',
        subtitulo: 'Carnet de vacunas',
        icono: Icons.medical_services,
        color: const Color(0xFF7C3AED),
        builder: (_) => const AdminVacunasScreen(),
      ),
      _OpcionAdmin(
        titulo: 'Alimentación',
        subtitulo: 'Planes nutricionales',
        icono: Icons.restaurant_outlined,
        color: const Color(0xFFF97316),
        builder: (_) => const AdminAlimentacionScreen(),
      ),
      _OpcionAdmin(
        titulo: 'Servicios',
        subtitulo: 'Servicios veterinarios',
        icono: Icons.favorite_border,
        color: const Color(0xFFDC2626),
        builder: (_) => const AdminServiciosScreen(),
      ),
      _OpcionAdmin(
        titulo: 'Notificaciones',
        subtitulo: 'Enviar y revisar',
        icono: Icons.notifications_none,
        color: const Color(0xFFCA8A04),
        builder: (_) => const AdminNotificacionesScreen(),
      ),
      _OpcionAdmin(
        titulo: 'Usuarios',
        subtitulo: 'Gestionar cuentas y roles',
        icono: Icons.people_outline,
        color: kAzul,
        builder: (_) => const AdminUsuariosScreen(),
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: kAzul,
        elevation: 0,
        title: const Text(
          'Panel de Administrador',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.logout, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/login');
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gestión del sistema',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            ...opciones.map((o) => _buildTarjeta(context, o)),
            const SizedBox(height: 20),
            Center(
              child: Text(
                '© 2026 PetCard Admin',
                style: TextStyle(fontSize: 12, color: Colors.grey[400]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTarjeta(BuildContext context, _OpcionAdmin o) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: o.builder),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: o.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(o.icono, color: o.color, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        o.titulo,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15.5,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        o.subtitulo,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OpcionAdmin {
  final String titulo;
  final String subtitulo;
  final IconData icono;
  final Color color;
  final Widget Function(BuildContext) builder;

  _OpcionAdmin({
    required this.titulo,
    required this.subtitulo,
    required this.icono,
    required this.color,
    required this.builder,
  });
}