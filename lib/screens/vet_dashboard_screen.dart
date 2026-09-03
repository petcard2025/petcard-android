import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'vet_citas_screen.dart';
import 'vet_alimentacion_screen.dart';

// Colores compartidos del tema (azul + blanco, igual que login.dart)
class VetColors {
  static const Color blue = Color(0xFF3B82F6);
  static const Color blueDark = Color(0xFF2563EB);
  static const Color blueLight = Color(0xFF60A5FA);
  static const Color blueBg = Color(0xFFEFF6FF);
  static const Color green = Color(0xFF16A34A);
  static const Color greenBg = Color(0xFFDCFCE7);
  static const Color yellow = Color(0xFFCA8A04);
  static const Color yellowBg = Color(0xFFFEF9C3);
  static const Color red = Color(0xFFDC2626);
  static const Color redBg = Color(0xFFFEE2E2);
  static const Color text = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF4B5563);
  static const Color muted = Color(0xFF9CA3AF);
  static const Color border = Color(0xFFE5E7EB);
}

// Modelo simple de una cita (ajusta los nombres de campo según tu API real)
class Cita {
  final String id;
  final String? idVeterinario;
  final String? fecha;
  final String? hora;
  final String? nombreMascota;
  final String? nombreServicio;
  final String? nombreCliente;
  final String? observaciones;

  Cita({
    required this.id,
    this.idVeterinario,
    this.fecha,
    this.hora,
    this.nombreMascota,
    this.nombreServicio,
    this.nombreCliente,
    this.observaciones,
  });

  factory Cita.fromJson(Map<String, dynamic> json) {
    return Cita(
      id: json['ID_cita'].toString(),
      idVeterinario: json['ID_veterinario']?.toString(),
      fecha: json['Fecha']?.toString(),
      hora: json['Hora']?.toString(),
      nombreMascota: json['Nombre_mascota']?.toString(),
      nombreServicio: json['Nombre_servicio']?.toString(),
      nombreCliente: json['Nombre_cliente']?.toString(),
      observaciones: json['Observaciones']?.toString(),
    );
  }

  bool get confirmada => observaciones != null && observaciones!.isNotEmpty;

  DateTime? get fechaDate {
    if (fecha == null || fecha!.length < 10) return null;
    return DateTime.tryParse(fecha!.substring(0, 10));
  }
}

class VetDashboardScreen extends StatefulWidget {
  final String nombreVeterinario;
  final String? idVeterinario;

  const VetDashboardScreen({
    super.key,
    required this.nombreVeterinario,
    this.idVeterinario,
  });

  @override
  State<VetDashboardScreen> createState() => _VetDashboardScreenState();
}

class _VetDashboardScreenState extends State<VetDashboardScreen> {
  List<Cita> _citas = [];
  bool _cargando = false;
  String? _error;
  int _tabIndex = 0;

  final _hoy = DateTime.now();

  @override
  void initState() {
    super.initState();
    _verificarAcceso();
    _cargarCitas();
  }

  Future<void> _verificarAcceso() async {
    if (!mounted) return;
    try {
      // Usamos el singleton para verificar si hay sesión y quién es el usuario
      final activa = await _auth.haySesionActiva();

      if (!activa) {
        if (mounted) Navigator.of(context).pushReplacementNamed('/login');
        return;
      }

      final user = _auth.usuarioActual;
      final rol = user?['Rol']?.toString().toLowerCase();

      if (rol != 'veterinario') {
        print('Acceso denegado. Rol: $rol');
        if (mounted) {
          await _auth.signOut();
          Navigator.of(context).pushReplacementNamed('/login');
        }
      }

      // Intentamos refrescar los datos del servidor de forma silenciosa
      // Si falla (404), no importa, ya tenemos los datos locales
      try {
        await _api.obtenerMiUsuario();
      } catch (e) {
        print('Nota: El servidor no soporta /auth/me (404), usando datos locales.');
      }

    } catch (e) {
      print('Error en verificación: $e');
    }
  }

  bool _esHoy(DateTime? d) {
    if (d == null) return false;
    return d.year == _hoy.year && d.month == _hoy.month && d.day == _hoy.day;
  }

  bool _esFuturaOHoy(DateTime? d) {
    if (d == null) return false;
    final soloFecha = DateTime(d.year, d.month, d.day);
    final hoySoloFecha = DateTime(_hoy.year, _hoy.month, _hoy.day);
    return !soloFecha.isBefore(hoySoloFecha);
  }

  final ApiService _api = ApiService();
  final AuthService _auth = AuthService();

  Future<void> _cargarCitas() async {
    if (!mounted) return;
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final data = await _api.obtenerCitasAdmin();
      final todas = data
          .map((e) => Cita.fromJson(e))
          .toList();

      final propias = todas.where((c) {
        if (c.idVeterinario != null && widget.idVeterinario != null) {
          return c.idVeterinario == widget.idVeterinario;
        }
        return true;
      }).toList();

      if (mounted) setState(() => _citas = propias);
    } catch (e) {
      if (mounted) setState(() => _error = 'Error al conectar con el servidor.');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  List<Cita> get _citasHoy =>
      _citas.where((c) => _esHoy(c.fechaDate)).toList();

  List<Cita> get _citasPendientes => _citas
      .where((c) => !c.confirmada && _esFuturaOHoy(c.fechaDate))
      .toList();

  List<Cita> get _citasConfirmadas => _citas.where((c) => c.confirmada).toList();

  List<Cita> get _proximasCitas {
    final lista = _citas.where((c) => _esFuturaOHoy(c.fechaDate)).toList();
    lista.sort((a, b) {
      final da = '${a.fecha ?? ''} ${a.hora ?? ''}';
      final db = '${b.fecha ?? ''} ${b.hora ?? ''}';
      return da.compareTo(db);
    });
    return lista.take(6).toList();
  }

  String get _iniciales {
    final partes = widget.nombreVeterinario.trim().split(' ');
    return partes
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();
  }

  String get _fechaLarga {
    final formatter = DateFormat("EEEE, d 'de' MMMM 'de' y", 'es');
    final texto = formatter.format(_hoy);
    return texto[0].toUpperCase() + texto.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: VetColors.blue,
        elevation: 0,
        title: Row(
          children: const [
            Icon(Icons.pets, color: Colors.white),
            SizedBox(width: 8),
            Text('PETCARD',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await _auth.signOut();
              if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _cargarCitas,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildBanner(),
              if (_error != null) _buildErrorBanner(),
              const SizedBox(height: 20),
              _buildStatsGrid(),
              const SizedBox(height: 24),
              _buildSectionHeader('Próximas citas', onVerTodas: () {
                setState(() => _tabIndex = 1);
              }),
              const SizedBox(height: 12),
              _buildTimeline(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (index) {
          setState(() => _tabIndex = index);
          if (index == 1) {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => VetCitasScreen(
                nombreVeterinario: widget.nombreVeterinario,
                idVeterinario: widget.idVeterinario,
              ),
            ));
            setState(() => _tabIndex = 0);
          } else if (index == 2) {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => VetAlimentacionScreen(
                nombreVeterinario: widget.nombreVeterinario,
                idVeterinario: widget.idVeterinario,
              ),
            ));
            setState(() => _tabIndex = 0);
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Inicio'),
          NavigationDestination(icon: Icon(Icons.event_note_outlined), selectedIcon: Icon(Icons.event_note), label: 'Mis Citas'),
          NavigationDestination(icon: Icon(Icons.restaurant_outlined), selectedIcon: Icon(Icons.restaurant), label: 'Alimentación'),
        ],
      ),
    );
  }

  Widget _buildBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [VetColors.blueDark, VetColors.blue, VetColors.blueLight],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: VetColors.blue.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.35), width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  _iniciales,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PANEL VETERINARIO',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Dr(a). ${widget.nombreVeterinario}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _fechaLarga,
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => VetCitasScreen(
                    nombreVeterinario: widget.nombreVeterinario,
                    idVeterinario: widget.idVeterinario,
                  ),
                ));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: VetColors.blueDark,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.arrow_forward, size: 18),
              label: const Text('Ver mis citas',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: VetColors.redBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text('⚠️ $_error', style: const TextStyle(color: VetColors.red)),
    );
  }

  Widget _buildStatsGrid() {
    final stats = [
      (_citasHoy.length, 'Citas hoy', Icons.calendar_today, VetColors.blue, VetColors.blueBg),
      (_citasPendientes.length, 'Pendientes', Icons.schedule, VetColors.yellow, VetColors.yellowBg),
      (_citasConfirmadas.length, 'Confirmadas', Icons.check_circle_outline, VetColors.green, VetColors.greenBg),
      (_citas.length, 'Total asignadas', Icons.list_alt, VetColors.blueDark, VetColors.blueBg),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.7,
      children: stats.map((s) {
        final (value, label, icon, color, bg) = s;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: VetColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$value',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                          color: VetColors.text,
                        )),
                    Text(label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: VetColors.muted,
                        )),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onVerTodas}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.w800, fontSize: 16, color: VetColors.text)),
        if (onVerTodas != null)
          TextButton(
            onPressed: onVerTodas,
            child: const Text('Ver todas',
                style: TextStyle(color: VetColors.blue, fontWeight: FontWeight.w600)),
          ),
      ],
    );
  }

  Widget _buildTimeline() {
    if (_cargando) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator(color: VetColors.blue)),
      );
    }
    if (_proximasCitas.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: VetColors.border, style: BorderStyle.solid),
        ),
        alignment: Alignment.center,
        child: const Text('No tienes citas próximas asignadas.',
            style: TextStyle(color: VetColors.muted)),
      );
    }

    return Column(
      children: _proximasCitas.map((cita) {
        final esHoy = _esHoy(cita.fechaDate);
        final d = cita.fechaDate;
        final dia = d != null ? DateFormat('dd').format(d) : '--';
        final mes = d != null ? DateFormat('MMM', 'es').format(d).toUpperCase() : '---';

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: esHoy ? VetColors.blue : VetColors.border,
              width: esHoy ? 1.4 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 42,
                child: Column(
                  children: [
                    Text(dia,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                            color: VetColors.blue)),
                    Text(mes,
                        style: const TextStyle(fontSize: 10, color: VetColors.muted)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(cita.nombreMascota ?? 'Mascota',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, color: VetColors.text)),
                        ),
                        _badge(cita.confirmada ? 'Confirmada' : 'Pendiente',
                            cita.confirmada),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${cita.nombreServicio ?? ''} · ${cita.hora ?? ''} · ${cita.nombreCliente ?? ''}',
                      style: const TextStyle(fontSize: 12.5, color: VetColors.textSecondary),
                    ),
                    if (cita.confirmada && (cita.observaciones ?? '').isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('"${cita.observaciones}"',
                            style: const TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                color: VetColors.green)),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _badge(String texto, bool confirmada) {
    final color = confirmada ? VetColors.green : VetColors.yellow;
    final bg = confirmada ? VetColors.greenBg : VetColors.yellowBg;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(texto,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }
}