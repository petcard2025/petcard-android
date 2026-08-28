// ============================================================
// INICIO SCREEN - Vista principal / Dashboard de PetCard
// ============================================================

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/notification_service.dart';

class InicioScreen extends StatefulWidget {
  const InicioScreen({super.key});

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> {
  // ============================================================
  // COLORES DE LA MARCA
  // ============================================================
  static const Color kBlue = Color(0xFF2563EB);
  static const Color kBlueDark = Color(0xFF1D4ED8);

  // ============================================================
  // ESTADO
  // ============================================================
  bool _isLoading = true;
  String _nombre = '';
  String _apellido = '';

  List<dynamic> _mascotas = [];
  List<dynamic> _citas = [];
  int _notifNoLeidas = 0;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  // ============================================================
  // CARGA DE DATOS (SharedPreferences del equipo)
  // ============================================================
  Future<void> _cargarDatos() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Usuario actual
      final usuarioStr = prefs.getString('petcard_usuario_actual');
      if (usuarioStr != null) {
        final Map<String, dynamic> usuario = jsonDecode(usuarioStr);
        _nombre = usuario['Nombre'] ?? usuario['nombre'] ?? '';
        _apellido = usuario['Apellido'] ?? usuario['apellido'] ?? '';
      }

      // Mascotas
      final mascotasStr = prefs.getString('petcard_mascotas') ?? '[]';
      _mascotas = jsonDecode(mascotasStr);

      // Citas
      final citasStr = prefs.getString('petcard_citas') ?? '[]';
      _citas = jsonDecode(citasStr);
      _citas.sort((a, b) {
        final fechaA = (a as Map)['fechaHoraOrden'] ?? '';
        final fechaB = (b as Map)['fechaHoraOrden'] ?? '';
        return fechaA.toString().compareTo(fechaB.toString());
      });

      _notifNoLeidas = await NotificationService().getNoLeidas();
    } catch (e) {
      debugPrint('Error cargando datos de inicio: $e');
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  // ============================================================
  // UTILIDADES
  // ============================================================
  String get _saludo {
    final hora = DateTime.now().hour;
    if (hora < 12) return 'Buenos días';
    if (hora < 18) return 'Buenas tardes';
    return 'Buenas noches';
  }

  String get _numeroCarnet {
    final primer =
        _mascotas.isNotEmpty ? (_mascotas.first as Map)['id'].toString() : '000001';
    if (primer.length >= 6) return 'PET-${primer.substring(primer.length - 6)}';
    return 'PET-${primer.padLeft(6, '0')}';
  }

  Map? get _proximaCita {
    for (final cita in _citas) {
      final estado = (cita as Map)['estado'] ?? '';
      if (estado == 'Pendiente' || estado == 'Confirmada') {
        return cita;
      }
    }
    return null;
  }

  // ============================================================
  // NAVEGACIÓN (rutas usadas por el equipo)
  // ============================================================
  void _irAMascotas() => Navigator.pushNamed(context, '/mis-mascotas');
  void _irACitas() => Navigator.pushNamed(context, '/citas');
  void _irACarnet() => Navigator.pushNamed(context, '/carnet');
  void _irANotificaciones() => Navigator.pushNamed(context, '/notificaciones');
  void _irAPerfil() => Navigator.pushNamed(context, '/perfil');
  void _irAAlimentacion() => Navigator.pushNamed(context, '/alimentacion');

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: kBlue,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.pets, color: Colors.white, size: 24),
            const SizedBox(width: 8),
            const Text(
              'PETCARD',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: _irANotificaciones,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ==========================================================
                  // BANNER DE BIENVENIDA
                  // ==========================================================
                  _buildBannerBienvenida(),

                  const SizedBox(height: 16),

                  // ==========================================================
                  // CARNET DESTACADO
                  // ==========================================================
                  _buildCarnetDestacado(),

                  const SizedBox(height: 24),

                  // ==========================================================
                  // ACCIONES RÁPIDAS
                  // ==========================================================
                  _buildSeccionTitulo(
                    icon: Icons.flash_on,
                    titulo: 'Acciones Rápidas',
                  ),
                  const SizedBox(height: 12),
                  _buildAccionesRapidas(),

                  const SizedBox(height: 24),

                  // ==========================================================
                  // PRÓXIMA CITA
                  // ==========================================================
                  _buildSeccionTitulo(
                    icon: Icons.event_available,
                    titulo: 'Próxima Cita',
                  ),
                  const SizedBox(height: 12),
                  _buildProximaCita(),

                  const SizedBox(height: 24),

                  // ==========================================================
                  // ESTADÍSTICAS
                  // ==========================================================
                  _buildSeccionTitulo(
                    icon: Icons.analytics,
                    titulo: 'Estadísticas',
                  ),
                  const SizedBox(height: 12),
                  _buildEstadisticas(),

                  const SizedBox(height: 32),

                  // ==========================================================
                  // FOOTER
                  // ==========================================================
                  _buildFooter(),
                ],
              ),
            ),
    );
  }

  // ============================================================
  // WIDGETS - BANNER DE BIENVENIDA
  // ============================================================
  Widget _buildBannerBienvenida() {
    return InkWell(
      onTap: _irAPerfil,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [kBlue, kBlueDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$_saludo,',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        _nombre.isNotEmpty ? '$_nombre $_apellido' : 'Bienvenido/a',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Tu mascota te está esperando',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // WIDGETS - CARNET DESTACADO
  // ============================================================
  Widget _buildCarnetDestacado() {
    final mascota = _mascotas.isNotEmpty ? _mascotas.first as Map : null;

    return InkWell(
      onTap: _irACarnet,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [kBlue, kBlueDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: kBlue.withOpacity(0.3),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.badge, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 10),
                const Text(
                  'CARNET PetCard',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.nfc, color: Colors.white70, size: 22),
              ],
            ),
            const SizedBox(height: 16),
            if (mascota != null) ...[
              Text(
                '${mascota['nombre'] ?? 'Mascota'}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${mascota['especie'] ?? ''} • ${mascota['raza'] ?? ''}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 14,
                ),
              ),
            ] else ...[
              const Text(
                'Tu carnet digital',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Registra tu primera mascota para generar tu carnet',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 13,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _numeroCarnet,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
                const Text(
                  'Ver carnet ›',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // WIDGETS - TÍTULO DE SECCIÓN
  // ============================================================
  Widget _buildSeccionTitulo({
    required IconData icon,
    required String titulo,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          titulo,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A2E),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // WIDGETS - ACCIONES RÁPIDAS
  // ============================================================
  Widget _buildAccionesRapidas() {
    final acciones = [
      _Accion(
        icon: Icons.pets,
        label: 'Mis Mascotas',
        color: kBlue,
        onTap: _irAMascotas,
      ),
      _Accion(
        icon: Icons.calendar_today,
        label: 'Programar Cita',
        color: kBlue,
        onTap: _irACitas,
      ),
      _Accion(
        icon: Icons.medical_services,
        label: 'Carnet de Vacunas',
        color: const Color(0xFF10B981),
        onTap: _irACarnet,
      ),
      _Accion(
        icon: Icons.restaurant,
        label: 'Alimentación',
        color: const Color(0xFFF59E0B),
        onTap: _irAAlimentacion,
      ),
      _Accion(
        icon: Icons.notifications,
        label: 'Recordatorios',
        color: const Color(0xFF8B5CF6),
        onTap: _irANotificaciones,
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.25,
      children: acciones
          .map(
            (accion) => _buildAccionCard(accion),
          )
          .toList(),
    );
  }

  Widget _buildAccionCard(_Accion accion) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        onTap: accion.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: accion.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child:
                        Icon(accion.icon, color: accion.color, size: 22),
                  ),
                  if (accion.label == 'Recordatorios' &&
                      _notifNoLeidas > 0)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$_notifNoLeidas',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                accion.label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // WIDGETS - PRÓXIMA CITA
  // ============================================================
  Widget _buildProximaCita() {
    final cita = _proximaCita;

    if (cita == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
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
        child: Column(
          children: [
            Icon(Icons.event_busy, size: 40, color: Colors.grey[300]),
            const SizedBox(height: 8),
            Text(
              'No tienes citas próximas',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Programa una cita para tu mascota',
              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: kBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.event_available,
              color: kBlue,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${cita['servicio'] ?? 'Cita'}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 4),
                Text.rich(
                  TextSpan(
                    children: [
                      WidgetSpan(
                        child: Icon(
                          Icons.calendar_today,
                          size: 13,
                          color: Colors.grey[500],
                        ),
                      ),
                      TextSpan(
                        text: '  ${cita['fecha'] ?? ''}  ${cita['hora'] ?? ''}',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                if ((cita['mascota'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    '🐾 ${cita['mascota']}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
        ],
      ),
    );
  }

  // ============================================================
  // WIDGETS - ESTADÍSTICAS
  // ============================================================
  Widget _buildEstadisticas() {
    final citasActivas = _citas
        .where(
          (c) =>
              (c['estado'] == 'Pendiente' || c['estado'] == 'Confirmada'),
        )
        .length;

    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        children: [
          _buildEstadisticaRow(
            label: 'Mascotas registradas',
            value: '${_mascotas.length}',
            icon: Icons.pets,
          ),
          _buildEstadisticaRow(
            label: 'Citas próximas',
            value: '$citasActivas',
            icon: Icons.event_available,
          ),
          _buildEstadisticaRow(
            label: 'Total de citas',
            value: '${_citas.length}',
            icon: Icons.calendar_today,
          ),
          _buildEstadisticaRow(
            label: 'Recordatorios',
            value: '$_notifNoLeidas',
            icon: Icons.notifications,
          ),
        ],
      ),
    );
  }

  Widget _buildEstadisticaRow({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: kBlue),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A2E),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // WIDGETS - FOOTER
  // ============================================================
  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        children: [
          Icon(Icons.pets, color: Colors.grey, size: 20),
          SizedBox(height: 8),
          Text(
            '© 2024 PetCard. Todos los derechos reservados.',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// MODELO INTERNO DE ACCIÓN
// ============================================================
class _Accion {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _Accion({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}