import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/api_service.dart';
import '../services/notification_service.dart';

class AlimentacionScreen extends StatefulWidget {
  const AlimentacionScreen({super.key});

  @override
  State<AlimentacionScreen> createState() => _AlimentacionScreenState();
}

class _AlimentacionScreenState extends State<AlimentacionScreen> {
  static const Color kBlue = Color(0xFF2563EB);
  static const Color kBlueDark = Color(0xFF1D4ED8);

  final ApiService _api = ApiService();
  List<Map<String, dynamic>> _planes = [];
  List<dynamic> _mascotas = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final token = await _api.obtenerToken();
      if (token == null) {
        await _api.login(
          correo: 'test@petcard.com',
          contrasena: 'test123',
        );
      }

      try {
        final prefs = await SharedPreferences.getInstance();
        final mascotasStr = prefs.getString('petcard_mascotas') ?? '[]';
        _mascotas = jsonDecode(mascotasStr);
      } catch (_) {
        _mascotas = [];
      }

      if (_mascotas.isEmpty) {
        try {
          _mascotas = await _api.obtenerMascotas();
        } catch (_) {}
      }

      _planes = await _api.obtenerPlanesAlimentacion();
    } catch (e) {
      _error = e.toString();
    }
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  String _nombreMascota(int? idMascota) {
    if (idMascota == null) return 'Sin mascota';
    for (final m in _mascotas) {
      final map = m as Map;
      final id = map['id'] ?? map['ID_mascota'];
      if (id != null && id.toString() == idMascota.toString()) {
        return map['nombre'] ?? map['Nombre'] ?? 'Mascota';
      }
    }
    return 'Mascota #$idMascota';
  }

  void _mostrarFormulario({Map<String, dynamic>? plan}) {
    final esEdicion = plan != null;

    final tipoDietaCtrl =
        TextEditingController(text: plan?['Tipo_dieta'] ?? '');
    final frecuenciaCtrl =
        TextEditingController(text: plan?['Frecuencia'] ?? '');
    final alergiasCtrl =
        TextEditingController(text: plan?['Alergias'] ?? '');
    final horarioCtrl =
        TextEditingController(text: plan?['Horario'] ?? '');
    final caloriasCtrl = TextEditingController(
        text: plan?['Calorias']?.toString() ?? '');
    final suplementosCtrl =
        TextEditingController(text: plan?['Suplementos'] ?? '');
    final comidasCtrl =
        TextEditingController(text: plan?['Comidas'] ?? '');
    final fechaInicioCtrl =
        TextEditingController(text: plan?['Fecha_inicio'] ?? '');
    final fechaFinCtrl =
        TextEditingController(text: plan?['Fecha_fin'] ?? '');
    final observacionesCtrl =
        TextEditingController(text: plan?['Observaciones'] ?? '');

    int? mascotaSeleccionada;
    if (esEdicion) {
      mascotaSeleccionada = (plan!['ID_mascota'] as num?)?.toInt();
    } else if (_mascotas.isNotEmpty) {
      final first = _mascotas.first as Map;
      mascotaSeleccionada =
          ((first['id'] ?? first['ID_mascota']) as num?)?.toInt();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.85,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              builder: (ctx, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20),
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        esEdicion
                            ? 'Editar Plan de Alimentación'
                            : 'Nuevo Plan de Alimentación',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Mascota
                      if (!esEdicion) ...[
                        const Text('Mascota',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1A2E))),
                        const SizedBox(height: 8),
                        Container(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              isExpanded: true,
                              value: mascotaSeleccionada,
                              items: _mascotas.map((m) {
                                final map = m as Map;
                                final id = ((map['id'] ??
                                        map['ID_mascota'])
                                    as num?)?.toInt() ?? 0;
                                final nombre = map['nombre'] ??
                                    map['Nombre'] ??
                                    'Mascota';
                                return DropdownMenuItem(
                                    value: id,
                                    child: Text(nombre));
                              }).toList(),
                              onChanged: (val) {
                                setModalState(
                                    () => mascotaSeleccionada = val);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Tipo de dieta
                      _campoFormulario(
                          'Tipo de dieta *', tipoDietaCtrl,
                          hint: 'Ej: Seca, Húmeda, Mixta, Especial'),
                      const SizedBox(height: 12),

                      // Frecuencia
                      _campoFormulario(
                          'Frecuencia', frecuenciaCtrl,
                          hint: 'Ej: 3 veces al día'),
                      const SizedBox(height: 12),

                      // Horario
                      _campoFormulario(
                          'Horario', horarioCtrl,
                          hint: 'Ej: 7:00 AM, 1:00 PM, 7:00 PM'),
                      const SizedBox(height: 12),

                      // Comidas
                      _campoFormulario(
                          'Comidas', comidasCtrl,
                          hint: 'Ej: Alimento seco premium',
                          maxLines: 2),
                      const SizedBox(height: 12),

                      // Calorías
                      _campoFormulario(
                          'Calorías (kcal)', caloriasCtrl,
                          hint: 'Ej: 350',
                          keyboardType: TextInputType.number),
                      const SizedBox(height: 12),

                      // Alergias
                      _campoFormulario(
                          'Alergias', alergiasCtrl,
                          hint: 'Ej: Pollo, Gluten',
                          maxLines: 2),
                      const SizedBox(height: 12),

                      // Suplementos
                      _campoFormulario(
                          'Suplementos', suplementosCtrl,
                          hint: 'Ej: Vitamina B, Omega 3',
                          maxLines: 2),
                      const SizedBox(height: 12),

                      // Fechas
                      Row(
                        children: [
                          Expanded(
                            child: _campoFormulario(
                                'Fecha inicio', fechaInicioCtrl,
                                hint: 'YYYY-MM-DD'),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _campoFormulario(
                                'Fecha fin', fechaFinCtrl,
                                hint: 'YYYY-MM-DD'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Observaciones
                      _campoFormulario(
                          'Observaciones', observacionesCtrl,
                          hint: 'Notas adicionales...',
                          maxLines: 3),
                      const SizedBox(height: 24),

                      // Botones
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(ctx),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                    color: Colors.grey),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Cancelar',
                                  style: TextStyle(
                                      color: Colors.grey)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                if (tipoDietaCtrl.text
                                    .trim()
                                    .isEmpty) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'El tipo de dieta es obligatorio'),
                                      backgroundColor:
                                          Colors.redAccent,
                                    ),
                                  );
                                  return;
                                }

                                try {
                                  if (esEdicion) {
                                    await _api
                                        .actualizarPlanAlimentacion(
                                      plan!['ID_planAlimentacion'],
                                      tipoDieta:
                                          tipoDietaCtrl.text.trim(),
                                      frecuencia:
                                          frecuenciaCtrl.text.trim(),
                                      alergias:
                                          alergiasCtrl.text.trim(),
                                      horario:
                                          horarioCtrl.text.trim(),
                                      calorias: int.tryParse(
                                          caloriasCtrl.text.trim()),
                                      suplementos:
                                          suplementosCtrl.text.trim(),
                                      comidas:
                                          comidasCtrl.text.trim(),
                                      fechaInicio:
                                          fechaInicioCtrl.text.trim(),
                                      fechaFin:
                                          fechaFinCtrl.text.trim(),
                                      observaciones:
                                          observacionesCtrl.text.trim(),
                                    );
                                  } else {
                                    await _api.crearPlanAlimentacion(
                                      idMascota:
                                          mascotaSeleccionada ?? 0,
                                      tipoDieta:
                                          tipoDietaCtrl.text.trim(),
                                      frecuencia:
                                          frecuenciaCtrl.text.trim(),
                                      alergias:
                                          alergiasCtrl.text.trim(),
                                      horario:
                                          horarioCtrl.text.trim(),
                                      calorias: int.tryParse(
                                          caloriasCtrl.text.trim()),
                                      suplementos:
                                          suplementosCtrl.text.trim(),
                                      comidas:
                                          comidasCtrl.text.trim(),
                                      fechaInicio:
                                          fechaInicioCtrl.text.trim(),
                                      fechaFin:
                                          fechaFinCtrl.text.trim(),
                                      observaciones:
                                          observacionesCtrl.text.trim(),
                                    );
                                  }

                                  if (!mounted) return;
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    SnackBar(
                                      content: Text(esEdicion
                                          ? 'Plan actualizado'
                                          : 'Plan creado'),
                                      backgroundColor: kBlue,
                                    ),
                                  );
                                } catch (e) {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    SnackBar(
                                      content:
                                          Text('Error: $e'),
                                      backgroundColor:
                                          Colors.redAccent,
                                    ),
                                  );
                                }

                                _cargarDatos();

                                if (!esEdicion) {
                                  NotificationService().show(
                                    title: 'Plan de alimentacion creado',
                                    body:
                                        '${tipoDietaCtrl.text.trim()} — ${comidasCtrl.text.trim()}',
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kBlue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                  esEdicion ? 'Actualizar' : 'Crear'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _campoFormulario(String label, TextEditingController ctrl,
      {String hint = '', int maxLines = 1, TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A2E),
                fontSize: 13)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kBlue, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmarEliminar(Map<String, dynamic> plan) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar plan'),
        content: Text(
            '¿Eliminar el plan de ${plan['Tipo_dieta'] ?? 'alimentación'}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmar == true) {
      try {
        await _api
            .eliminarPlanAlimentacion(plan['ID_planAlimentacion']);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Plan eliminado'),
            backgroundColor: Colors.redAccent,
          ),
        );
        _cargarDatos();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: kBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            const Icon(Icons.restaurant, color: Colors.white, size: 22),
            const SizedBox(width: 8),
            const Text(
              'Alimentación',
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
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _cargarDatos,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: kBlue))
          : _error != null
              ? _buildError()
              : _planes.isEmpty
                  ? _buildVacia()
                  : _buildLista(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarFormulario(),
        backgroundColor: kBlue,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
            const SizedBox(height: 16),
            const Text(
              'Error de conexión',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E)),
            ),
            const SizedBox(height: 8),
            Text(
              'No se pudieron cargar los planes.\nVerifica que el servidor esté activo.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _cargarDatos,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label:
                  const Text('Reintentar', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: kBlue,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVacia() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: kBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.restaurant,
                  size: 40, color: kBlue),
            ),
            const SizedBox(height: 20),
            const Text(
              'Sin planes de alimentación',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E)),
            ),
            const SizedBox(height: 8),
            Text(
              'Crea un plan de alimentación\npara tu mascota',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLista() {
    return RefreshIndicator(
      onRefresh: _cargarDatos,
      color: kBlue,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _planes.length,
        itemBuilder: (ctx, i) => _buildPlanCard(_planes[i]),
      ),
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan) {
    final idMascota = plan['ID_mascota'];
    final nombreMascota =
        plan['Nombre_mascota'] ?? _nombreMascota(idMascota);
    final tipoDieta = plan['Tipo_dieta'] ?? 'Sin tipo';
    final frecuencia = plan['Frecuencia'] ?? '';
    final horario = plan['Horario'] ?? '';
    final calorias = plan['Calorias'];
    final comidas = plan['Comidas'] ?? '';
    final alergias = plan['Alergias'] ?? '';
    final suplementos = plan['Suplementos'] ?? '';
    final observaciones = plan['Observaciones'] ?? '';

    return Dismissible(
      key: Key('plan_${plan['ID_planAlimentacion']}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        _confirmarEliminar(plan);
        return false;
      },
      child: GestureDetector(
        onTap: () => _mostrarFormulario(plan: plan),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: kBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.pets, color: kBlue, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nombreMascota,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tipoDieta,
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios,
                      size: 14, color: Colors.grey[400]),
                ],
              ),
              if (frecuencia.isNotEmpty || horario.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      if (frecuencia.isNotEmpty) ...[
                        const Icon(Icons.schedule,
                            size: 14, color: kBlue),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            frecuencia,
                            style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF1A1A2E)),
                          ),
                        ),
                      ],
                      if (horario.isNotEmpty) ...[
                        if (frecuencia.isNotEmpty)
                          Container(
                            width: 1,
                            height: 14,
                            color: Colors.grey[300],
                            margin: const EdgeInsets.symmetric(
                                horizontal: 8),
                          ),
                        const Icon(Icons.access_time,
                            size: 14, color: kBlue),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            horario,
                            style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF1A1A2E)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  if (calorias != null)
                    _chipInfo(Icons.local_fire_department,
                        '${calorias} kcal', Colors.orange),
                  if (comidas.isNotEmpty)
                    _chipInfo(Icons.restaurant_menu, comidas, kBlue),
                  if (alergias.isNotEmpty)
                    _chipInfo(Icons.warning_amber_rounded,
                        'Alergias: $alergias', Colors.redAccent),
                  if (suplementos.isNotEmpty)
                    _chipInfo(
                        Icons.medication, suplementos, Colors.teal),
                ],
              ),
              if (observaciones.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  observaciones,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _chipInfo(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
