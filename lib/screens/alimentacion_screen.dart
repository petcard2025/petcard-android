// ============================================================
// ALIMENTACION SCREEN - Plan nutricional de las mascotas
// Mismo diseño (selector de mascota, tabs, stats, tarjetas)
// que la sección "Alimentación" de la web de PetCard,
// adaptado a móvil. Color principal: azul (igual que el resto
// de la app), no morado.
// ============================================================

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AlimentacionScreen extends StatefulWidget {
  const AlimentacionScreen({super.key});

  @override
  State<AlimentacionScreen> createState() => _AlimentacionScreenState();
}

class _AlimentacionScreenState extends State<AlimentacionScreen> {
  // ============================================================
  // COLORES (igual que el resto de la app)
  // ============================================================
  static const Color kAzul = Color(0xFF2563EB);
  static const Color kAzulBg = Color(0xFFEFF6FF);
  static const Color kNaranja = Color(0xFFF97316);
  static const Color kNaranjaBg = Color(0xFFFFF7ED);
  static const Color kVerde = Color(0xFF16A34A);
  static const Color kVerdeBg = Color(0xFFDCFCE7);
  static const Color kRojo = Color(0xFFDC2626);
  static const Color kRojoBg = Color(0xFFFEE2E2);
  static const Color kAmarillo = Color(0xFFCA8A04);
  static const Color kAmarilloBg = Color(0xFFFEF9C3);

  // ============================================================
  // VARIABLES DE ESTADO
  // ============================================================
  bool _isLoading = true;
  List<Map<String, dynamic>> _mascotas = [];
  List<Map<String, dynamic>> _planes = [];
  String? _mascotaSeleccionada;
  int _tabIndex = 0; // 0 = Plan, 1 = Historial, 2 = Alternativas

  // Controladores del formulario de plan nutricional
  final TextEditingController _tipoDietaController = TextEditingController();
  final TextEditingController _caloriasController = TextEditingController();
  final TextEditingController _frecuenciaController = TextEditingController();
  final TextEditingController _horarioController = TextEditingController();
  final TextEditingController _comidasController = TextEditingController();
  final TextEditingController _suplementosController = TextEditingController();
  final TextEditingController _alergiasController = TextEditingController();
  final TextEditingController _diagnosticoController = TextEditingController();
  final TextEditingController _observacionesController = TextEditingController();

  // ============================================================
  // CICLO DE VIDA
  // ============================================================
  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  @override
  void dispose() {
    _tipoDietaController.dispose();
    _caloriasController.dispose();
    _frecuenciaController.dispose();
    _horarioController.dispose();
    _comidasController.dispose();
    _suplementosController.dispose();
    _alergiasController.dispose();
    _diagnosticoController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  // ============================================================
  // CARGA DE DATOS
  // ============================================================
  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();

      final mascotasStr = prefs.getString('petcard_mascotas') ?? '[]';
      final List<dynamic> mascotas = jsonDecode(mascotasStr);
      _mascotas = mascotas.map((m) => Map<String, dynamic>.from(m)).toList();

      final planesStr = prefs.getString('petcard_alimentacion') ?? '[]';
      final List<dynamic> planes = jsonDecode(planesStr);
      _planes = planes.map((p) => Map<String, dynamic>.from(p)).toList();

      if ((_mascotaSeleccionada == null ||
          !_mascotas.any((m) => m['nombre'] == _mascotaSeleccionada)) &&
          _mascotas.isNotEmpty) {
        _mascotaSeleccionada = _mascotas.first['nombre'].toString();
      }
      if (_mascotas.isEmpty) {
        _mascotaSeleccionada = null;
      }
    } catch (e) {
      debugPrint('Error cargando datos de alimentación: $e');
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  Future<void> _guardarEnPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('petcard_alimentacion', jsonEncode(_planes));
  }

  // ============================================================
  // GETTERS DE CONVENIENCIA
  // ============================================================
  Map<String, dynamic>? get _planActual {
    if (_mascotaSeleccionada == null) return null;
    for (final p in _planes.reversed) {
      if (p['mascota'] == _mascotaSeleccionada) return p;
    }
    return null;
  }

  Map<String, dynamic>? get _mascotaActual {
    if (_mascotaSeleccionada == null) return null;
    for (final m in _mascotas) {
      if (m['nombre'] == _mascotaSeleccionada) return m;
    }
    return null;
  }

  List<String> get _comidasList {
    final plan = _planActual;
    if (plan == null) return [];
    final raw = (plan['comidas'] ?? '').toString();
    return raw.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  // ============================================================
  // FORMULARIO - CREAR / EDITAR PLAN
  // ============================================================
  void _abrirFormularioPlan() {
    if (_mascotaSeleccionada == null) {
      _mostrarAlerta('Atención', '⚠️ Primero registra o selecciona una mascota.');
      return;
    }

    final planExistente = _planActual;
    _tipoDietaController.text = planExistente?['tipoDieta']?.toString() ?? '';
    _caloriasController.text = planExistente?['calorias']?.toString() ?? '';
    _frecuenciaController.text = planExistente?['frecuencia']?.toString() ?? '';
    _horarioController.text = planExistente?['horario']?.toString() ?? '';
    _comidasController.text = planExistente?['comidas']?.toString() ?? '';
    _suplementosController.text = planExistente?['suplementos']?.toString() ?? '';
    _alergiasController.text = planExistente?['alergias']?.toString() ?? '';
    _diagnosticoController.text = planExistente?['diagnostico']?.toString() ?? '';
    _observacionesController.text = planExistente?['observaciones']?.toString() ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildFormularioPlan(),
    );
  }

  Widget _buildFormularioPlan() {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Plan Nutricional',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              Text(
                'Mascota: $_mascotaSeleccionada',
                style: TextStyle(color: Colors.grey[600], fontSize: 12.5),
              ),
              const SizedBox(height: 16),
              _campoTexto('Tipo de dieta', _tipoDietaController, hint: 'Ej. Balanceada completa'),
              Row(
                children: [
                  Expanded(
                    child: _campoTexto('Calorías/día', _caloriasController, hint: 'Ej. 1200 kcal'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _campoTexto('Frecuencia', _frecuenciaController, hint: '2 veces al día'),
                  ),
                ],
              ),
              _campoTexto('Horario', _horarioController, hint: 'Ej. 7:00 AM · 6:00 PM'),
              _campoTexto('Comidas (separadas por coma)', _comidasController,
                  hint: 'Desayuno, Almuerzo, Cena'),
              _campoTexto('Suplementos', _suplementosController, hint: 'Ej. Omega-3, Glucosamina'),
              _campoTexto('Alergias / restricciones', _alergiasController, hint: 'Ninguna'),
              _campoTexto('Diagnóstico', _diagnosticoController, hint: 'No disponible'),
              _campoTexto('Observaciones', _observacionesController,
                  hint: 'Notas del veterinario', maxLines: 3),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _guardarPlan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kAzul,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text(
                    'Guardar Plan',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _campoTexto(
      String label,
      TextEditingController controller, {
        String? hint,
        int maxLines = 1,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[700]),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: kAzul, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              isDense: true,
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _guardarPlan() async {
    if (_tipoDietaController.text.trim().isEmpty || _caloriasController.text.trim().isEmpty) {
      _mostrarAlerta('Error', '⚠️ El tipo de dieta y las calorías son obligatorios');
      return;
    }

    try {
      final nuevoPlan = {
        'id': DateTime.now().millisecondsSinceEpoch,
        'mascota': _mascotaSeleccionada,
        'tipoDieta': _tipoDietaController.text.trim(),
        'calorias': _caloriasController.text.trim(),
        'frecuencia': _frecuenciaController.text.trim(),
        'horario': _horarioController.text.trim(),
        'comidas': _comidasController.text.trim(),
        'suplementos':
        _suplementosController.text.trim().isEmpty ? 'Ninguno' : _suplementosController.text.trim(),
        'alergias':
        _alergiasController.text.trim().isEmpty ? 'Ninguna' : _alergiasController.text.trim(),
        'diagnostico': _diagnosticoController.text.trim().isEmpty
            ? 'No disponible'
            : _diagnosticoController.text.trim(),
        'observaciones': _observacionesController.text.trim().isEmpty
            ? 'Sin observaciones adicionales'
            : _observacionesController.text.trim(),
        'fechaRegistro': DateTime.now().toIso8601String(),
      };

      // Solo un plan activo por mascota: se reemplaza el anterior
      _planes.removeWhere((p) => p['mascota'] == _mascotaSeleccionada);
      _planes.add(nuevoPlan);
      await _guardarEnPrefs();

      if (!mounted) return;
      Navigator.pop(context);

      await _cargarDatos();
      if (!mounted) return;
      _mostrarAlerta('Éxito', '✅ Plan nutricional guardado correctamente');
    } catch (e) {
      if (mounted) {
        _mostrarAlerta('Error', '❌ Error al guardar el plan');
      }
      debugPrint('Error guardando plan de alimentación: $e');
    }
  }

  void _usarPlanBase(Map<String, String> datos) {
    setState(() => _tabIndex = 0);
    _tipoDietaController.text = datos['tipoDieta'] ?? '';
    _caloriasController.text = datos['calorias'] ?? '';
    _frecuenciaController.text = datos['frecuencia'] ?? '';
    _horarioController.text = datos['horario'] ?? '';
    _comidasController.text = datos['comidas'] ?? '';
    _suplementosController.text = '';
    _alergiasController.text = '';
    _diagnosticoController.text = '';
    _observacionesController.text = datos['observaciones'] ?? '';

    if (_mascotaSeleccionada == null) {
      _mostrarAlerta('Atención', '⚠️ Primero registra o selecciona una mascota.');
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildFormularioPlan(),
    );
  }

  void _mostrarAlerta(String titulo, String mensaje) {
    if (!mounted) return;
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
  // CONSTRUCCIÓN DE LA INTERFAZ
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: kAzul,
        elevation: 0,
        title: const Text(
          'Alimentación',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: kAzul))
          : RefreshIndicator(
        onRefresh: _cargarDatos,
        color: kAzul,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSelectorMascota(),
              const SizedBox(height: 16),
              _buildTabs(),
              const SizedBox(height: 16),
              if (_tabIndex == 0) _buildTabPlan(),
              if (_tabIndex == 1) _buildTabHistorial(),
              if (_tabIndex == 2) _buildTabAlternativas(),
            ],
          ),
        ),
      ),
      floatingActionButton: (_mascotaSeleccionada == null || _isLoading)
          ? null
          : FloatingActionButton.extended(
        onPressed: _abrirFormularioPlan,
        backgroundColor: kAzul,
        icon: const Icon(Icons.edit_note, color: Colors.white),
        label: Text(
          _planActual == null ? 'Crear Plan' : 'Editar Plan',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // Selector de mascota
  // ------------------------------------------------------------
  Widget _buildSelectorMascota() {
    return Container(
      width: double.infinity,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.pets, color: kAzul, size: 20),
              SizedBox(width: 8),
              Text('Seleccionar Mascota',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Elige tu mascota para ver su plan nutricional',
            style: TextStyle(fontSize: 12.5, color: Colors.grey[600]),
          ),
          const SizedBox(height: 10),
          if (_mascotas.isEmpty)
            Text(
              'No hay mascotas registradas todavía. Ve a "Mis Mascotas" para agregar una.',
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            )
          else
            DropdownButtonFormField<String>(
              initialValue: _mascotaSeleccionada,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                isDense: true,
                filled: true,
                fillColor: Colors.white,
              ),
              items: _mascotas
                  .map((m) => DropdownMenuItem(
                value: m['nombre'].toString(),
                child: Text('${m['nombre']} · ${m['especie'] ?? 'Mascota'}'),
              ))
                  .toList(),
              onChanged: (v) => setState(() => _mascotaSeleccionada = v),
            ),
          if (_planActual != null) ...[
            const SizedBox(height: 8),
            Text(
              'Plan: ${_planActual!['tipoDieta']}',
              style: const TextStyle(color: kAzul, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // Tabs
  // ------------------------------------------------------------
  Widget _buildTabs() {
    final tabs = ['Plan Nutricional', 'Historial', 'Alternativas'];
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final activo = _tabIndex == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _tabIndex = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: activo ? kAzul : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  tabs[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: activo ? Colors.white : Colors.grey[600],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ------------------------------------------------------------
  // TAB: Plan Nutricional
  // ------------------------------------------------------------
  Widget _buildTabPlan() {
    if (_mascotaSeleccionada == null) {
      return _mensajeVacio(
        'Registra una mascota',
        'Agrega una mascota en "Mis Mascotas" para poder crear su plan nutricional.',
      );
    }

    final plan = _planActual;
    final mascota = _mascotaActual;

    if (plan == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (mascota != null) ...[_tarjetaInfoMascota(mascota), const SizedBox(height: 16)],
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF5F0),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFDE2E2)),
            ),
            child: Column(
              children: [
                const Text(
                  'Aún no tienes un plan de alimentación asignado',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFB91C1C)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Normalmente es tu veterinario quien crea y asigna el plan nutricional. Toca "Crear Plan" para registrarlo.',
                  style: TextStyle(color: Color(0xFF7F1D1D), fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      );
    }

    final comidas = _comidasList;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stats
        Row(
          children: [
            Expanded(
              child: _statBox(
                icon: Icons.local_fire_department_outlined,
                value: (plan['calorias'] ?? '—').toString(),
                label: 'Calorías Diarias',
                color: kNaranja,
                bg: kNaranjaBg,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _statBox(
                icon: Icons.restaurant_menu,
                value: comidas.isNotEmpty ? '${comidas.length}' : '—',
                label: 'Comidas en Plan',
                color: kAzul,
                bg: kAzulBg,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _statBox(
                icon: Icons.event_repeat,
                value: (plan['frecuencia'] ?? '—').toString(),
                label: 'Frecuencia',
                color: kVerde,
                bg: kVerdeBg,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Alimento / plan recomendado
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: kAzulBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Plan de dieta: ${plan['tipoDieta'] ?? ''}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: kAzul),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Horario: ${(plan['horario'] ?? '').toString().isEmpty ? 'No definido' : plan['horario']}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Suplementos', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                  Text(
                    (plan['suplementos'] ?? 'Ninguno').toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Horarios de alimentación
        _seccionTitulo('Horarios de Alimentación'),
        if (comidas.isEmpty)
          Text(
            'No hay comidas registradas en el plan de esta mascota.',
            style: TextStyle(color: Colors.grey[500]),
          )
        else
          ...comidas.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            final destacado = idx == 1;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: destacado ? kVerdeBg : Colors.grey[100],
                    ),
                    child: Icon(Icons.access_time,
                        size: 15, color: destacado ? kVerde : Colors.grey[500]),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                        Text(
                          (plan['horario'] ?? '').toString().isEmpty
                              ? 'Horario no definido'
                              : plan['horario'].toString(),
                          style: TextStyle(fontSize: 11.5, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${plan['calorias'] ?? ''} cal',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.check_circle, size: 16, color: destacado ? kVerde : Colors.grey[300]),
                ],
              ),
            );
          }),
        const SizedBox(height: 18),

        // Suplementos
        _seccionTitulo('Suplementos'),
        _suplementoCard(
          (plan['suplementos'] ?? 'Ninguno').toString(),
          (plan['frecuencia'] ?? '').toString().isNotEmpty
              ? plan['frecuencia'].toString()
              : 'Revisión de frecuencia pendiente',
          'Activo',
          kVerde,
          kVerdeBg,
        ),
        const SizedBox(height: 18),

        // Restricciones
        _seccionTitulo('Restricciones Alimentarias'),
        _restriccionItem(
          icon: Icons.warning_amber_rounded,
          titulo: (plan['alergias'] ?? 'Ninguna').toString(),
          subtitulo: 'Restricción',
          badge: 'Importante',
          color: kRojo,
          bg: kRojoBg,
        ),
        const SizedBox(height: 8),
        _restriccionItem(
          icon: Icons.warning_amber_rounded,
          titulo: 'Diagnóstico',
          subtitulo: (plan['diagnostico'] ?? 'No disponible').toString(),
          badge: 'Revisión',
          color: kAmarillo,
          bg: kAmarilloBg,
        ),
        const SizedBox(height: 18),

        // Observaciones
        _seccionTitulo('Observaciones'),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: Text(
            (plan['observaciones'] ?? 'Sin observaciones adicionales').toString(),
            style: const TextStyle(fontSize: 13, height: 1.5),
          ),
        ),
        const SizedBox(height: 20),

        if (mascota != null) ...[_tarjetaInfoMascota(mascota), const SizedBox(height: 16)],
        _tarjetaConsumoNutricional(),
        const SizedBox(height: 90),
      ],
    );
  }

  Widget _seccionTitulo(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(t, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
  );

  Widget _statBox({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF1A1A2E)),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }

  Widget _suplementoCard(String titulo, String detalle, String badge, Color color, Color bg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(titulo,
                    style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
                child: Text(badge,
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(detalle, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
        ],
      ),
    );
  }

  Widget _restriccionItem({
    required IconData icon,
    required String titulo,
    required String subtitulo,
    required String badge,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
                Text(subtitulo, style: TextStyle(fontSize: 11.5, color: Colors.grey[600])),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
            child: Text(badge,
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _tarjetaInfoMascota(Map<String, dynamic> m) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.pets, color: kAzul, size: 18),
              const SizedBox(width: 8),
              Text(
                'Información de ${m['nombre'] ?? 'Mascota'}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: kAzul),
              ),
            ],
          ),
          const Divider(height: 20),
          _filaInfo('Peso Actual', '${m['peso'] ?? '—'} kg'),
          _filaInfo('Edad', '${m['edad'] ?? '—'}'),
          _filaInfo('Raza', '${m['raza'] ?? '—'}'),
          _filaInfo('Especie', '${m['especie'] ?? '—'}'),
        ],
      ),
    );
  }

  Widget _filaInfo(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          Text(valor, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _tarjetaConsumoNutricional() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.pie_chart_outline, color: kAzul, size: 18),
              SizedBox(width: 8),
              Text('Consumo Nutricional', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 14),
          _barraNutriente('Proteínas', 0.45, kAzul, 'Recomendado: 40-50%'),
          _barraNutriente('Grasas', 0.20, kVerde, 'Recomendado: 15-25%'),
          _barraNutriente('Carbohidratos', 0.35, Colors.grey, 'Recomendado: 30-40%'),
        ],
      ),
    );
  }

  Widget _barraNutriente(String label, double valor, Color color, String recomendado) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 12.5)),
              Text('${(valor * 100).round()}%',
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: valor,
              minHeight: 7,
              backgroundColor: Colors.grey[200],
              color: color,
            ),
          ),
          const SizedBox(height: 3),
          Text(recomendado, style: TextStyle(fontSize: 10.5, color: Colors.grey[500])),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // TAB: Historial de cambios
  // ------------------------------------------------------------
  Widget _buildTabHistorial() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.history, size: 56, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text('No hay cambios registrados aún.', style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // TAB: Alternativas / planes recomendados
  // ------------------------------------------------------------
  Widget _buildTabAlternativas() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Planes de Alimentación Veterinarios',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
        const SizedBox(height: 4),
        Text(
          'Planes recomendados por veterinarias especializadas. Solo tu veterinario puede asignarte uno oficialmente.',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(height: 14),
        ..._planesRecomendados.map(_planRecomendadoCard),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F9FF),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFBAE6FD)),
          ),
          child: const Text(
            'ℹ️ Nota: Estos planes son de referencia. El plan activo de tu mascota debe ser confirmado por tu veterinario.',
            style: TextStyle(fontSize: 12, color: Color(0xFF0C4A6E)),
          ),
        ),
        const SizedBox(height: 90),
      ],
    );
  }

  List<Map<String, dynamic>> get _planesRecomendados => [
    {
      'emoji': '🥗',
      'titulo': 'Plan Mantenimiento Estándar',
      'vet': 'Clínica Veterinaria del Valle · Adultos sanos',
      'badge': 'Más popular',
      'color': kVerde,
      'items': {
        'Tipo de dieta': 'Balanceada completa',
        'Frecuencia': '2 veces al día',
        'Horario': '7:00 AM · 6:00 PM',
        'Calorías/día': '1200 kcal',
        'Proteína': '26-30%',
        'Grasas': '12-16%',
      },
      'comidas': [
        '🌅 Desayuno · Croquetas Premium 180 g + agua',
        '🌆 Cena · Croquetas Premium 180 g + vegetal cocido',
      ],
      'obs':
      'Sin restricciones específicas. Ideal para mascotas adultas sin patologías. Revisión nutricional cada 6 meses.',
    },
    {
      'emoji': '⚖️',
      'titulo': 'Plan Control de Peso',
      'vet': 'Centro Veterinario Bienestar Animal · Sobrepeso',
      'badge': 'Especializado',
      'color': kAmarillo,
      'items': {
        'Tipo de dieta': 'Hipocalórica controlada',
        'Frecuencia': '3 veces al día',
        'Horario': '8 AM · 1 PM · 7 PM',
        'Calorías/día': '800-950 kcal',
        'Proteína': '30-35%',
        'Grasas': '6-10%',
      },
      'comidas': [
        '🌅 Mañana · Alimento Light 120 g + zanahoria',
        '☀️ Mediodía · Pollo hervido 80 g',
        '🌆 Noche · Alimento Light 120 g + caldo',
      ],
      'obs':
      'Sin golosinas entre comidas. Ejercicio diario de 30 min recomendado. Pesaje mensual obligatorio.',
    },
    {
      'emoji': '💊',
      'titulo': 'Plan Soporte Renal y Digestivo',
      'vet': 'Hospital Veterinario San Francisco · Patologías internas',
      'badge': 'Prescripción médica',
      'color': kAzul,
      'items': {
        'Tipo de dieta': 'Terapéutica baja en fósforo',
        'Frecuencia': '3-4 veces al día',
        'Horario': 'Cada 6 horas',
        'Calorías/día': '900-1100 kcal',
        'Proteína': '14-18%',
        'Fósforo': '< 0.5%',
      },
      'comidas': [
        "Hill's k/d Kidney Care · según peso",
        'Royal Canin Renal · alternado',
      ],
      'obs':
      'Requiere diagnóstico previo. Evitar proteínas de origen vegetal. Control de BUN y creatinina cada 3 meses.',
    },
    {
      'emoji': '🐾',
      'titulo': 'Plan Crecimiento (Cachorros / Junior)',
      'vet': 'Clínica PetLife · Hasta 12 meses',
      'badge': 'Junior',
      'color': kAmarillo,
      'items': {
        'Tipo de dieta': 'Alta energía',
        'Frecuencia': '4 veces al día',
        'Horario': '7 AM · 12 PM · 5 PM · 9 PM',
        'Calorías/día': '1500-1800 kcal',
        'Proteína': '28-32%',
        'Calcio': '1.2-1.8%',
      },
      'comidas': [
        '🌅 Mañana · Puppy food húmedo 100 g + DHA',
        '☀️ Mediodía · Croquetas Junior 120 g',
        '🌆 Tarde · Croquetas Junior 120 g + calcio',
        '🌙 Noche · Puppy food seco 100 g',
      ],
      'obs':
      'Suplementar con omega-3 para desarrollo neurológico. Transición gradual de 7 días al cambiar de alimento.',
    },
    {
      'emoji': '🏥',
      'titulo': 'Plan Geronto (Senior +7 años)',
      'vet': 'Clínica Veterinaria Oasis · Mascotas mayores',
      'badge': 'Senior',
      'color': kAzul,
      'items': {
        'Tipo de dieta': 'Baja en sodio',
        'Frecuencia': '2-3 veces al día',
        'Horario': '8 AM · 3 PM · 8 PM',
        'Calorías/día': '1000-1200 kcal',
        'Proteína': '22-28%',
        'Fibra': '3-5%',
      },
      'comidas': [
        "Hill's Science Diet Senior · según peso",
        'Glucosamina/condroitina · diario',
        'Omega-3 · 1 cápsula diaria',
      ],
      'obs':
      'Evitar alimentos procesados con alto sodio. Control geriátrico anual. Agua fresca disponible siempre.',
    },
  ];

  Widget _planRecomendadoCard(Map<String, dynamic> p) {
    final Color color = p['color'] as Color;
    final items = Map<String, String>.from(p['items'] as Map);
    final comidas = List<String>.from(p['comidas'] as List);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: color, width: 4)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${p['emoji']} ${p['titulo']}',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(p['vet'].toString(), style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
                child: Text(
                  p['badge'].toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: items.entries
                .map((e) => SizedBox(
              width: 140,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.key, style: TextStyle(fontSize: 10.5, color: Colors.grey[500])),
                  Text(e.value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ))
                .toList(),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: comidas
                .map((c) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Text(c, style: const TextStyle(fontSize: 10.5)),
            ))
                .toList(),
          ),
          const SizedBox(height: 10),
          Text(p['obs'].toString(),
              style: TextStyle(fontSize: 11.5, color: Colors.grey[600], height: 1.4)),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _usarPlanBase({
                'tipoDieta': items['Tipo de dieta'] ?? '',
                'calorias': items['Calorías/día'] ?? '',
                'frecuencia': items['Frecuencia'] ?? '',
                'horario': items['Horario'] ?? '',
                'comidas': comidas.join(', '),
                'observaciones': p['obs'].toString(),
              }),
              icon: Icon(Icons.copy_outlined, size: 15, color: color),
              label: Text('Usar como base',
                  style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mensajeVacio(String titulo, String subtitulo) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.pets_outlined, size: 56, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(titulo, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.grey[700])),
          const SizedBox(height: 6),
          Text(
            subtitulo,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}