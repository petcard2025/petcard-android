// ============================================================
// ADMIN · CITAS SCREEN
// Gestión de todas las citas del sistema
// ============================================================

import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AdminCitasScreen extends StatefulWidget {
  const AdminCitasScreen({super.key});

  @override
  State<AdminCitasScreen> createState() => _AdminCitasScreenState();
}

class _AdminCitasScreenState extends State<AdminCitasScreen> {
  static const Color kAzul = Color(0xFF2563EB);
  static const Color kRojo = Color(0xFFDC2626);
  static const Color kVerde = Color(0xFF16A34A);
  static const Color kAmarillo = Color(0xFFCA8A04);

  final ApiService _api = ApiService();

  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _citas = [];
  List<Map<String, dynamic>> _mascotas = [];
  List<Map<String, dynamic>> _servicios = [];
  List<Map<String, dynamic>> _veterinarios = [];

  String _busqueda = '';
  String _filtroEstado = 'Todos';
  final List<String> _estados = ['Todos', 'Pendiente', 'Confirmada', 'Completada', 'Cancelada'];

  // Formulario
  bool _mostrarFormulario = false;
  bool _editando = false;
  dynamic _citaEditandoId;

  final _mascotaCtrl = TextEditingController();
  final _clienteCtrl = TextEditingController();
  final _servicioCtrl = TextEditingController();
  final _veterinarioCtrl = TextEditingController();
  final _fechaCtrl = TextEditingController();
  final _horaCtrl = TextEditingController();
  final _estadoCtrl = TextEditingController();
  final _motivoCtrl = TextEditingController();
  final _observacionesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  @override
  void dispose() {
    _mascotaCtrl.dispose();
    _clienteCtrl.dispose();
    _servicioCtrl.dispose();
    _veterinarioCtrl.dispose();
    _fechaCtrl.dispose();
    _horaCtrl.dispose();
    _estadoCtrl.dispose();
    _motivoCtrl.dispose();
    _observacionesCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final resultados = await Future.wait([
        _api.obtenerCitasAdmin(),
        _api.obtenerMascotasAdmin(),
        _api.obtenerServicios(),
        _api.obtenerVeterinarios(),
      ]);
      _citas = resultados[0];
      _mascotas = resultados[1];
      _servicios = resultados[2];
      _veterinarios = resultados[3];
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    }
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  List<Map<String, dynamic>> get _citasFiltradas {
    final texto = _busqueda.toLowerCase();
    return _citas.where((c) {
      final combinado = '${c['Nombre_mascota'] ?? ''} ${c['Nombre_cliente'] ?? ''} ${c['Nombre_servicio'] ?? ''}'
          .toLowerCase();
      final coincideBusqueda = combinado.contains(texto);
      final estado = (c['Estado'] ?? 'Pendiente').toString();
      final coincideEstado = _filtroEstado == 'Todos' || estado == _filtroEstado;
      return coincideBusqueda && coincideEstado;
    }).toList();
  }

  void _limpiarFormulario() {
    _mascotaCtrl.clear();
    _clienteCtrl.clear();
    _servicioCtrl.clear();
    _veterinarioCtrl.clear();
    _fechaCtrl.clear();
    _horaCtrl.clear();
    _estadoCtrl.text = 'Pendiente';
    _motivoCtrl.clear();
    _observacionesCtrl.clear();
    _citaEditandoId = null;
    _editando = false;
  }

  void _abrirNuevo() {
    _limpiarFormulario();
    setState(() => _mostrarFormulario = true);
  }

  void _abrirEditar(Map<String, dynamic> cita) {
    _citaEditandoId = cita['ID_cita'];
    _mascotaCtrl.text = (cita['Nombre_mascota'] ?? '').toString();
    _clienteCtrl.text = (cita['Nombre_cliente'] ?? '').toString();
    _servicioCtrl.text = (cita['ID_servicio'] ?? '').toString();
    _veterinarioCtrl.text = (cita['ID_veterinario'] ?? '').toString();
    _fechaCtrl.text = (cita['Fecha'] ?? '').toString();
    _horaCtrl.text = (cita['Hora'] ?? '').toString();
    _estadoCtrl.text = (cita['Estado'] ?? 'Pendiente').toString();
    _motivoCtrl.text = (cita['Motivo'] ?? '').toString();
    _observacionesCtrl.text = (cita['Observaciones'] ?? '').toString();
    _editando = true;
    setState(() => _mostrarFormulario = true);
  }

  Future<void> _guardarCita() async {
    if (_mascotaCtrl.text.trim().isEmpty || _servicioCtrl.text.trim().isEmpty) {
      _mostrarAlerta('Atención', 'Mascota y servicio son obligatorios.');
      return;
    }

    final datos = {
      'ID_mascota': _mascotaCtrl.text.trim(),
      'ID_cliente': _clienteCtrl.text.trim(),
      'ID_servicio': _servicioCtrl.text.trim(),
      'ID_veterinario': _veterinarioCtrl.text.trim(),
      'Fecha': _fechaCtrl.text.trim(),
      'Hora': _horaCtrl.text.trim(),
      'Estado': _estadoCtrl.text.trim(),
      'Motivo': _motivoCtrl.text.trim(),
      'Observaciones': _observacionesCtrl.text.trim(),
    };

    try {
      if (_editando) {
        await _api.actualizarCita(_citaEditandoId, datos);
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
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    } catch (e) {
      _mostrarAlerta('Error', e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _confirmarEliminar(Map<String, dynamic> cita) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar cita?'),
        content: Text('¿Deseas eliminar la cita de ${cita['Nombre_mascota'] ?? ''}?'),
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
    if (confirmar != true) return;
    try {
      await _api.eliminarCita(cita['ID_cita']);
      await _cargarDatos();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🗑️ Cita eliminada'), backgroundColor: Colors.red),
      );
    } catch (e) {
      _mostrarAlerta('Error', e.toString().replaceFirst('Exception: ', ''));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: kAzul,
        elevation: 0,
        title: const Text(
          'Citas · Admin',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirNuevo,
        backgroundColor: kAzul,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Nueva Cita',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: Stack(
        children: [
          _buildBody(),
          if (_mostrarFormulario) _buildFormulario(),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: kAzul));
    }

    return RefreshIndicator(
      onRefresh: _cargarDatos,
      color: kAzul,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Gestión de Citas',
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
              'Administra todas las citas veterinarias',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            _buildBuscadorYFiltro(),
            const SizedBox(height: 16),
            if (_error != null)
              _buildEstadoMensaje(icono: Icons.wifi_off, texto: _error!, color: kRojo)
            else if (_citasFiltradas.isEmpty)
              _buildEstadoMensaje(
                icono: Icons.calendar_today,
                texto: 'No se encontraron citas.',
                color: Colors.grey,
              )
            else
              ..._citasFiltradas.map(_buildCitaCard),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

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

  Widget _buildEstadoMensaje({
    required IconData icono,
    required String texto,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(icono, size: 40, color: color.withOpacity(0.6)),
          const SizedBox(height: 10),
          Text(texto, style: TextStyle(color: Colors.grey[600], fontSize: 13.5)),
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
        border: Border(
          left: BorderSide(color: colorEstado, width: 4),
        ),
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
            '📅 ${c['Fecha'] ?? ''} — 🕐 ${c['Hora'] ?? ''}',
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
                  onPressed: () => _abrirEditar(c),
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
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _confirmarEliminar(c),
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

  // ============================================================
  // FORMULARIO (Modal)
  // ============================================================
  Widget _buildFormulario() {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 500,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _editando ? 'Editar Cita' : 'Nueva Cita',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() => _mostrarFormulario = false);
                          _limpiarFormulario();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildDropdownBusqueda(
                    label: 'Mascota',
                    controller: _mascotaCtrl,
                    opciones: _mascotas.map((m) => m['Nombre']?.toString() ?? '').toList(),
                  ),
                  const SizedBox(height: 12),
                  _campoTexto('Cliente (ID)', _clienteCtrl, hint: 'ID del cliente'),
                  const SizedBox(height: 12),
                  _buildDropdownBusqueda(
                    label: 'Servicio',
                    controller: _servicioCtrl,
                    opciones: _servicios.map((s) => s['Nombre']?.toString() ?? '').toList(),
                  ),
                  const SizedBox(height: 12),
                  _buildDropdownBusqueda(
                    label: 'Veterinario (ID)',
                    controller: _veterinarioCtrl,
                    opciones: _veterinarios.map((v) => v['ID_veterinario']?.toString() ?? '').toList(),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _campoTexto('Fecha', _fechaCtrl, hint: 'YYYY-MM-DD'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _campoTexto('Hora', _horaCtrl, hint: 'HH:MM'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildDropdownBusqueda(
                    label: 'Estado',
                    controller: _estadoCtrl,
                    opciones: ['Pendiente', 'Confirmada', 'Completada', 'Cancelada'],
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
                        _editando ? 'Actualizar' : 'Agregar',
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
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownBusqueda({
    required String label,
    required TextEditingController controller,
    required List<String> opciones,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[700])),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: controller.text.isNotEmpty ? controller.text : null,
              isExpanded: true,
              hint: Text('Selecciona...', style: TextStyle(color: Colors.grey[400])),
              items: opciones.map((opcion) {
                return DropdownMenuItem(
                  value: opcion,
                  child: Text(opcion),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => controller.text = value ?? '');
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _campoTexto(
      String label,
      TextEditingController controller, {
        String? hint,
        int maxLines = 1,
      }) {
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
}