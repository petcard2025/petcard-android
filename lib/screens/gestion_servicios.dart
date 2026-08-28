import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

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
  const GestionServiciosScreen({super.key});

  @override
  State<GestionServiciosScreen> createState() => _GestionServiciosScreenState();
}

class _GestionServiciosScreenState extends State<GestionServiciosScreen> {
  static const Color kBlue = Color(0xFF3B82F6);
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

  bool _isLoading = true;
  Map<String, dynamic>? _mascota;
  String _nombreUsuario = 'Carlitos Pinzón';

  List<ServiceModel> _servicios = [
    ServiceModel(
      icon: Icons.vaccines,
      title: 'Vacunación',
      subtitle: 'Última: 10 jun 2026',
      status: 'Completado',
      iconBgColor: kBlueLight,
      iconColor: kBlue,
      statusBgColor: kSuccessLight,
      statusColor: kSuccess,
    ),
    ServiceModel(
      icon: Icons.medical_services,
      title: 'Consulta Veterinaria',
      subtitle: 'Próxima: 15 sep 2026',
      status: 'Pendiente',
      iconBgColor: kWarningLight,
      iconColor: kWarning,
      statusBgColor: kWarningLight,
      statusColor: kWarning,
    ),
    ServiceModel(
      icon: Icons.brush,
      title: 'Peluquería',
      subtitle: 'Última: 01 ago 2026',
      status: 'Completado',
      iconBgColor: const Color(0xFFD1FAE5),
      iconColor: const Color(0xFF059669),
      statusBgColor: kSuccessLight,
      statusColor: kSuccess,
    ),
    ServiceModel(
      icon: Icons.medication,
      title: 'Desparasitación',
      subtitle: 'Próxima: 20 oct 2026',
      status: 'Pendiente',
      iconBgColor: kDangerLight,
      iconColor: kDanger,
      statusBgColor: kWarningLight,
      statusColor: kWarning,
    ),
    ServiceModel(
      icon: Icons.favorite,
      title: 'Revisión Cardíaca',
      subtitle: 'Próxima: 05 nov 2026',
      status: 'Pendiente',
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

  Future<void> _cargarDatos() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final usuarioStr = prefs.getString('petcard_usuario_actual');
      if (usuarioStr != null) {
        final usuario = jsonDecode(usuarioStr);
        final nombre = usuario['Nombre'] ?? usuario['nombre'] ?? '';
        final apellido = usuario['Apellido'] ?? usuario['apellido'] ?? '';
        setState(() {
          _nombreUsuario = '$nombre $apellido'.trim();
          if (_nombreUsuario.isEmpty) _nombreUsuario = 'Carlitos Pinzón';
        });
      }

      final mascotasStr = prefs.getString('petcard_mascotas') ?? '[]';
      final List<dynamic> mascotas = jsonDecode(mascotasStr);
      if (mascotas.isNotEmpty) {
        setState(() {
          _mascota = Map<String, dynamic>.from(mascotas.first);
        });
      }
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _mostrarDialogoNuevoServicio() {
    final titleController = TextEditingController();
    final subtitleController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Nuevo Servicio', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Nombre del Servicio', hintText: 'Ej. Limpieza Dental'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: subtitleController,
              decoration: const InputDecoration(labelText: 'Fecha/Nota', hintText: 'Ej. Próxima: 20 Dic'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kBlue, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () {
              if (titleController.text.isNotEmpty) {
                setState(() {
                  _servicios.add(ServiceModel(
                    icon: Icons.add_task,
                    title: titleController.text,
                    subtitle: subtitleController.text.isEmpty ? 'Pendiente' : subtitleController.text,
                    status: 'Nuevo',
                    iconBgColor: kPurpleLight,
                    iconColor: kPurple,
                    statusBgColor: kWarningLight,
                    statusColor: kWarning,
                  ));
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1E293B), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Servicios',
          style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              children: [
                const Icon(Icons.account_circle, color: kBlue, size: 28),
                const SizedBox(width: 8),
                Text(
                  _nombreUsuario,
                  style: const TextStyle(color: Color(0xFF1E293B), fontSize: 13, fontWeight: FontWeight.w600),
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
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Gestión Médica',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFF0F172A), letterSpacing: -0.5),
              ),
              const SizedBox(height: 4),
              Text(
                'Historial de atenciones para ${_mascota?['nombre'] ?? 'Benyi'}',
                style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 24),

              // Mascota Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(color: kBlueLight, shape: BoxShape.circle),
                      child: const Icon(Icons.pets, color: kBlue, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _mascota?['nombre'] ?? 'Benyi',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              _buildChip('${_mascota?['raza'] ?? 'Frespuder'}'),
                              const SizedBox(width: 8),
                              _buildChip('${_mascota?['edad'] ?? '10 años'}'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(color: kSuccessLight, borderRadius: BorderRadius.circular(100)),
                      child: const Text('Activa', style: TextStyle(color: kSuccess, fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Grid de Servicios
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.82,
                ),
                itemCount: _servicios.length,
                itemBuilder: (context, index) {
                  final s = _servicios[index];
                  return _buildServiceCard(s);
                },
              ),
              const SizedBox(height: 32),

              // Botón Agregar
              Container(
                width: double.infinity,
                height: 58,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: kBlue.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6)),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: _mostrarDialogoNuevoServicio,
                  icon: const Icon(Icons.add_circle_outline, color: Colors.white, size: 24),
                  label: const Text('Agregar Nuevo Servicio', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kBlue,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildServiceCard(ServiceModel service) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: service.iconBgColor, borderRadius: BorderRadius.circular(16)),
                child: Icon(service.icon, color: service.iconColor, size: 26),
              ),
              const SizedBox(height: 14),
              Text(
                service.title,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                service.subtitle,
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w400),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: service.statusBgColor, borderRadius: BorderRadius.circular(8)),
                child: Text(
                  service.status.toUpperCase(),
                  style: TextStyle(color: service.statusColor, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                ),
              ),
            ],
          ),
          const Positioned(top: 0, right: 0, child: Icon(Icons.arrow_forward, color: Color(0xFFCBD5E1), size: 18)),
        ],
      ),
    );
  }
}
