// ============================================================
// ADMIN · SERVICIOS SCREEN
// Gestión de todos los servicios veterinarios del sistema.
// Mismo diseño que el resto de la app (AppBar azul, cards
// blancas con sombra suave, bottom sheets para formularios),
// consumiendo el backend real como el panel admin de la web.
// ============================================================

import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AdminServiciosScreen extends StatefulWidget {
  const AdminServiciosScreen({super.key});

  @override
  State<AdminServiciosScreen> createState() => _AdminServiciosScreenState();
}

class _AdminServiciosScreenState extends State<AdminServiciosScreen> {
  // ============================================================
  // COLORES (igual que el resto de la app)
  // ============================================================
  static const Color kAzul = Color(0xFF2563EB);
  static const Color kVerde = Color(0xFF16A34A);
  static const Color kVerdeBg = Color(0xFFDCFCE7);
  static const Color kRojo = Color(0xFFDC2626);

  final ApiService _api = ApiService();

  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _servicios = [];
  String _busqueda = '';

  final _nombreCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  final _categoriaCtrl = TextEditingController();
  dynamic _servicioEnEdicionId;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descripcionCtrl.dispose();
    _categoriaCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      _servicios = await _api.obtenerServicios();
    } catch (e) {
      _error = 'No se pudo conectar con el servidor.';
    }
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  List<Map<String, dynamic>> get _serviciosFiltrados {
    final texto = _busqueda.toLowerCase();
    return _servicios.where((s) {
      final combinado =
      '${s['Nombre'] ?? ''} ${s['Descripcion'] ?? ''} ${s['Categoria'] ?? ''}'.toLowerCase();
      return combinado.contains(texto);
    }).toList();
  }

  // ============================================================
  // ACCIONES
  // ============================================================
  void _limpiarFormulario() {
    _nombreCtrl.clear();
    _descripcionCtrl.clear();
    _categoriaCtrl.clear();
    _servicioEnEdicionId = null;
  }

  void _abrirNuevo() {
    _limpiarFormulario();
    _abrirFormulario();
  }

  void _abrirEditar(Map<String, dynamic> s) {
    _nombreCtrl.text = (s['Nombre'] ?? '').toString();
    _descripcionCtrl.text = (s['Descripcion'] ?? '').toString();
    _categoriaCtrl.text = (s['Categoria'] ?? '').toString();
    _servicioEnEdicionId = s['ID_servicio'];
    _abrirFormulario();
  }

  void _abrirFormulario() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildFormulario(),
    );
  }

  Future<void> _guardarServicio() async {
    if (_nombreCtrl.text.trim().isEmpty) {
      _mostrarAlerta('Atención', 'El nombre es obligatorio.');
      return;
    }
    final datos = {
      'Nombre': _nombreCtrl.text.trim(),
      'Descripcion': _descripcionCtrl.text.trim(),
      'Categoria': _categoriaCtrl.text.trim(),
    };

    try {
      if (_servicioEnEdicionId == null) {
        await _api.crearServicio(datos);
      } else {
        await _api.actualizarServicio(_servicioEnEdicionId, datos);
      }
      if (!mounted) return;
      Navigator.pop(context);
      await _cargarDatos();
      if (!mounted) return;
      _mostrarSnack(_servicioEnEdicionId == null ? 'Servicio creado correctamente' : 'Servicio actualizado');
    } catch (e) {
      _mostrarAlerta('Error', e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _confirmarEliminar(Map<String, dynamic> s) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar servicio?'),
        content: Text(
          '¿Deseas eliminar "${s['Nombre'] ?? ''}"? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: kRojo)),
          ),
        ],
      ),
    );
    if (confirmar != true) return;

    try {
      await _api.eliminarServicio(s['ID_servicio']);
      await _cargarDatos();
      if (!mounted) return;
      _mostrarSnack('Servicio eliminado');
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  void _mostrarSnack(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  // ============================================================
  // UI
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: kAzul,
        elevation: 0,
        title: const Text(
          'Servicios · Admin',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirNuevo,
        backgroundColor: kAzul,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nuevo Servicio', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Gestión de Servicios',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: kAzul.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_servicios.length} servicios',
                      style: const TextStyle(color: kAzul, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Administra todos los servicios veterinarios disponibles',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              TextField(
                onChanged: (v) => setState(() => _busqueda = v),
                decoration: InputDecoration(
                  hintText: 'Buscar servicios...',
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
              const SizedBox(height: 16),
              if (_error != null)
                _buildEstadoMensaje(icono: Icons.wifi_off, texto: _error!, color: kRojo)
              else if (_serviciosFiltrados.isEmpty)
                _buildEstadoMensaje(
                  icono: Icons.medical_services_outlined,
                  texto: 'No se encontraron servicios.',
                  color: Colors.grey,
                )
              else
                ..._serviciosFiltrados.map(_buildServicioCard),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEstadoMensaje({required IconData icono, required String texto, required Color color}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(icono, size: 40, color: color.withValues(alpha: 0.6)),
          const SizedBox(height: 10),
          Text(texto, style: TextStyle(color: Colors.grey[600], fontSize: 13.5)),
        ],
      ),
    );
  }

  Widget _buildServicioCard(Map<String, dynamic> s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: kAzul.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.medical_services_outlined, color: kAzul, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (s['Nombre'] ?? 'Servicio').toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15.5),
                    ),
                    if ((s['Categoria'] ?? '').toString().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          (s['Categoria']).toString(),
                          style: TextStyle(color: Colors.grey[600], fontSize: 12.5),
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: kVerdeBg, borderRadius: BorderRadius.circular(20)),
                child: const Text(
                  'ACTIVO',
                  style: TextStyle(color: kVerde, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          if ((s['Descripcion'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              (s['Descripcion']).toString(),
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _abrirEditar(s),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Editar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kAzul,
                    side: const BorderSide(color: kAzul),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _confirmarEliminar(s),
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('Eliminar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kRojo,
                    side: const BorderSide(color: kRojo),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // FORMULARIO (bottom sheet) crear / editar
  // ------------------------------------------------------------
  Widget _buildFormulario() {
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
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(4)),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _servicioEnEdicionId == null ? 'Nuevo Servicio' : 'Editar Servicio',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
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
              const SizedBox(height: 12),
              _campoTexto('Nombre', _nombreCtrl, hint: 'Ej. Consulta general'),
              _campoTexto('Descripción', _descripcionCtrl, hint: 'Breve descripción del servicio', maxLines: 3),
              _campoTexto('Categoría', _categoriaCtrl, hint: 'Ej. Consulta, Vacunación...'),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _guardarServicio,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kAzul,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    _servicioEnEdicionId == null ? 'Crear Servicio' : 'Guardar Cambios',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
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

  Widget _campoTexto(String label, TextEditingController controller, {String? hint, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
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
      ),
    );
  }
}