import 'package:flutter/material.dart';
import 'citas_screen.dart';
import '../services/api_service.dart';

class ServiceModel {
  final IconData icon;
  final String title;
  final String subtitle;
  final String status;
  final Color iconBgColor;
  final Color iconColor;
  final Color statusBgColor;
  final Color statusColor;

  ServiceModel({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.iconBgColor,
    required this.iconColor,
    required this.statusBgColor,
    required this.statusColor,
  });
}

class GestionServiciosScreen extends StatefulWidget {
  final void Function(String nombreServicio)? onAgendarServicio;

  const GestionServiciosScreen({super.key, this.onAgendarServicio});

  @override
  State<GestionServiciosScreen> createState() => _GestionServiciosScreenState();
}

class _GestionServiciosScreenState extends State<GestionServiciosScreen> {
  static const Color kBlue = Color(0xFF2563EB);
  static const Color kBlueLight = Color(0xFFDBEAFE);
  static const Color kSuccess = Color(0xFF059669);
  static const Color kSuccessLight = Color(0xFFD1FAE5);
  static const Color kWarning = Color(0xFFF59E0B);
  static const Color kWarningLight = Color(0xFFFEF3C7);
  static const Color kDanger = Color(0xFFE91E63);
  static const Color kDangerLight = Color(0xFFFCE4EC);
  static const Color kPurple = Color(0xFF7C3AED);
  static const Color kPurpleLight = Color(0xFFEDE7F6);
  static const Color kOrange = Color(0xFFF57C00);
  static const Color kOrangeLight = Color(0xFFFFE0B2);

  final ApiService _api = ApiService();

  bool _isLoading = true;
  String? _error;
  String _nombreUsuario = '';

  List<Map<String, dynamic>> _mascotas = [];
  Map<String, dynamic>? _mascotaSeleccionada;

  List<ServiceModel> _servicios = [
    ServiceModel(
      icon: Icons.vaccines,
      title: 'Vacunación',
      subtitle: 'Aplicación de vacunas',
      status: 'Disponible',
      iconBgColor: kBlueLight,
      iconColor: kBlue,
      statusBgColor: kSuccessLight,
      statusColor: kSuccess,
    ),
    ServiceModel(
      icon: Icons.medical_services,
      title: 'Consulta Veterinaria',
      subtitle: 'Revisión médica general',
      status: 'Disponible',
      iconBgColor: kWarningLight,
      iconColor: kWarning,
      statusBgColor: kWarningLight,
      statusColor: kWarning,
    ),
    ServiceModel(
      icon: Icons.brush,
      title: 'Peluquería',
      subtitle: 'Baño y corte',
      status: 'Disponible',
      iconBgColor: kSuccessLight,
      iconColor: kSuccess,
      statusBgColor: kSuccessLight,
      statusColor: kSuccess,
    ),
    ServiceModel(
      icon: Icons.medication,
      title: 'Desparasitación',
      subtitle: 'Tratamiento antiparasitario',
      status: 'Disponible',
      iconBgColor: kDangerLight,
      iconColor: kDanger,
      statusBgColor: kWarningLight,
      statusColor: kWarning,
    ),
    ServiceModel(
      icon: Icons.favorite,
      title: 'Revisión Cardíaca',
      subtitle: 'Chequeo del corazón',
      status: 'Disponible',
      iconBgColor: kOrangeLight,
      iconColor: kOrange,
      statusBgColor: kWarningLight,
      statusColor: kWarning,
    ),
  ];

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
      final usuario = await _api.obtenerMiUsuario();
      _nombreUsuario = usuario?['Nombre'] ?? 'Usuario';

      final mascotas = await _api.obtenerMisMascotas();
      _mascotas = mascotas;

      if (_mascotas.isNotEmpty) {
        _mascotaSeleccionada = _mascotas.first;
      }
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      debugPrint('Error cargando servicios: $_error');
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  // ============================================================
  // AGENDAR CITA
  // ============================================================
  void _irAAgendarCita(ServiceModel service) {
    if (_mascotas.isEmpty) {
      _mostrarAlerta(
        'Sin mascotas',
        'Primero debes registrar una mascota para poder agendar una cita.',
      );
      return;
    }

    if (_mascotaSeleccionada == null) {
      _mostrarAlerta('Atención', 'Selecciona una mascota primero.');
      return;
    }

    if (widget.onAgendarServicio != null) {
      widget.onAgendarServicio!(service.title);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CitasScreen(
          servicioPreseleccionado: service.title,
          abrirFormulario: true,
        ),
      ),
    );
  }

  void _mostrarAlerta(String titulo, String mensaje) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titulo),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SELECTOR DE MASCOTA (bottom sheet)
  // ============================================================
  void _mostrarSelectorMascota() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Selecciona una mascota',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              const Divider(height: 1),
              ..._mascotas.map((m) {
                final seleccionada =
                    _mascotaSeleccionada?['ID_mascota'] == m['ID_mascota'];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: kBlueLight,
                    child: Icon(
                      _iconoEspecie(m['Especie'] ?? ''),
                      color: kBlue,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    m['Nombre'] ?? 'Sin nombre',
                    style: TextStyle(
                      fontWeight:
                      seleccionada ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    '${m['Especie'] ?? ''} • ${m['Raza'] ?? ''}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  trailing: seleccionada
                      ? const Icon(Icons.check_circle, color: kSuccess)
                      : null,
                  onTap: () {
                    setState(() => _mascotaSeleccionada = m);
                    Navigator.pop(context);
                  },
                );
              }).toList(),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  IconData _iconoEspecie(String especie) {
    final e = especie.toLowerCase();
    if (e.contains('perro')) return Icons.pets;
    if (e.contains('gato')) return Icons.pets;
    if (e.contains('ave') || e.contains('pajaro')) return Icons.flight;
    if (e.contains('conejo')) return Icons.cruelty_free;
    return Icons.pets;
  }

  String _calcularEdad(String fechaNacimiento) {
    if (fechaNacimiento.isEmpty) return '—';
    final nacimiento = DateTime.tryParse(fechaNacimiento);
    if (nacimiento == null) return '—';
    final ahora = DateTime.now();
    int anios = ahora.year - nacimiento.year;
    if (ahora.month < nacimiento.month ||
        (ahora.month == nacimiento.month && ahora.day < nacimiento.day)) {
      anios--;
    }
    if (anios < 0) return '—';
    if (anios == 0) return 'Menos de 1 año';
    return '$anios año${anios == 1 ? '' : 's'}';
  }

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Color(0xFF1E293B), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Servicios',
          style: TextStyle(
              color: Color(0xFF1E293B),
              fontWeight: FontWeight.bold,
              fontSize: 20),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              children: [
                const Icon(Icons.account_circle, color: kBlue, size: 28),
                const SizedBox(width: 8),
                Text(
                  _nombreUsuario.isEmpty ? 'Usuario' : _nombreUsuario,
                  style: const TextStyle(
                      color: Color(0xFF1E293B),
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: const Color(0xFFF1F5F9), height: 1.0),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: kBlue))
          : _error != null
          ? _buildErrorState()
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Gestión Médica',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _mascotas.isEmpty
                    ? 'Aún no tienes mascotas registradas'
                    : 'Selecciona un servicio para agendar una cita',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),

              // SECCIÓN DE MASCOTA
              if (_mascotas.isEmpty)
                _buildSinMascotas()
              else
                _buildSelectorMascota(),

              const SizedBox(height: 28),

              // Grid de Servicios
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.70,
                ),
                itemCount: _servicios.length,
                itemBuilder: (context, index) {
                  final s = _servicios[index];
                  return _buildServiceCard(s);
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // WIDGET: SIN MASCOTAS
  // ============================================================
  Widget _buildSinMascotas() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration:
            const BoxDecoration(color: kWarningLight, shape: BoxShape.circle),
            child: const Icon(Icons.pets, color: kWarning, size: 30),
          ),
          const SizedBox(height: 14),
          const Text(
            'No tienes mascotas registradas',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Registra tu primera mascota para poder agendar una cita.',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/mis-mascotas');
            },
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Registrar mascota'),
            style: ElevatedButton.styleFrom(
              backgroundColor: kBlue,
              foregroundColor: Colors.white,
              padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // WIDGET: SELECTOR DE MASCOTA (estilo "Mis Mascotas")
  // ============================================================
  Widget _buildSelectorMascota() {
    final hayVarias = _mascotas.length > 1;
    final mascota = _mascotaSeleccionada;

    final nombre = mascota?['Nombre'] ?? 'Sin nombre';
    final especie = mascota?['Especie'] ?? '';
    final raza = mascota?['Raza'] ?? '';
    final sexo = mascota?['Sexo'] ?? '';
    final peso = mascota?['Peso'];
    final fechaNacimiento = mascota?['Fecha_nacimiento'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fila superior: Avatar + Nombre + Botón Cambiar
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: kBlueLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _iconoEspecie(especie),
                  color: kBlue,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombre,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$especie • $raza',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (hayVarias)
                TextButton.icon(
                  onPressed: _mostrarSelectorMascota,
                  icon: const Icon(Icons.swap_horiz, size: 18, color: kBlue),
                  label: const Text(
                    'Cambiar',
                    style:
                    TextStyle(color: kBlue, fontWeight: FontWeight.w600),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 14),

          // Chips con info extra: Sexo, Peso, Edad
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (sexo.isNotEmpty) _buildChip(sexo),
              if (peso != null) _buildChip('${peso} kg'),
              if (fechaNacimiento != null)
                _buildChip('🎂 ${_calcularEdad(fechaNacimiento.toString())}'),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // WIDGET: ESTADO DE ERROR
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
            ),
            const SizedBox(height: 6),
            Text(
              _error ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
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
  // WIDGET: CHIP
  // ============================================================
  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF64748B),
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  // ============================================================
  // WIDGET: TARJETA DE SERVICIO
  // ============================================================
  Widget _buildServiceCard(ServiceModel service) {
    final puedeAgendar = _mascotas.isNotEmpty;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: puedeAgendar ? () => _irAAgendarCita(service) : null,
        child: Opacity(
          opacity: puedeAgendar ? 1.0 : 0.5,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFF1F5F9)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: service.iconBgColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(service.icon,
                      color: service.iconColor, size: 24),
                ),
                const SizedBox(height: 10),
                Text(
                  service.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  service.subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 13,
                      color: puedeAgendar ? kBlue : Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      puedeAgendar ? 'Agendar' : 'Sin mascotas',
                      style: TextStyle(
                        color: puedeAgendar ? kBlue : Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward,
                      color: puedeAgendar
                          ? const Color(0xFFCBD5E1)
                          : Colors.grey[300],
                      size: 16,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}