import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class CitasScreen extends StatefulWidget {
  const CitasScreen({super.key});

  @override
  State<CitasScreen> createState() => _CitasScreenState();
}

class _CitasScreenState extends State<CitasScreen> {
  // ============================================================
  // COLOR PRINCIPAL (igual que el resto de la app)
  // ============================================================
  static const Color kMorado = Color(0xFF7C3AED);

  // ============================================================
  // VARIABLES DE ESTADO
  // ============================================================
  bool _isLoading = true;
  List<Map<String, dynamic>> _citas = [];
  List<Map<String, dynamic>> _mascotas = [];
  bool _mostrarFormulario = false;

  // Lista de servicios disponibles para el dropdown
  final List<String> _servicios = [
    'Consulta general',
    'Vacunación',
    'Baño y peluquería',
    'Desparasitación',
    'Estética',
    'Dermatología',
    'Cirugía',
    'Otro',
  ];

  // Estados posibles de una cita
  final List<String> _estados = [
    'Pendiente',
    'Confirmada',
    'Completada',
    'Cancelada',
  ];

  // Controladores para el formulario
  String? _servicioSeleccionado;
  String? _mascotaSeleccionada;
  final TextEditingController _veterinarioController = TextEditingController();
  final TextEditingController _notasController = TextEditingController();
  DateTime? _fechaSeleccionada;
  TimeOfDay? _horaSeleccionada;
  String _estadoSeleccionado = 'Pendiente';

  // Controladores para edición
  Map<String, dynamic>? _citaEditando;
  bool _editando = false;

  // Última cita creada (para mostrar la confirmación tras agendar)
  Map<String, dynamic>? _citaRecienCreada;

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
    _veterinarioController.dispose();
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

      // Cargar citas
      final citasStr = prefs.getString('petcard_citas') ?? '[]';
      final List<dynamic> citas = jsonDecode(citasStr);
      _citas = citas.map((c) => Map<String, dynamic>.from(c)).toList();

      // Ordenar por fecha (las más próximas primero)
      _citas.sort((a, b) {
        final fechaA = a['fechaHoraOrden'] ?? '';
        final fechaB = b['fechaHoraOrden'] ?? '';
        return fechaA.compareTo(fechaB);
      });

      // Cargar mascotas registradas (para el dropdown de selección)
      final mascotasStr = prefs.getString('petcard_mascotas') ?? '[]';
      final List<dynamic> mascotas = jsonDecode(mascotasStr);
      _mascotas = mascotas.map((m) => Map<String, dynamic>.from(m)).toList();
    } catch (e) {
      debugPrint('Error cargando citas: $e');
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  // ============================================================
  // GUARDAR CITA
  // ============================================================
  Future<void> _guardarCita() async {
    if (_servicioSeleccionado == null ||
        _mascotaSeleccionada == null ||
        _fechaSeleccionada == null ||
        _horaSeleccionada == null) {
      _mostrarAlerta(
        'Error',
        '⚠️ Servicio, mascota, fecha y hora son obligatorios',
      );
      return;
    }

    final horaFormateada = _horaSeleccionada!.format(context);

    try {
      final prefs = await SharedPreferences.getInstance();

      final fechaHoraOrden = DateTime(
        _fechaSeleccionada!.year,
        _fechaSeleccionada!.month,
        _fechaSeleccionada!.day,
        _horaSeleccionada!.hour,
        _horaSeleccionada!.minute,
      ).toIso8601String();

      final Map<String, dynamic> nuevaCita = {
        'id': DateTime.now().millisecondsSinceEpoch,
        'servicio': _servicioSeleccionado,
        'mascota': _mascotaSeleccionada,
        'veterinario': _veterinarioController.text.trim(),
        'fecha': _formatearFecha(_fechaSeleccionada!),
        'hora': horaFormateada,
        'fechaHoraOrden': fechaHoraOrden,
        'estado': _estadoSeleccionado,
        'notas': _notasController.text.trim(),
        'fechaRegistro': DateTime.now().toIso8601String(),
      };

      _citas.add(nuevaCita);
      await _guardarEnPrefs(prefs);

      _limpiarFormulario();
      if (!mounted) return;
      setState(() {
        _mostrarFormulario = false;
        _editando = false;
        _citaRecienCreada = nuevaCita;
      });

      await _cargarDatos();
    } catch (e) {
      if (mounted) {
        _mostrarAlerta('Error', '❌ Error al guardar la cita');
      }
      debugPrint('Error guardando cita: $e');
    }
  }

  // ============================================================
  // ACTUALIZAR CITA
  // ============================================================
  Future<void> _actualizarCita() async {
    if (_servicioSeleccionado == null ||
        _mascotaSeleccionada == null ||
        _fechaSeleccionada == null ||
        _horaSeleccionada == null) {
      _mostrarAlerta(
        'Error',
        '⚠️ Servicio, mascota, fecha y hora son obligatorios',
      );
      return;
    }

    final horaFormateada = _horaSeleccionada!.format(context);

    try {
      final prefs = await SharedPreferences.getInstance();

      final index = _citas.indexWhere(
            (c) => c['id'] == _citaEditando!['id'],
      );

      if (index != -1) {
        final fechaHoraOrden = DateTime(
          _fechaSeleccionada!.year,
          _fechaSeleccionada!.month,
          _fechaSeleccionada!.day,
          _horaSeleccionada!.hour,
          _horaSeleccionada!.minute,
        ).toIso8601String();

        _citas[index] = {
          ..._citas[index],
          'servicio': _servicioSeleccionado,
          'mascota': _mascotaSeleccionada,
          'veterinario': _veterinarioController.text.trim(),
          'fecha': _formatearFecha(_fechaSeleccionada!),
          'hora': horaFormateada,
          'fechaHoraOrden': fechaHoraOrden,
          'estado': _estadoSeleccionado,
          'notas': _notasController.text.trim(),
        };

        await _guardarEnPrefs(prefs);
        _limpiarFormulario();
        if (!mounted) return;
        setState(() {
          _mostrarFormulario = false;
          _editando = false;
          _citaEditando = null;
        });

        await _cargarDatos();
        if (!mounted) return;
        _mostrarAlerta('Éxito', '✅ Cita actualizada correctamente');
      }
    } catch (e) {
      if (mounted) {
        _mostrarAlerta('Error', '❌ Error al actualizar la cita');
      }
      debugPrint('Error actualizando cita: $e');
    }
  }

  // ============================================================
  // CANCELAR CITA (cambia el estado, no la elimina)
  // ============================================================
  Future<void> _cancelarCita(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar cita'),
        content: const Text('¿Estás seguro que deseas cancelar esta cita?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Sí, cancelar',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (confirm == true) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final index = _citas.indexWhere((c) => c['id'] == id);
        if (index != -1) {
          _citas[index]['estado'] = 'Cancelada';
          await _guardarEnPrefs(prefs);
          if (!mounted) return;
          setState(() {});
          _mostrarAlerta('Éxito', '✅ Cita cancelada');
        }
      } catch (e) {
        if (mounted) {
          _mostrarAlerta('Error', '❌ Error al cancelar la cita');
        }
        debugPrint('Error cancelando cita: $e');
      }
    }
  }

  // ============================================================
  // ELIMINAR CITA (borra el registro por completo)
  // ============================================================
  Future<void> _eliminarCita(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar cita'),
        content: const Text(
          '¿Estás seguro que deseas eliminar esta cita del historial?',
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
        _citas.removeWhere((c) => c['id'] == id);
        await _guardarEnPrefs(prefs);
        if (!mounted) return;
        setState(() {});
        _mostrarAlerta('Éxito', '✅ Cita eliminada correctamente');
      } catch (e) {
        if (mounted) {
          _mostrarAlerta('Error', '❌ Error al eliminar la cita');
        }
        debugPrint('Error eliminando cita: $e');
      }
    }
  }

  // ============================================================
  // EDICIÓN
  // ============================================================
  void _editarCita(Map<String, dynamic> cita) {
    setState(() {
      _citaEditando = cita;
      _editando = true;
      _mostrarFormulario = true;

      _servicioSeleccionado = cita['servicio'];
      _mascotaSeleccionada = cita['mascota'];
      _veterinarioController.text = cita['veterinario'] ?? '';
      _notasController.text = cita['notas'] ?? '';
      _estadoSeleccionado = cita['estado'] ?? 'Pendiente';

      if (cita['fechaHoraOrden'] != null) {
        final dt = DateTime.tryParse(cita['fechaHoraOrden']);
        if (dt != null) {
          _fechaSeleccionada = DateTime(dt.year, dt.month, dt.day);
          _horaSeleccionada = TimeOfDay(hour: dt.hour, minute: dt.minute);
        }
      }
    });
  }

  void _limpiarFormulario() {
    _servicioSeleccionado = null;
    _mascotaSeleccionada = null;
    _veterinarioController.clear();
    _notasController.clear();
    _fechaSeleccionada = null;
    _horaSeleccionada = null;
    _estadoSeleccionado = 'Pendiente';
    _citaEditando = null;
    _editando = false;
  }

  // ============================================================
  // GUARDAR EN PREFERENCES
  // ============================================================
  Future<void> _guardarEnPrefs(SharedPreferences prefs) async {
    final String citasJson = jsonEncode(_citas);
    await prefs.setString('petcard_citas', citasJson);
  }

  // ============================================================
  // SELECTORES DE FECHA Y HORA
  // ============================================================
  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: kMorado),
          ),
          child: child!,
        );
      },
    );
    if (!mounted) return;
    if (fecha != null) {
      setState(() => _fechaSeleccionada = fecha);
    }
  }

  Future<void> _seleccionarHora() async {
    final hora = await showTimePicker(
      context: context,
      initialTime: _horaSeleccionada ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: kMorado),
          ),
          child: child!,
        );
      },
    );
    if (!mounted) return;
    if (hora != null) {
      setState(() => _horaSeleccionada = hora);
    }
  }

  String _formatearFecha(DateTime fecha) {
    const meses = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
    ];
    return '${fecha.day} de ${meses[fecha.month - 1]} de ${fecha.year}';
  }

  // ============================================================
  // UTILIDADES DE ESTADO (colores y etiquetas del badge)
  // ============================================================
  Color _colorEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'confirmada':
        return const Color(0xFF10B981);
      case 'completada':
        return Colors.grey;
      case 'cancelada':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFFF59E0B); // Pendiente
    }
  }

  String _iconoEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'confirmada':
        return '✅';
      case 'completada':
        return '☑️';
      case 'cancelada':
        return '❌';
      default:
        return '🕐';
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
        backgroundColor: kMorado,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.calendar_today, color: Colors.white, size: 22),
            const SizedBox(width: 8),
            const Text(
              'Mis Citas',
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
                _citaRecienCreada = null;
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
                  'Citas y agendamientos',
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
                    color: kMorado.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_citas.length} citas',
                    style: const TextStyle(
                      color: kMorado,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Agenda y consulta las citas de tus mascotas',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),

            // ==========================================================
            // FORMULARIO DE NUEVA CITA
            // ==========================================================
            if (_mostrarFormulario) _buildFormularioCita(),

            // ==========================================================
            // CONFIRMACIÓN DE CITA RECIÉN CREADA
            // ==========================================================
            if (!_mostrarFormulario && _citaRecienCreada != null)
              _buildConfirmacionCita(),

            // ==========================================================
            // LISTA DE CITAS (gestión completa)
            // ==========================================================
            if (!_mostrarFormulario && _citaRecienCreada == null) ...[
              if (_citas.isEmpty)
                _buildEmptyState()
              else
                ..._citas.map((cita) => _buildCitaCard(cita)),
              const SizedBox(height: 20),
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
                    'Nueva cita',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kMorado,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // WIDGET - CONFIRMACIÓN DE CITA CREADA
  // ============================================================
  Widget _buildConfirmacionCita() {
    final cita = _citaRecienCreada!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF10B981).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '¡Cita agendada!',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[900],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tu cita quedó registrada correctamente',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Tarjeta con los datos de la cita que se acaba de crear
        _buildCitaCard(cita),
        const SizedBox(height: 8),

        // Botón para ir a ver la gestión completa de citas
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => setState(() => _citaRecienCreada = null),
            icon: const Icon(Icons.event_note, color: kMorado),
            label: const Text(
              'Ver la gestión de tus citas',
              style: TextStyle(color: kMorado, fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: kMorado),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // WIDGET - FORMULARIO DE CITA
  // ============================================================
  Widget _buildFormularioCita() {
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
                    _editando ? Icons.edit : Icons.calendar_today,
                    size: 18,
                    color: kMorado,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _editando ? 'Editar Cita' : 'Nueva Cita',
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
                ? 'Actualiza los datos de la cita'
                : 'Completa los datos para agendar una cita',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),

          // Servicio
          _buildDropdown(
            label: 'Servicio',
            hint: 'Selecciona un servicio',
            valor: _servicioSeleccionado,
            opciones: _servicios,
            onChanged: (v) => setState(() => _servicioSeleccionado = v),
          ),
          const SizedBox(height: 12),

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
            opciones: _mascotas
                .map((m) => m['nombre'].toString())
                .toList(),
            onChanged: (v) => setState(() => _mascotaSeleccionada = v),
          ),
          const SizedBox(height: 12),

          // Veterinario / responsable
          _buildCampoFormulario(
            label: 'Veterinario / Responsable',
            hint: 'Ej. Dr. Gómez',
            controller: _veterinarioController,
          ),
          const SizedBox(height: 12),

          // Fecha y hora en Row
          Row(
            children: [
              Expanded(
                child: _buildSelectorFecha(
                  label: 'Fecha',
                  valor: _fechaSeleccionada == null
                      ? 'Seleccionar'
                      : _formatearFecha(_fechaSeleccionada!),
                  onTap: _seleccionarFecha,
                  icono: Icons.calendar_today,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSelectorFecha(
                  label: 'Hora',
                  valor: _horaSeleccionada == null
                      ? 'Seleccionar'
                      : _horaSeleccionada!.format(context),
                  onTap: _seleccionarHora,
                  icono: Icons.access_time,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Estado
          _buildDropdown(
            label: 'Estado',
            hint: 'Estado de la cita',
            valor: _estadoSeleccionado,
            opciones: _estados,
            onChanged: (v) =>
                setState(() => _estadoSeleccionado = v ?? 'Pendiente'),
          ),
          const SizedBox(height: 12),

          // Notas
          _buildCampoFormulario(
            label: 'Notas (opcional)',
            hint: 'Ej. Motivo de la consulta',
            controller: _notasController,
          ),
          const SizedBox(height: 16),

          // Botón Guardar
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _editando ? _actualizarCita : _guardarCita,
              style: ElevatedButton.styleFrom(
                backgroundColor: kMorado,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                _editando ? 'Actualizar Cita' : 'Agendar cita',
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
              borderSide: const BorderSide(color: kMorado, width: 2),
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
              borderSide: const BorderSide(color: kMorado, width: 2),
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

  Widget _buildSelectorFecha({
    required String label,
    required String valor,
    required VoidCallback onTap,
    required IconData icono,
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
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: Row(
              children: [
                Icon(icono, size: 16, color: kMorado),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    valor,
                    style: const TextStyle(fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // WIDGET - TARJETA DE CITA
  // ============================================================
  Widget _buildCitaCard(Map<String, dynamic> cita) {
    final estado = cita['estado'] ?? 'Pendiente';
    final colorEstado = _colorEstado(estado);

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
              // Icono de calendario
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: kMorado.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.calendar_today,
                  color: kMorado,
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
                      cita['servicio'] ?? 'Servicio',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${cita['mascota'] ?? ''} · ${cita['hora'] ?? ''}'
                          '${(cita['veterinario'] ?? '').toString().isNotEmpty ? ' · ${cita['veterinario']}' : ''}',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      cita['fecha'] ?? '',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),

              // Badge de estado
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: colorEstado.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_iconoEstado(estado)} $estado',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colorEstado,
                  ),
                ),
              ),
            ],
          ),

          if ((cita['notas'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              cita['notas'],
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
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (estado != 'Cancelada' && estado != 'Completada')
                TextButton.icon(
                  onPressed: () => _cancelarCita(cita['id']),
                  icon: const Icon(Icons.close, size: 16, color: Colors.red),
                  label: const Text(
                    'Cancelar',
                    style: TextStyle(fontSize: 12, color: Colors.red),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              TextButton.icon(
                onPressed: () => _editarCita(cita),
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
                onPressed: () => _eliminarCita(cita['id']),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
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
          Icon(Icons.calendar_today, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No tienes citas agendadas',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Agenda tu primera cita para comenzar',
            style: TextStyle(fontSize: 13, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }
}