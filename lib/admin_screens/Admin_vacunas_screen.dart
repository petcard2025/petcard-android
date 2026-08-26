// ============================================================
// ADMIN · VACUNAS SCREEN (Carnet de Vacunas)
// Gestión de todas las vacunas del sistema
// ============================================================

import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AdminVacunasScreen extends StatefulWidget {
  const AdminVacunasScreen({super.key});

  @override
  State<AdminVacunasScreen> createState() => _AdminVacunasScreenState();
}

class _AdminVacunasScreenState extends State<AdminVacunasScreen> {
  static const Color kAzul = Color(0xFF2563EB);
  static const Color kRojo = Color(0xFFDC2626);

  final ApiService _api = ApiService();

  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _vacunas = [];
  List<Map<String, dynamic>> _mascotas = [];
  List<Map<String, dynamic>> _servicios = [];

  String _busqueda = '';
  String _filtroEstado = 'Todos';
  final List<String> _estados = ['Todos', 'Pendiente', 'Completada', 'Aplicada'];

  // Formulario
  bool _mostrarFormulario = false;
  bool _editando = false;
  dynamic _vacunaEditandoId;

  final _mascotaCtrl = TextEditingController();
  final _servicioCtrl = TextEditingController();
  final _nombreVacunaCtrl = TextEditingController();
  final _loteCtrl = TextEditingController();
  final _fechaAplicacionCtrl = TextEditingController();
  final _proximaDosisCtrl = TextEditingController();
  final _estadoCtrl = TextEditingController();
  final _observacionesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  @override
  void dispose() {
    _mascotaCtrl.dispose();
    _servicioCtrl.dispose();
    _nombreVacunaCtrl.dispose();
    _loteCtrl.dispose();
    _fechaAplicacionCtrl.dispose();
    _proximaDosisCtrl.dispose();
    _estadoCtrl.dispose();
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
        _api.obtenerVacunas(),
        _api.obtenerMascotasAdmin(),
        _api.obtenerServicios(),
      ]);
      _vacunas = resultados[0];
      _mascotas = resultados[1];
      _servicios = resultados[2];
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    }
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  List<Map<String, dynamic>> get _vacunasFiltradas {
    final texto = _busqueda.toLowerCase();
    return _vacunas.where((v) {
      final combinado = '${v['Nombre_mascota'] ?? ''} ${v['Nombre_vacuna'] ?? ''}'
          .toLowerCase();
      final coincideBusqueda = combinado.contains(texto);
      final estado = (v['Estado'] ?? 'Pendiente').toString();
      final coincideEstado = _filtroEstado == 'Todos' || estado == _filtroEstado;
      return coincideBusqueda && coincideEstado;
    }).toList();
  }

  void _limpiarFormulario() {
    _mascotaCtrl.clear();
    _servicioCtrl.clear();
    _nombreVacunaCtrl.clear();
    _loteCtrl.clear();
    _fechaAplicacionCtrl.clear();
    _proximaDosisCtrl.clear();
    _estadoCtrl.text = 'Pendiente';
    _observacionesCtrl.clear();
    _vacunaEditandoId = null;
    _editando = false;
  }

  void _abrirNuevo() {
    _limpiarFormulario();
    setState(() => _mostrarFormulario = true);
  }

  void _abrirEditar(Map<String, dynamic> v) {
    _vacunaEditandoId = v['ID_carnetVacunas'];
    _mascotaCtrl.text = (v['Nombre_mascota'] ?? '').toString();
    _servicioCtrl.text = (v['ID_servicio'] ?? '').toString();
    _nombreVacunaCtrl.text = (v['Nombre_vacuna'] ?? '').toString();
    _loteCtrl.text = (v['Lote'] ?? '').toString();
    _fechaAplicacionCtrl.text = (v['Fecha_aplicacion'] ?? '').toString();
    _proximaDosisCtrl.text = (v['Proxima_dosis'] ?? '').toString();
    _estadoCtrl.text = (v['Estado'] ?? 'Pendiente').toString();
    _observacionesCtrl.text = (v['Observaciones'] ?? '').toString();
    _editando = true;
    setState(() => _mostrarFormulario = true);
  }

  Future<void> _guardarVacuna() async {
    if (_mascotaCtrl.text.trim().isEmpty || _nombreVacunaCtrl.text.trim().isEmpty) {
      _mostrarAlerta('Atención', 'Mascota y nombre de vacuna son obligatorios.');
      return;
    }

    final datos = {
      'ID_mascota': _mascotaCtrl.text.trim(),
      'ID_servicio': _servicioCtrl.text.trim(),
      'Nombre_vacuna': _nombreVacunaCtrl.text.trim(),
      'Lote': _loteCtrl.text.trim(),
      'Fecha_aplicacion': _fechaAplicacionCtrl.text.trim().isEmpty
          ? null
          : _fechaAplicacionCtrl.text.trim(),
      'Proxima_dosis': _proximaDosisCtrl.text.trim().isEmpty
          ? null
          : _proximaDosisCtrl.text.trim(),
      'Estado': _estadoCtrl.text.trim(),
      'Observaciones': _observacionesCtrl.text.trim(),
    };

    try {
      if (_editando) {
        await _api.actualizarVacuna(_vacunaEditandoId, datos);
      } else {
        await _api.crearVacuna(datos);
      }
      if (!mounted) return;
      setState(() => _mostrarFormulario = false);
      await _cargarDatos();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_editando ? '✅ Vacuna actualizada' : '✅ Vacuna registrada'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    } catch (e) {
      _mostrarAlerta('Error', e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _confirmarEliminar(Map<String, dynamic> v) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar vacuna?'),
        content: Text('¿Deseas eliminar la vacuna "${v['Nombre_vacuna'] ?? ''}"?'),
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
      await _api.eliminarVacuna(v['ID_carnetVacunas']);
      await _cargarDatos();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🗑️ Vacuna eliminada'), backgroundColor: Colors.red),
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

  String _getEstadoColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'completada':
        return '#10B981';
      case 'aplicada':
        return '#10B981';
      case 'pendiente':
        return '#CA8A04';
      default:
        return '#94A3B8';
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
          'Carnet de Vacunas · Admin',
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
          'Nuevo Registro',
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
                  'Vacunas Registradas',
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
                    '${_vacunas.length} registros',
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
              'Administra el carnet de vacunas de todas las mascotas',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            _buildBuscadorYFiltro(),
            const SizedBox(height: 16),
            if (_error != null)
              _buildEstadoMensaje(icono: Icons.wifi_off, texto: _error!, color: kRojo)
            else if (_vacunasFiltradas.isEmpty)
              _buildEstadoMensaje(
                icono: Icons.medical_services_outlined,
                texto: 'No se encontraron registros.',
                color: Colors.grey,
              )
            else
              ..._vacunasFiltradas.map(_buildVacunaCard),
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
            hintText: 'Buscar por mascota o vacuna...',
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

  Widget _buildVacunaCard(Map<String, dynamic> v) {
    final estado = (v['Estado'] ?? 'Pendiente').toString();
    final colorEstado = _getEstadoColor(estado);

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
          left: BorderSide(
            color: Color(int.parse('0xFF${colorEstado.substring(1)}')),
            width: 4,
          ),
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
                      v['Nombre_mascota'] ?? 'Sin mascota',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    Text(
                      v['Nombre_vacuna'] ?? 'Sin vacuna',
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Color(int.parse('0xFF${colorEstado.substring(1)}'))
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  estado.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(int.parse('0xFF${colorEstado.substring(1)}')),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (v['Lote'] != null && v['Lote'].toString().isNotEmpty)
            Text(
              'Lote: ${v['Lote']}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          if (v['Fecha_aplicacion'] != null)
            Text(
              '📅 Aplicada: ${v['Fecha_aplicacion']}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          if (v['Proxima_dosis'] != null)
            Text(
              '⏳ Próxima: ${v['Proxima_dosis']}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          if (v['Observaciones'] != null && v['Observaciones'].toString().isNotEmpty)
            Text(
              '📝 ${v['Observaciones']}',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _abrirEditar(v),
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
                  onPressed: () => _confirmarEliminar(v),
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
                        _editando ? 'Editar Vacuna' : 'Nueva Vacuna',
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
                  _buildDropdownBusqueda(
                    label: 'Servicio',
                    controller: _servicioCtrl,
                    opciones: _servicios.map((s) => s['Nombre']?.toString() ?? '').toList(),
                  ),
                  const SizedBox(height: 12),
                  _campoTexto('Nombre de la vacuna', _nombreVacunaCtrl, hint: 'Ej. Antirrábica'),
                  const SizedBox(height: 12),
                  _campoTexto('Lote', _loteCtrl, hint: 'Ej. A123'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _campoTexto('Fecha aplicación', _fechaAplicacionCtrl, hint: 'YYYY-MM-DD'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _campoTexto('Próxima dosis', _proximaDosisCtrl, hint: 'YYYY-MM-DD'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildDropdownBusqueda(
                    label: 'Estado',
                    controller: _estadoCtrl,
                    opciones: ['Pendiente', 'Completada', 'Aplicada'],
                  ),
                  const SizedBox(height: 12),
                  _campoTexto('Observaciones', _observacionesCtrl, hint: 'Notas adicionales', maxLines: 2),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _guardarVacuna,
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
        TextInputType keyboardType = TextInputType.text,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[700])),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
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