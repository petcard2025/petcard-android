import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'vet_dashboard_screen.dart'; // reutiliza VetColors

class PlanAlimentacion {
  final String id;
  final String? nombreMascota;
  final String? nombreServicio;
  final String? tipoDieta;
  final String? frecuencia;
  final String? horario;
  final num? calorias;
  final String? alergias;
  final String? suplementos;
  final String? comidas;
  final String? fechaInicio;
  final String? fechaFin;
  final String? diagnostico;
  final String? observaciones;
  final String estado;

  PlanAlimentacion({
    required this.id,
    this.nombreMascota,
    this.nombreServicio,
    this.tipoDieta,
    this.frecuencia,
    this.horario,
    this.calorias,
    this.alergias,
    this.suplementos,
    this.comidas,
    this.fechaInicio,
    this.fechaFin,
    this.diagnostico,
    this.observaciones,
    this.estado = 'Pendiente',
  });

  factory PlanAlimentacion.fromJson(Map<String, dynamic> j) {
    return PlanAlimentacion(
      id: j['ID_planAlimentacion'].toString(),
      nombreMascota: j['Nombre_mascota']?.toString(),
      nombreServicio: j['Nombre_servicio']?.toString(),
      tipoDieta: j['Tipo_dieta']?.toString(),
      frecuencia: j['Frecuencia']?.toString(),
      horario: j['Horario']?.toString(),
      calorias: j['Calorias'] is num ? j['Calorias'] as num : num.tryParse('${j['Calorias']}'),
      alergias: j['Alergias']?.toString(),
      suplementos: j['Suplementos']?.toString(),
      comidas: j['Comidas']?.toString(),
      fechaInicio: j['Fecha_inicio']?.toString(),
      fechaFin: j['Fecha_fin']?.toString(),
      diagnostico: j['Diagnostico']?.toString(),
      observaciones: j['Observaciones']?.toString(),
      estado: j['Revision_nutricional']?.toString() ?? 'Pendiente',
    );
  }
}

class OpcionAtendida {
  final String idMascota;
  final String nombreMascota;
  final String idServicio;
  final String nombreServicio;

  OpcionAtendida({
    required this.idMascota,
    required this.nombreMascota,
    required this.idServicio,
    required this.nombreServicio,
  });
}

class VetAlimentacionScreen extends StatefulWidget {
  final String nombreVeterinario;
  final String? idVeterinario;

  const VetAlimentacionScreen({
    super.key,
    required this.nombreVeterinario,
    this.idVeterinario,
  });

  @override
  State<VetAlimentacionScreen> createState() => _VetAlimentacionScreenState();
}

class _VetAlimentacionScreenState extends State<VetAlimentacionScreen> {
  List<PlanAlimentacion> _planes = [];
  List<OpcionAtendida> _opcionesAtendidas = [];
  bool _cargando = false;
  String? _error;
  String _busqueda = '';
  String _filtroEstado = 'Todos';

  final ApiService _api = ApiService();
  final AuthService _auth = AuthService();

  @override
  void initState() {
    super.initState();
    _verificarAcceso();
    _cargarTodo();
  }

  Future<void> _verificarAcceso() async {
    if (!mounted) return;
    final activa = await _auth.haySesionActiva();
    if (!activa && mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  Future<void> _cargarTodo() async {
    if (!mounted) return;
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final planesData = await _api.obtenerPlanesAlimentacion();
      final listadoPlanes = planesData
          .map((e) => PlanAlimentacion.fromJson(e))
          .toList();

      final citasData = await _api.obtenerCitasAdmin();
      final vistos = <String>{};
      final opciones = <OpcionAtendida>[];
      for (final c in citasData) {
        if (widget.idVeterinario != null &&
            c['ID_veterinario']?.toString() != widget.idVeterinario) {
          continue;
        }

        final idMascota = c['ID_mascota']?.toString() ?? '';
        final idServicio = c['ID_servicio']?.toString() ?? '';
        final clave = '$idMascota-$idServicio';
        if (idMascota.isEmpty || vistos.contains(clave)) continue;
        vistos.add(clave);
        opciones.add(OpcionAtendida(
          idMascota: idMascota,
          nombreMascota: c['Nombre_mascota']?.toString() ?? '',
          idServicio: idServicio,
          nombreServicio: c['Nombre_servicio']?.toString() ?? '',
        ));
      }

      if (mounted) {
        setState(() {
          _planes = listadoPlanes;
          _opcionesAtendidas = opciones;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Error al cargar datos nutricionales.');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  List<PlanAlimentacion> get _planesFiltrados {
    return _planes.where((p) {
      final texto = '${p.nombreMascota ?? ''} ${p.tipoDieta ?? ''}'.toLowerCase();
      final coincideTexto = texto.contains(_busqueda.toLowerCase());
      final coincideEstado = _filtroEstado == 'Todos' || p.estado == _filtroEstado;
      return coincideTexto && coincideEstado;
    }).toList();
  }

  Color _colorEstado(String estado) => estado == 'Activo' ? VetColors.green : VetColors.yellow;
  Color _bgEstado(String estado) => estado == 'Activo' ? VetColors.greenBg : VetColors.yellowBg;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: VetColors.blue,
        elevation: 0,
        title: const Text('Alimentación',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: VetColors.green,
        onPressed: _abrirNuevoPlan,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nuevo Plan', style: TextStyle(color: Colors.white)),
      ),
      body: RefreshIndicator(
        onRefresh: _cargarTodo,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Planes nutricionales de las mascotas, ${widget.nombreVeterinario}',
                    style: const TextStyle(fontSize: 12.5, color: VetColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    onChanged: (v) => setState(() => _busqueda = v),
                    decoration: InputDecoration(
                      hintText: 'Buscar por mascota o tipo de dieta...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: VetColors.border),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _filtroEstado,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: VetColors.border),
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'Todos', child: Text('Todos')),
                            DropdownMenuItem(value: 'Activo', child: Text('Activo')),
                            DropdownMenuItem(value: 'Pendiente', child: Text('Pendiente')),
                          ],
                          onChanged: (v) => setState(() => _filtroEstado = v ?? 'Todos'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text('${_planesFiltrados.length} result.',
                          style: const TextStyle(fontSize: 12, color: VetColors.muted)),
                    ],
                  ),
                ],
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: VetColors.redBg, borderRadius: BorderRadius.circular(10)),
                  child: Text('⚠️ $_error', style: const TextStyle(color: VetColors.red)),
                ),
              ),
            Expanded(
              child: _cargando
                  ? const Center(child: CircularProgressIndicator(color: VetColors.blue))
                  : _planesFiltrados.isEmpty
                  ? const Center(
                  child: Text('No se encontraron planes con ese filtro.',
                      style: TextStyle(color: VetColors.muted)))
                  : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                itemCount: _planesFiltrados.length,
                itemBuilder: (context, i) {
                  final plan = _planesFiltrados[i];
                  return _PlanCard(
                    plan: plan,
                    color: _colorEstado(plan.estado),
                    bg: _bgEstado(plan.estado),
                    onTap: () => _abrirDetalle(plan),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: VetColors.muted, fontWeight: FontWeight.w600, fontSize: 13)),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.right,
                style: const TextStyle(color: VetColors.text, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  void _abrirDetalle(PlanAlimentacion plan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Detalle del plan',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: VetColors.text)),
                  const SizedBox(height: 12),
                  _detailRow('Mascota', plan.nombreMascota ?? '—'),
                  _detailRow('Servicio', plan.nombreServicio ?? '—'),
                  _detailRow('Tipo de dieta', plan.tipoDieta ?? '—'),
                  _detailRow('Frecuencia', plan.frecuencia ?? '—'),
                  _detailRow('Horario', plan.horario ?? '—'),
                  _detailRow('Calorías', plan.calorias != null ? '${plan.calorias}' : '—'),
                  _detailRow('Alergias', plan.alergias?.isNotEmpty == true ? plan.alergias! : 'Ninguna'),
                  _detailRow('Suplementos', plan.suplementos ?? '—'),
                  _detailRow('Periodo',
                      '${(plan.fechaInicio ?? '—').toString().substring(0, plan.fechaInicio != null && plan.fechaInicio!.length >= 10 ? 10 : plan.fechaInicio?.length ?? 0)} — ${(plan.fechaFin ?? '—')}'),
                  const SizedBox(height: 10),
                  const Text('Comidas',
                      style: TextStyle(fontSize: 12.5, color: VetColors.muted, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  _textBlock(plan.comidas ?? 'Sin comidas registradas.'),
                  const SizedBox(height: 10),
                  const Text('Diagnóstico',
                      style: TextStyle(fontSize: 12.5, color: VetColors.muted, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  _textBlock(plan.diagnostico ?? 'No registrado.'),
                  const SizedBox(height: 10),
                  const Text('Observaciones',
                      style: TextStyle(fontSize: 12.5, color: VetColors.muted, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  _textBlock(plan.observaciones ?? 'Sin observaciones.'),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _textBlock(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        border: Border.all(color: VetColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(text, style: const TextStyle(fontSize: 13, color: VetColors.text)),
    );
  }

  void _abrirNuevoPlan() {
    String? claveSeleccionada;
    final tipoDietaCtrl = TextEditingController();
    final frecuenciaCtrl = TextEditingController();
    final caloriasCtrl = TextEditingController();
    final horarioCtrl = TextEditingController();
    final alergiasCtrl = TextEditingController();
    final suplementosCtrl = TextEditingController();
    final comidasCtrl = TextEditingController();
    final diagnosticoCtrl = TextEditingController();
    final observacionesCtrl = TextEditingController();
    bool guardando = false;
    String? errorLocal;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Nuevo plan de alimentación',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: VetColors.text)),
                  const SizedBox(height: 14),
                  const Text('Mascota / Servicio atendido',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: claveSeleccionada,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: VetColors.border),
                      ),
                    ),
                    hint: const Text('Selecciona una mascota que hayas atendido'),
                    items: _opcionesAtendidas
                        .map((op) => DropdownMenuItem(
                      value: '${op.idMascota}-${op.idServicio}',
                      child: Text('${op.nombreMascota} — ${op.nombreServicio}',
                          overflow: TextOverflow.ellipsis),
                    ))
                        .toList(),
                    onChanged: (v) => setModalState(() => claveSeleccionada = v),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Solo puedes crear planes para mascotas y servicios de citas que hayas atendido.',
                    style: TextStyle(fontSize: 11.5, color: VetColors.muted),
                  ),
                  const SizedBox(height: 14),
                  _campo('Tipo de dieta', tipoDietaCtrl, hint: 'Balanceada, especial digestiva...'),
                  Row(
                    children: [
                      Expanded(child: _campo('Frecuencia', frecuenciaCtrl, hint: '2 veces al día')),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _campo('Calorías', caloriasCtrl,
                              hint: '1200', keyboardType: TextInputType.number)),
                    ],
                  ),
                  _campo('Horario', horarioCtrl, hint: '8am - 6pm'),
                  _campo('Alergias', alergiasCtrl, hint: 'Ninguna'),
                  _campo('Suplementos', suplementosCtrl, hint: 'Vitaminas'),
                  _campo('Comidas', comidasCtrl, maxLines: 2, hint: 'Desayuno 8:00 400 cal...'),
                  _campo('Diagnóstico nutricional', diagnosticoCtrl, maxLines: 2),
                  _campo('Observaciones', observacionesCtrl, maxLines: 2),
                  if (errorLocal != null) ...[
                    const SizedBox(height: 8),
                    Text(errorLocal!, style: const TextStyle(color: VetColors.red, fontSize: 12.5)),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: guardando ? null : () => Navigator.pop(context),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: guardando
                              ? null
                              : () async {
                            if (claveSeleccionada == null ||
                                tipoDietaCtrl.text.isEmpty ||
                                frecuenciaCtrl.text.isEmpty ||
                                caloriasCtrl.text.isEmpty) {
                              setModalState(() {
                                errorLocal =
                                'Selecciona la mascota y completa dieta, frecuencia y calorías.';
                              });
                              return;
                            }
                            final partes = claveSeleccionada!.split('-');
                            setModalState(() => guardando = true);
                            try {
                              await _api.crearPlanAlimentacion({
                                'ID_mascota': partes[0],
                                'ID_servicio': partes.length > 1 ? partes[1] : null,
                                'Tipo_dieta': tipoDietaCtrl.text,
                                'Frecuencia': frecuenciaCtrl.text,
                                'Calorias': num.tryParse(caloriasCtrl.text) ?? 0,
                                'Horario': horarioCtrl.text,
                                'Alergias': alergiasCtrl.text,
                                'Suplementos': suplementosCtrl.text,
                                'Comidas': comidasCtrl.text,
                                'Diagnostico': diagnosticoCtrl.text,
                                'Observaciones': observacionesCtrl.text,
                                'Revision_nutricional': 'Activo',
                              });
                              await _cargarTodo();
                              if (context.mounted) Navigator.pop(context);
                            } catch (e) {
                              setModalState(() {
                                guardando = false;
                                errorLocal = 'No se pudo crear el plan de alimentación.';
                              });
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: VetColors.green,
                            foregroundColor: Colors.white,
                          ),
                          child: guardando
                              ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Crear plan'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  Widget _campo(String label, TextEditingController controller,
      {String? hint, int maxLines = 1, TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: VetColors.text)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: VetColors.border),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final PlanAlimentacion plan;
  final Color color;
  final Color bg;
  final VoidCallback onTap;

  const _PlanCard({required this.plan, required this.color, required this.bg, required this.onTap});

  String _iniciales(String? nombre) {
    if (nombre == null || nombre.trim().isEmpty) return '—';
    final partes = nombre.trim().split(' ');
    return partes.where((p) => p.isNotEmpty).take(2).map((p) => p[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: VetColors.border),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: VetColors.blueBg,
              child: Text(_iniciales(plan.nombreMascota),
                  style: const TextStyle(color: VetColors.blue, fontWeight: FontWeight.w800, fontSize: 12)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(plan.nombreMascota ?? 'Mascota',
                            style: const TextStyle(fontWeight: FontWeight.w700, color: VetColors.text)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
                        child: Text(plan.estado.toUpperCase(),
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(plan.tipoDieta ?? '—',
                      style: const TextStyle(fontSize: 12.5, color: VetColors.textSecondary)),
                  Text(
                    '${plan.calorias != null ? '${plan.calorias} cal' : '—'} · ${plan.frecuencia ?? '—'}',
                    style: const TextStyle(fontSize: 11.5, color: VetColors.muted),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: VetColors.muted),
          ],
        ),
      ),
    );
  }
}