// ============================================================
// INICIO SCREEN - Vista principal / Dashboard de PetCard
// ============================================================

import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'carnet_digital.dart';

class InicioScreen extends StatefulWidget {
  final void Function(int index)? onIrATab;

  const InicioScreen({super.key, this.onIrATab});

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> {
  // ============================================================
  // COLORES DE LA MARCA
  // ============================================================
  static const Color kBlue = Color(0xFF2563EB);
  static const Color kBlueDark = Color(0xFF1D4ED8);
  static const Color kGreen = Color(0xFF059669);
  static const Color kGreenDark = Color(0xFF047857);

  // ============================================================
  // API Y ESTADO
  // ============================================================
  final ApiService _api = ApiService();

  bool _isLoading = true;
  String? _error;
  String _nombre = '';

  List<Map<String, dynamic>> _mascotas = [];
  List<Map<String, dynamic>> _citas = [];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  // ============================================================
  // CARGA DE DATOS
  // ============================================================
  Future<void> _cargarDatos() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final miUsuario = await _api.obtenerMiUsuario();
      if (miUsuario == null) {
        throw Exception('No hay sesion activa. Vuelve a iniciar sesion.');
      }
      _nombre = miUsuario['Nombre'] ?? miUsuario['nombre'] ?? '';

      final idCliente = await _api.obtenerIdClienteActual();

      _mascotas = await _api.obtenerMascotasPorCliente(idCliente);

      final todasLasCitas = await _api.obtenerCitasAdmin();
      _citas = todasLasCitas
          .where((c) => c['ID_cliente'].toString() == idCliente.toString())
          .toList();
      _citas.sort((a, b) {
        final fechaA = '${a['Fecha'] ?? ''} ${a['Hora'] ?? ''}';
        final fechaB = '${b['Fecha'] ?? ''} ${b['Hora'] ?? ''}';
        return fechaA.compareTo(fechaB);
      });
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      debugPrint('Error cargando datos de inicio: $_error');
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  // ============================================================
  // UTILIDADES
  // ============================================================
  String get _saludo {
    final hora = DateTime.now().hour;
    if (hora < 12) return 'Buenos dias';
    if (hora < 18) return 'Buenas tardes';
    return 'Buenas noches';
  }

  String _generarNumeroCarnet(dynamic idMascota) {
    final id = idMascota?.toString() ?? '';
    String digitos;
    if (id.isEmpty) {
      digitos = '000001';
    } else {
      final relleno = id.padLeft(6, '0');
      digitos = relleno.length > 6
          ? relleno.substring(relleno.length - 6)
          : relleno;
    }
    return 'PET-$digitos';
  }

  Map<String, dynamic>? get _proximaCita {
    for (final cita in _citas) {
      final estado = cita['Estado'] ?? '';
      if (estado == 'Pendiente' || estado == 'Confirmada') {
        return cita;
      }
    }
    return null;
  }

  double _convertirPeso(dynamic pesoRaw) {
    if (pesoRaw == null) return 0.0;
    if (pesoRaw is double) return pesoRaw;
    if (pesoRaw is int) return pesoRaw.toDouble();
    if (pesoRaw is String) {
      return double.tryParse(pesoRaw.replaceAll(',', '.')) ?? 0.0;
    }
    return 0.0;
  }

  // ============================================================
  // NAVEGACION
  // ============================================================
  void _irAMascotas() => widget.onIrATab != null
      ? widget.onIrATab!(2)
      : Navigator.pushNamed(context, '/mis-mascotas');

  void _irACitas() => widget.onIrATab != null
      ? widget.onIrATab!(1)
      : Navigator.pushNamed(context, '/citas');

  void _irAGestionServicios() =>
      Navigator.pushNamed(context, '/gestion-servicios');

  void _irANotificaciones() => Navigator.pushNamed(context, '/notificaciones');

  void _irAPerfil() => widget.onIrATab != null
      ? widget.onIrATab!(4)
      : Navigator.pushNamed(context, '/perfil');

  void _irACarnet(Map<String, dynamic> mascota) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CarnetDigitalScreen(
          idMascota: mascota['ID_mascota'] ?? 0,
          nombreMascota: mascota['Nombre'] ?? 'Sin nombre',
          especie: mascota['Especie'] ?? '',
          raza: mascota['Raza'] ?? '',
          sexo: mascota['Sexo'] ?? '',
          peso: _convertirPeso(mascota['Peso']),
          fechaNacimiento: mascota['Fecha_nacimiento'],
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
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
          : _error != null
          ? _buildErrorState()
          : RefreshIndicator(
        onRefresh: _cargarDatos,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBannerBienvenida(),
              const SizedBox(height: 16),

              // ─── SECCION: MIS CARNETS ───
              if (_mascotas.isNotEmpty) ...[
                _buildSeccionTitulo(
                  icon: Icons.badge,
                  titulo: 'Mis Carnets',
                ),
                const SizedBox(height: 10),
                ..._mascotas.map((mascota) => _buildCarnetCard(mascota)),
                const SizedBox(height: 16),
              ] else ...[
                _buildCarnetVacio(),
                const SizedBox(height: 16),
              ],

              _buildSeccionTitulo(
                icon: Icons.flash_on,
                titulo: 'Acciones Rapidas',
              ),
              const SizedBox(height: 12),
              _buildAccionesRapidas(),
              const SizedBox(height: 24),
              _buildSeccionTitulo(
                icon: Icons.event_available,
                titulo: 'Proxima Cita',
              ),
              const SizedBox(height: 12),
              _buildProximaCita(),
              const SizedBox(height: 24),
              _buildSeccionTitulo(
                icon: Icons.analytics,
                titulo: 'Estadisticas',
              ),
              const SizedBox(height: 12),
              _buildEstadisticas(),
              const SizedBox(height: 32),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // WIDGETS - ESTADO DE ERROR
  // ============================================================
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'No se pudieron cargar tus datos',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              _error ?? '',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _cargarDatos,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kBlue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // WIDGETS - BANNER DE BIENVENIDA (AZUL)
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
                    color: Colors.white.withValues(alpha: 0.2),
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
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        _nombre.isNotEmpty ? _nombre : 'Bienvenido/a',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Tu mascota te esta esperando',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // WIDGETS - CARNET PEQUEÑO (VERDE)
  // ============================================================
  Widget _buildCarnetCard(Map<String, dynamic> mascota) {
    final nombre = mascota['Nombre'] ?? 'Mascota';
    final especie = mascota['Especie'] ?? '';
    final raza = mascota['Raza'] ?? '';
    final id = mascota['ID_mascota'];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [kGreen, kGreenDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: kGreen.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _irACarnet(mascota),
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            // Icono
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.pets, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),

            // Informacion
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    nombre,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '$especie • $raza',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Numero de carnet y flecha
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _generarNumeroCarnet(id),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.chevron_right,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // WIDGETS - CARNET VACIO
  // ============================================================
  Widget _buildCarnetVacio() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [kGreen, kGreenDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: kGreen.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.badge, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Sin mascotas',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Registra tu primera mascota',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _irAMascotas,
            icon: const Icon(Icons.add, color: Colors.white, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // WIDGETS - TITULO DE SECCION
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
  // WIDGETS - ACCIONES RAPIDAS
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
        onTap: () {
          if (_mascotas.isNotEmpty) {
            _irACarnet(_mascotas.first);
          } else {
            _irAMascotas();
          }
        },
      ),
      _Accion(
        icon: Icons.notifications,
        label: 'Recordatorios',
        color: const Color(0xFFF59E0B),
        onTap: _irANotificaciones,
      ),
      _Accion(
        icon: Icons.assignment,
        label: 'Servicios',
        color: const Color(0xFF7C3AED),
        onTap: _irAGestionServicios,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: 118,
      ),
      itemCount: acciones.length,
      itemBuilder: (context, index) => _buildAccionCard(acciones[index]),
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
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accion.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(accion.icon, color: accion.color, size: 22),
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
  // WIDGETS - PROXIMA CITA
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
              color: Colors.black.withValues(alpha: 0.05),
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
              'No tienes citas proximas',
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
            color: Colors.black.withValues(alpha: 0.05),
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
              color: kBlue.withValues(alpha: 0.1),
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
                  '${cita['Nombre_servicio'] ?? 'Cita'}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
                        text: '  ${cita['Fecha'] ?? ''}  ${cita['Hora'] ?? ''}',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                if ((cita['Nombre_mascota'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    '🐾 ${cita['Nombre_mascota']}',
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
  // WIDGETS - ESTADISTICAS
  // ============================================================
  Widget _buildEstadisticas() {
    final citasActivas = _citas
        .where(
          (c) => (c['Estado'] == 'Pendiente' || c['Estado'] == 'Confirmada'),
    )
        .length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
            label: 'Citas proximas',
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
            value: '0',
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
            '© 2026 PetCard. Todos los derechos reservados.',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// MODELO INTERNO DE ACCION
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