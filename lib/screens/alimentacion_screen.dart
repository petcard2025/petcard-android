// ============================================================
// ALIMENTACIÓN SCREEN - Gestión de planes de alimentación
// Mismo lenguaje visual que Citas y Mis Mascotas, en azul
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
  // COLOR PRINCIPAL (igual que el resto de la app)
  // ============================================================
  static const Color kAzul = Color(0xFF2563EB);

  // ============================================================
  // VARIABLES DE ESTADO
  // ============================================================
  bool _isLoading = true;
  List<Map<String, dynamic>> _planes = [];
  List<Map<String, dynamic>> _mascotas = [];
  bool _mostrarFormulario = false;

  // Tipos de alimento para el dropdown
  final List<String> _tiposAlimento = [
    'Concentrado / Croquetas',
    'Alimento húmedo',
    'Dieta BARF (cruda)',
    'Alimento casero',
    'Snacks / Premios',
    'Dieta prescrita (veterinaria)',
    'Otro',
  ];

  // Frecuencias disponibles
  final List<String> _frecuencias = [
    '1 vez al día',
    '2 veces al día',
    '3 veces al día',
    '4 veces al día',
    'Cada 12 horas',
    'Cada 8 horas',
    'Libre acceso',
  ];

  // Controladores del formulario
  String? _tipoSeleccionado;
  String? _mascotaSeleccionada;
  String? _frecuenciaSeleccionada;
  final TextEditingController _cantidadController = TextEditingController();
  final TextEditingController _horarioController = TextEditingController();
  final TextEditingController _notasController = TextEditingController();
  bool _recordatorioActivo = true;

  // Controladores para edición
  Map<String, dynamic>? _planEditando;
  bool _editando = false;

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
    _cantidadController.dispose();
    _horarioController.dispose();
    _notasController.dispose();
    super.dispose();
  }

  // ============================================================
  // CARGA DE DATOS
  // ============================================================
  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();

      final planesStr = prefs.getString('petcard_alimentacion') ?? '[]';
      final List<dynamic> planes = jsonDecode(planesStr);
      _planes = planes.map((p) => Map<String, dynamic>.from(p)).toList();

      final mascotasStr = prefs.getString('petcard_mascotas') ?? '[]';
      final List<dynamic> mascotas = jsonDecode(mascotasStr);
      _mascotas = mascotas.map((m) => Map<String, dynamic>.from(m)).toList();
    } catch (e) {
      debugPrint('Error cargando alimentación: $e');
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  // ============================================================
  // GUARDAR PLAN
  // ============================================================
  Future<void> _guardarPlan() async {
    if (_tipoSeleccionado == null ||
        _mascotaSeleccionada == null ||
        _frecuenciaSeleccionada == null ||
        _cantidadController.text.trim().isEmpty) {
      _mostrarAlerta(
        'Error',
        '⚠️ Tipo de alimento, mascota, cantidad y frecuencia son obligatorios',
      );
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();

      final Map<String, dynamic> nuevoPlan = {
        'id': DateTime.now().millisecondsSinceEpoch,
        'tipoAlimento': _tipoSeleccionado,
        'mascota': _mascotaSeleccionada,
        'cantidad': _cantidadController.text.trim(),
        'frecuencia': _frecuenciaSeleccionada,
        'horario': _horarioController.text.trim(),
        'notas': _notasController.text.trim(),
        'recordatorio': _recordatorioActivo,
        'fechaRegistro': DateTime.now().toIso8601String(),
      };

      _planes.add(nuevoPlan);
      await _guardarEnPrefs(prefs);

      _limpiarFormulario();
      if (!mounted) return;
      setState(() {
        _mostrarFormulario = false;
        _editando = false;
      });

      await _cargarDatos();
      if (!mounted) return;
      _mostrarAlerta('Éxito', '✅ Plan de alimentación guardado correctamente');
    } catch (e) {
      if (mounted) {
        _mostrarAlerta('Error', '❌ Error al guardar el plan de alimentación');
      }
      debugPrint('Error guardando plan: $e');
    }
  }

  // ============================================================
  // ACTUALIZAR PLAN
  // ============================================================
  Future<void> _actualizarPlan() async {
    if (_tipoSeleccionado == null ||
        _mascotaSeleccionada == null ||
        _frecuenciaSeleccionada == null ||
        _cantidadController.text.trim().isEmpty) {
      _mostrarAlerta(
        'Error',
        '⚠️ Tipo de alimento, mascota, cantidad y frecuencia son obligatorios',
      );
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();

      final index = _planes.indexWhere(
            (p) => p['id'] == _planEditando!['id'],
      );

      if (index != -1) {
        _planes[index] = {
          ..._planes[index],
          'tipoAlimento': _tipoSeleccionado,
          'mascota': _mascotaSeleccionada,
          'cantidad': _cantidadController.text.trim(),
          'frecuencia': _frecuenciaSeleccionada,
          'horario': _horarioController.text.trim(),
          'notas': _notasController.text.trim(),
          'recordatorio': _recordatorioActivo,
        };

        await _guardarEnPrefs(prefs);
        _limpiarFormulario();
        if (!mounted) return;
        setState(() {
          _mostrarFormulario = false;
          _editando = false;
          _planEditando = null;
        });

        await _cargarDatos();
        if (!mounted) return;
        _mostrarAlerta('Éxito', '✅ Plan actualizado correctamente');
      }
    } catch (e) {
      if (mounted) {
        _mostrarAlerta('Error', '❌ Error al actualizar el plan');
      }
      debugPrint('Error actualizando plan: $e');
    }
  }

  // ============================================================
  // ELIMINAR PLAN
  // ============================================================
  Future<void> _eliminarPlan(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar plan'),
        content: const Text(
          '¿Estás seguro que deseas eliminar este plan de alimentación?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (confirm == true) {
      try {
        final prefs = await SharedPreferences.getInstance();
        _planes.removeWhere((p) => p['id'] == id);
        await _guardarEnPrefs(prefs);
        if (!mounted) return;
        setState(() {});
        _mostrarAlerta('Éxito', '✅ Plan eliminado correctamente');
      } catch (e) {
        if (mounted) {
          _mostrarAlerta('Error', '❌ Error al eliminar el plan');
        }
        debugPrint('Error eliminando plan: $e');
      }
    }
  }

  // ============================================================
  // ACTIVAR / DESACTIVAR RECORDATORIO DESDE LA TARJETA
  // ============================================================
  Future<void> _toggleRecordatorio(int id, bool valor) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final index = _planes.indexWhere((p) => p['id'] == id);
      if (index != -1) {
        _planes[index]['recordatorio'] = valor;
        await _guardarEnPrefs(prefs);
        if (!mounted) return;
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error actualizando recordatorio: $e');
    }
  }

  // ============================================================
  // EDICIÓN
  // ============================================================
  void _editarPlan(Map<String, dynamic> plan) {
    setState(() {
      _planEditando = plan;
      _editando = true;
      _mostrarFormulario = true;

      _tipoSeleccionado = plan['tipoAlimento'];
      _mascotaSeleccionada = plan['mascota'];
      _frecuenciaSeleccionada = plan['frecuencia'];
      _cantidadController.text = plan['cantidad'] ?? '';
      _horarioController.text = plan['horario'] ?? '';
      _notasController.text = plan['notas'] ?? '';
      _recordatorioActivo = plan['recordatorio'] ?? true;
    });
  }

  void _limpiarFormulario() {
    _tipoSeleccionado = null;
    _mascotaSeleccionada = null;
    _frecuenciaSeleccionada = null;
    _cantidadController.clear();
    _horarioController.clear();
    _notasController.clear();
    _recordatorioActivo = true;
    _planEditando = null;
    _editando = false;
  }

  // ============================================================
  // GUARDAR EN PREFERENCES
  // ============================================================
  Future<void> _guardarEnPrefs(SharedPreferences prefs) async {
    final String planesJson = jsonEncode(_planes);
    await prefs.setString('petcard_alimentacion', planesJson);
  }

  // ============================================================
  // UTILIDADES
  // ============================================================
  IconData _iconoAlimento(String tipo) {
    switch (tipo) {
      case 'Concentrado / Croquetas':
        return Icons.grain;
      case 'Alimento húmedo':
        return Icons.set_meal;
      case 'Dieta BARF (cruda)':
        return Icons.restaurant;
      case 'Alimento casero':
        return Icons.soup_kitchen;
      case 'Snacks / Premios':
        return Icons.cookie;
      case 'Dieta prescrita (veterinaria)':
        return Icons.medical_services;
      default:
        return Icons.pets;
    }
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
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () {
              setState(() {
                _mostrarFormulario = true;
                _editando = false;
                _limpiarFormulario();
              });
            },
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
            // TÍTULO Y CONTADOR
            // ==========================================================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Planes de alimentación',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: kAzul.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_planes.length} planes',
                    style: const TextStyle(
                      color: kAzul,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Controla la dieta y los horarios de comida de tus mascotas',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),

            // ==========================================================
            // FORMULARIO
            // ==========================================================
            if (_mostrarFormulario) _buildFormularioPlan(),

            // ==========================================================
            // LISTA DE PLANES
            // ==========================================================
            if (_planes.isEmpty && !_mostrarFormulario)
              _buildEmptyState()
            else if (!_mostrarFormulario)
              ..._planes.map((plan) => _buildPlanCard(plan)),

            const SizedBox(height: 20),

            // ==========================================================
            // BOTÓN NUEVO PLAN
            // ==========================================================
            if (!_mostrarFormulario)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _mostrarFormulario = true;
                      _editando = false;
                      _limpiarFormulario();
                    });
                  },
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text(
                    'Nuevo plan de alimentación',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kAzul,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // WIDGET - FORMULARIO DE PLAN
  // ============================================================
  Widget _buildFormularioPlan() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    _editando ? Icons.edit : Icons.restaurant,
                    size: 18,
                    color: kAzul,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _editando ? 'Editar Plan' : 'Nuevo Plan de Alimentación',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () {
                  setState(() {
                    _mostrarFormulario = false;
                    _limpiarFormulario();
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _editando
                ? 'Actualiza los datos del plan de alimentación'
                : 'Completa los datos para registrar un nuevo plan',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),

          // Mascota
          _mascotas.isEmpty
              ? Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              '⚠️ No tienes mascotas registradas. Ve a "Mis Mascotas" y agrega una primero.',
              style: TextStyle(fontSize: 12, color: Color(0xFF92400E)),
            ),
          )
              : _buildDropdown(
            label: 'Mascota',
            hint: 'Selecciona la mascota',
            valor: _mascotaSeleccionada,
            opciones:
            _mascotas.map((m) => m['nombre'].toString()).toList(),
            onChanged: (v) => setState(() => _mascotaSeleccionada = v),
          ),
          const SizedBox(height: 12),

          // Tipo de alimento
          _buildDropdown(
            label: 'Tipo de alimento',
            hint: 'Selecciona el tipo de alimento',
            valor: _tipoSeleccionado,
            opciones: _tiposAlimento,
            onChanged: (v) => setState(() => _tipoSeleccionado = v),
          ),
          const SizedBox(height: 12),

          // Cantidad y frecuencia en Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildCampoFormulario(
                  label: 'Cantidad por porción',
                  hint: 'Ej. 150 g',
                  controller: _cantidadController,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropdown(
                  label: 'Frecuencia',
                  hint: 'Selecciona',
                  valor: _frecuenciaSeleccionada,
                  opciones: _frecuencias,
                  onChanged: (v) =>
                      setState(() => _frecuenciaSeleccionada = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Horario
          _buildCampoFormulario(
            label: 'Horario sugerido (opcional)',
            hint: 'Ej. 7:00 am y 6:00 pm',
            controller: _horarioController,
          ),
          const SizedBox(height: 12),

          // Notas
          _buildCampoFormulario(
            label: 'Notas (opcional)',
            hint: 'Ej. Alergias, restricciones o indicaciones del veterinario',
            controller: _notasController,
          ),
          const SizedBox(height: 12),

          // Recordatorio
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.notifications_active_outlined,
                    size: 18, color: kAzul),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Activar recordatorio de comida',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
                Switch(
                  value: _recordatorioActivo,
                  activeColor: kAzul,
                  onChanged: (v) => setState(() => _recordatorioActivo = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Botón Guardar
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _editando ? _actualizarPlan : _guardarPlan,
              style: ElevatedButton.styleFrom(
                backgroundColor: kAzul,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                _editando ? 'Actualizar Plan' : 'Guardar plan',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampoFormulario({
    required String label,
    required String hint,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            isDense: true,
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String hint,
    required String? valor,
    required List<String> opciones,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          initialValue: valor,
          isExpanded: true,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            isDense: true,
            filled: true,
            fillColor: Colors.white,
          ),
          items: opciones
              .map((op) => DropdownMenuItem(value: op, child: Text(op)))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  // ============================================================
  // WIDGET - TARJETA DE PLAN
  // ============================================================
  Widget _buildPlanCard(Map<String, dynamic> plan) {
    final tipo = plan['tipoAlimento'] ?? 'Alimento';
    final recordatorio = plan['recordatorio'] ?? true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icono del alimento
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: kAzul.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _iconoAlimento(tipo),
                  color: kAzul,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),

              // Información
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tipo,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${plan['mascota'] ?? ''} · ${plan['cantidad'] ?? ''}',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${plan['frecuencia'] ?? ''}'
                          '${(plan['horario'] ?? '').toString().isNotEmpty ? ' · ${plan['horario']}' : ''}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),

              // Badge de recordatorio
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: (recordatorio ? kAzul : Colors.grey)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  recordatorio ? '🔔 Activo' : '🔕 Inactivo',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: recordatorio ? kAzul : Colors.grey,
                  ),
                ),
              ),
            ],
          ),

          if ((plan['notas'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              plan['notas'],
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],

          const Divider(height: 20),

          // Acciones
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.notifications_none,
                      size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    'Recordatorio',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                  Switch(
                    value: recordatorio,
                    activeColor: kAzul,
                    onChanged: (v) => _toggleRecordatorio(plan['id'], v),
                  ),
                ],
              ),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () => _editarPlan(plan),
                    icon: Icon(Icons.edit, size: 16, color: Colors.grey[700]),
                    label: Text(
                      'Editar',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: Colors.red[300],
                    ),
                    onPressed: () => _eliminarPlan(plan['id']),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.restaurant, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No tienes planes de alimentación',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Registra el primer plan para comenzar',
            style: TextStyle(fontSize: 13, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }
}
