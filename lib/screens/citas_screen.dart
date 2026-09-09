// ============================================================
// CITAS SCREEN - Gestión de citas del usuario
// ============================================================

import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CitasScreen extends StatefulWidget {
  const CitasScreen({super.key});

  @override
  State<CitasScreen> createState() => _CitasScreenState();
}

class _CitasScreenState extends State<CitasScreen> {
  // ============================================================
  // COLORES
  // ============================================================
  static const Color kAzul = Color(0xFF2563EB);
  static const Color kAzulBg = Color(0xFFEFF6FF);
  static const Color kRojo = Color(0xFFDC2626);
  static const Color kVerde = Color(0xFF16A34A);
  static const Color kAmarillo = Color(0xFFCA8A04);

  // ============================================================
  // VARIABLES DE ESTADO
  // ============================================================
  final ApiService _api = ApiService();

  bool _isLoading = true;
  List<Map<String, dynamic>> _citas = [];
  List<Map<String, dynamic>> _mascotas = [];
  List<Map<String, dynamic>> _servicios = [];
  List<Map<String, dynamic>> _veterinarios = [];
  dynamic _idCliente;

  String _busqueda = '';
  String _filtroEstado = 'Todos';
  final List<String> _estados = ['Todos', 'Pendiente', 'Confirmada', 'Completada', 'Cancelada'];

  // Formulario
  bool _mostrarFormulario = false;
  bool _editando = false;
  Map<String, dynamic>? _citaEditando;

  // Controladores
  final TextEditingController _fechaCtrl = TextEditingController();
  final TextEditingController _horaCtrl = TextEditingController();
  final TextEditingController _estadoCtrl = TextEditingController();
  final TextEditingController _motivoCtrl = TextEditingController();
  final TextEditingController _observacionesCtrl = TextEditingController();

  int? _mascotaSeleccionadaId;
  int? _servicioSeleccionadoId;
  int? _veterinarioSeleccionadoId;

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
    _fechaCtrl.dispose();
    _horaCtrl.dispose();
    _estadoCtrl.dispose();
    _motivoCtrl.dispose();
    _observacionesCtrl.dispose();
    super.dispose();
  }

  // ============================================================
  // CARGA DE DATOS
  // ============================================================
  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);

    try {
      final miUsuario = await _api.obtenerMiUsuario();
      if (miUsuario == null) {
        throw Exception('No hay sesión activa.');
      }
      final idUsuario = miUsuario['ID_usuario'];

      final cliente = await _api.obtenerClientePorUsuario(idUsuario);
      if (cliente == null) {
        throw Exception('Este usuario no tiene un perfil de cliente asociado.');
      }
      _idCliente = cliente['ID_cliente'];

      final todasLasCitas = await _api.obtenerCitasAdmin();
      _citas = todasLasCitas
          .where((c) => c['ID_cliente'].toString() == _idCliente.toString())
          .toList();
      _citas.sort((a, b) {
        final fechaA = '${a['Fecha'] ?? ''} ${a['Hora'] ?? ''}';
        final fechaB = '${b['Fecha'] ?? ''} ${b['Hora'] ?? ''}';
        return fechaA.compareTo(fechaB);
      });

      _mascotas = await _api.obtenerMascotasPorCliente(_idCliente);
      _servicios = await _api.obtenerServicios();
      _veterinarios = await _api.obtenerVeterinarios();
    } catch (e) {
      if (mounted) {
        _mostrarAlerta('Error', '❌ No se pudieron cargar los datos: $e');
      }
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  // ============================================================
  // FUNCIONES DE VALIDACIÓN
  // ============================================================
  bool _validarFormulario() {
    if (_mascotaSeleccionadaId == null) {
      _mostrarAlerta('Atención', 'Selecciona una mascota');
      return false;
    }
    if (_servicioSeleccionadoId == null) {
      _mostrarAlerta('Atención', 'Selecciona un servicio');
      return false;
    }
    if (_veterinarioSeleccionadoId == null) {
      _mostrarAlerta('Atención', 'Selecciona un veterinario');
      return false;
    }
    if (_fechaCtrl.text.trim().isEmpty) {
      _mostrarAlerta('Atención', 'La fecha es obligatoria');
      return false;
    }
    if (_horaCtrl.text.trim().isEmpty) {
      _mostrarAlerta('Atención', 'La hora es obligatoria');
      return false;
    }
    return true;
  }

  // ============================================================
  // GUARDAR CITA
  // ============================================================
  Future<void> _guardarCita() async {
    if (!_validarFormulario()) return;

    final datos = {
      'ID_mascota': _mascotaSeleccionadaId,
      'ID_servicio': _servicioSeleccionadoId,
      'ID_veterinario': _veterinarioSeleccionadoId ?? 0,
      'Fecha': _fechaCtrl.text.trim(),
      'Hora': _horaCtrl.text.trim(),
      'Estado': _estadoCtrl.text.trim().isEmpty ? 'Pendiente' : _estadoCtrl.text.trim(),
      'Motivo': _motivoCtrl.text.trim(),
      'Observaciones': _observacionesCtrl.text.trim(),
    };

    try {
      if (_editando && _citaEditando != null) {
        await _api.actualizarCita(_citaEditando!['ID_cita'], datos);
      } else {
        await _api.crearCita(datos);
      }

      if (!mounted) return;
      setState(() => _mostrarFormulario = false);
      await _cargarDatos();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_editando ? '✅ Cita actualizada' : '✅ Cita creada'),
          backgroundColor: kVerde,
        ),
      );
    } catch (e) {
      _mostrarAlerta('Error', e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // ============================================================
  // CANCELAR / ELIMINAR CITA
  // ============================================================
  Future<void> _cancelarCita(dynamic id) async {
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
            child: const Text('Sí, cancelar', style: TextStyle(color: kRojo)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _api.cambiarEstadoCita(id, 'Cancelada');
        await _cargarDatos();
        if (!mounted) return;
        _mostrarAlerta('Éxito', '✅ Cita cancelada');
      } catch (e) {
        _mostrarAlerta('Error', '❌ Error al cancelar la cita: $e');
      }
    }
  }

  Future<void> _eliminarCita(dynamic id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar cita'),
        content: const Text('¿Estás seguro que deseas eliminar esta cita del historial?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: kRojo)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _api.eliminarCita(id);
        await _cargarDatos();
        if (!mounted) return;
        _mostrarAlerta('Éxito', '✅ Cita eliminada correctamente');
      } catch (e) {
        _mostrarAlerta('Error', '❌ Error al eliminar la cita: $e');
      }
    }
  }

  // ============================================================
  // EDITAR CITA
  // ============================================================
  void _editarCita(Map<String, dynamic> cita) {
    setState(() {
      _citaEditando = cita;
      _editando = true;
      _mostrarFormulario = true;

      _mascotaSeleccionadaId = cita['ID_mascota'];
      _servicioSeleccionadoId = cita['ID_servicio'];
      _veterinarioSeleccionadoId = cita['ID_veterinario'];

      _fechaCtrl.text = (cita['Fecha'] ?? '').toString();
      _horaCtrl.text = (cita['Hora'] ?? '').toString();
      _estadoCtrl.text = (cita['Estado'] ?? 'Pendiente').toString();
      _motivoCtrl.text = (cita['Motivo'] ?? '').toString();
      _observacionesCtrl.text = (cita['Observaciones'] ?? '').toString();
    });
  }

  void _limpiarFormulario() {
    _fechaCtrl.clear();
    _horaCtrl.clear();
    _estadoCtrl.clear();
    _motivoCtrl.clear();
    _observacionesCtrl.clear();
    _mascotaSeleccionadaId = null;
    _servicioSeleccionadoId = null;
    _veterinarioSeleccionadoId = null;
    _citaEditando = null;
    _editando = false;
  }

  void _abrirNuevo() {
    _limpiarFormulario();
    _citaRecienCreada = null;
    setState(() => _mostrarFormulario = true);
  }

  // ============================================================
  // UTILIDADES
  // ============================================================
  Color _colorEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'confirmada':
        return kVerde;
      case 'completada':
        return Colors.grey;
      case 'cancelada':
        return kRojo;
      default:
        return kAmarillo;
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

  String _formatearFecha(String? fechaRaw) {
    if (fechaRaw == null || fechaRaw.isEmpty) return '';
    try {
      final dt = DateTime.parse(fechaRaw);
      const meses = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
      return '${dt.day} ${meses[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return fechaRaw;
    }
  }

  String _recortarHora(String? horaRaw) {
    if (horaRaw == null || horaRaw.isEmpty) return '';
    return horaRaw.length >= 5 ? horaRaw.substring(0, 5) : horaRaw;
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
  // BUILD
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
            onPressed: _abrirNuevo,
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
            // Título
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: kAzul.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_citas.length} citas',
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
              'Agenda y consulta las citas de tus mascotas',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),

            // Buscador y filtros
            _buildBuscadorYFiltro(),
            const SizedBox(height: 16),

            // Formulario
            if (_mostrarFormulario) _buildFormularioCita(),

            // Lista de citas
            if (!_mostrarFormulario) ...[
              if (_citas.isEmpty)
                _buildEmptyState()
              else
                ..._citas.where((c) {
                  final texto = '${c['Nombre_mascota'] ?? ''} ${c['Nombre_cliente'] ?? ''} ${c['Nombre_servicio'] ?? ''}'
                      .toLowerCase();
                  final coincideBusqueda = texto.contains(_busqueda.toLowerCase());
                  final estado = (c['Estado'] ?? 'Pendiente').toString();
                  final coincideEstado = _filtroEstado == 'Todos' || estado == _filtroEstado;
                  return coincideBusqueda && coincideEstado;
                }).map(_buildCitaCard),
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // WIDGETS
  // ============================================================
  Widget _buildBuscadorYFiltro() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          onChanged: (v) => setState(() => _busqueda = v),
          decoration: InputDecoration(
            hintText: 'Buscar por mascota, cliente o servicio...',
            prefixIcon: const Icon(Icons.search, size: 20),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: kAzul, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _estados.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final estado = _estados[i];
              final activo = _filtroEstado == estado;
              return ChoiceChip(
                label: Text(estado),
                selected: activo,
                onSelected: (_) => setState(() => _filtroEstado = estado),
                selectedColor: kAzul,
                backgroundColor: Colors.white,
                labelStyle: TextStyle(
                  color: activo ? Colors.white : Colors.grey[700],
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: activo ? kAzul : Colors.grey[300]!),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFormularioCita() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(_editando ? Icons.edit : Icons.calendar_today, size: 18, color: kAzul),
                  const SizedBox(width: 8),
                  Text(
                    _editando ? 'Editar Cita' : 'Nueva Cita',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
            _editando ? 'Actualiza los datos de la cita' : 'Completa los datos para agendar una cita',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),

          // Mascota
          _buildDropdown(
            label: 'Mascota',
            hint: 'Selecciona la mascota',
            value: _mascotaSeleccionadaId,
            items: _mascotas.map((m) {
              return DropdownMenuItem<int>(
                value: m['ID_mascota'],
                child: Text(m['Nombre'] ?? 'Sin nombre'),
              );
            }).toList(),
            onChanged: (v) => setState(() => _mascotaSeleccionadaId = v),
          ),
          const SizedBox(height: 12),

          // Servicio
          _buildDropdown(
            label: 'Servicio',
            hint: 'Selecciona un servicio',
            value: _servicioSeleccionadoId,
            items: _servicios.map((s) {
              return DropdownMenuItem<int>(
                value: s['ID_servicio'],
                child: Text(s['Nombre'] ?? 'Sin nombre'),
              );
            }).toList(),
            onChanged: (v) => setState(() => _servicioSeleccionadoId = v),
          ),
          const SizedBox(height: 12),

          // Veterinario
          _buildDropdown(
            label: 'Veterinario',
            hint: 'Selecciona un veterinario',
            value: _veterinarioSeleccionadoId,
            items: _veterinarios.map((v) {
              return DropdownMenuItem<int>(
                value: v['ID_veterinario'],
                child: Text(v['Nombre'] ?? 'Sin nombre'),
              );
            }).toList(),
            onChanged: (v) => setState(() => _veterinarioSeleccionadoId = v),
          ),
          const SizedBox(height: 12),

          // Fecha y Hora
          Row(
            children: [
              Expanded(child: _campoTexto('Fecha', _fechaCtrl, hint: 'YYYY-MM-DD')),
              const SizedBox(width: 12),
              Expanded(child: _campoTexto('Hora', _horaCtrl, hint: 'HH:MM')),
            ],
          ),
          const SizedBox(height: 12),

          // Estado
          _buildDropdown(
            label: 'Estado',
            hint: 'Selecciona un estado',
            value: _estadoCtrl.text.isNotEmpty ? _estadoCtrl.text : null,
            items: ['Pendiente', 'Confirmada', 'Completada', 'Cancelada'].map((estado) {
              return DropdownMenuItem<String>(
                value: estado,
                child: Text(estado),
              );
            }).toList(),
            onChanged: (v) => setState(() => _estadoCtrl.text = v ?? ''),
          ),
          const SizedBox(height: 12),

          _campoTexto('Motivo', _motivoCtrl, hint: 'Motivo de la cita'),
          const SizedBox(height: 12),
          _campoTexto('Observaciones', _observacionesCtrl, hint: 'Notas adicionales', maxLines: 2),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _guardarCita,
              style: ElevatedButton.styleFrom(
                backgroundColor: kAzul,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                _editando ? 'Actualizar' : 'Agendar cita',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required String hint,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[700])),
        const SizedBox(height: 4),
        DropdownButtonFormField<T>(
          value: value,
          isExpanded: true,
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
          items: items,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _campoTexto(String label, TextEditingController controller, {String? hint, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[700])),
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
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _abrirNuevo,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Agendar cita'),
            style: ElevatedButton.styleFrom(
              backgroundColor: kAzul,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCitaCard(Map<String, dynamic> c) {
    final estado = (c['Estado'] ?? 'Pendiente').toString();
    final colorEstado = _colorEstado(estado);

    return Container(
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
        border: Border(left: BorderSide(color: colorEstado, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c['Nombre_mascota'] ?? 'Sin mascota',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    Text(
                      c['Nombre_cliente'] ?? 'Sin cliente',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colorEstado.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_iconoEstado(estado)} $estado',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: colorEstado,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            c['Nombre_servicio'] ?? 'Sin servicio',
            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
          ),
          Text(
            'con ${c['Nombre_veterinario'] ?? 'Sin veterinario'}',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          Text(
            '📅 ${_formatearFecha(c['Fecha'])} — 🕐 ${_recortarHora(c['Hora'])}',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          if ((c['Motivo'] ?? '').toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '📝 ${c['Motivo']}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _editarCita(c),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Editar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kAzul,
                    side: const BorderSide(color: kAzul),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (estado != 'Cancelada' && estado != 'Completada')
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _cancelarCita(c['ID_cita']),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Cancelar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kRojo,
                      side: const BorderSide(color: kRojo),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _eliminarCita(c['ID_cita']),
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('Eliminar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kRojo,
                    side: const BorderSide(color: kRojo),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}