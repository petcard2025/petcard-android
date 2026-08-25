// ============================================================
// ADMIN · USUARIOS SCREEN
// Consulta y administra el nombre y rol de todos los usuarios.
// Mismo diseño que el resto de la app (AppBar azul, cards
// blancas con sombra suave), consumiendo el backend real como
// el panel admin de la web.
// ============================================================

import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AdminUsuariosScreen extends StatefulWidget {
  const AdminUsuariosScreen({super.key});

  @override
  State<AdminUsuariosScreen> createState() => _AdminUsuariosScreenState();
}

class _AdminUsuariosScreenState extends State<AdminUsuariosScreen> {
  // ============================================================
  // COLORES (igual que el resto de la app)
  // ============================================================
  static const Color kAzul = Color(0xFF2563EB);
  static const Color kAzulBg = Color(0xFFEFF6FF);
  static const Color kVerde = Color(0xFF16A34A);
  static const Color kVerdeBg = Color(0xFFDCFCE7);
  static const Color kGris = Color(0xFF6B7280);
  static const Color kGrisBg = Color(0xFFF3F4F6);
  static const Color kRojo = Color(0xFFDC2626);

  final ApiService _api = ApiService();

  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _usuarios = [];

  String _busqueda = '';
  String _filtroRol = 'Todos';
  final List<String> _roles = ['Todos', 'administrador', 'veterinario', 'cliente'];

  // Edición inline
  dynamic _editandoId;
  final _nombreEditCtrl = TextEditingController();
  String _rolEditado = 'cliente';
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _cargarUsuarios();
  }

  @override
  void dispose() {
    _nombreEditCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarUsuarios() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      _usuarios = await _api.obtenerUsuarios();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    }
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  List<Map<String, dynamic>> get _usuariosFiltrados {
    final texto = _busqueda.toLowerCase();
    return _usuarios.where((u) {
      final combinado = '${u['Nombre'] ?? ''} ${u['Correo'] ?? ''}'.toLowerCase();
      final coincideBusqueda = combinado.contains(texto);
      final coincideRol = _filtroRol == 'Todos' || u['Rol'] == _filtroRol;
      return coincideBusqueda && coincideRol;
    }).toList();
  }

  // ============================================================
  // ACCIONES
  // ============================================================
  void _abrirEdicion(Map<String, dynamic> u) {
    setState(() {
      _editandoId = u['ID_usuario'];
      _nombreEditCtrl.text = (u['Nombre'] ?? '').toString();
      _rolEditado = (u['Rol'] ?? 'cliente').toString();
    });
  }

  void _cancelarEdicion() {
    setState(() => _editandoId = null);
  }

  Future<void> _guardarEdicion(dynamic id) async {
    setState(() => _guardando = true);
    try {
      await _api.actualizarUsuario(id, {
        'Nombre': _nombreEditCtrl.text.trim(),
        'Rol': _rolEditado,
      });
      _editandoId = null;
      await _cargarUsuarios();
      if (!mounted) return;
      _mostrarSnack('Usuario actualizado');
    } catch (e) {
      _mostrarAlerta('Error', e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _confirmarEliminar(Map<String, dynamic> u) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar usuario?'),
        content: Text(
          '¿Deseas eliminar a ${u['Nombre'] ?? ''}? Esta acción no se puede deshacer.',
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
      await _api.eliminarUsuario(u['ID_usuario']);
      await _cargarUsuarios();
      if (!mounted) return;
      _mostrarSnack('Usuario eliminado');
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

  Color _colorRol(String rol) {
    if (rol == 'administrador') return kAzul;
    if (rol == 'veterinario') return kVerde;
    return kGris;
  }

  Color _bgRol(String rol) {
    if (rol == 'administrador') return kAzulBg;
    if (rol == 'veterinario') return kVerdeBg;
    return kGrisBg;
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
          'Usuarios · Admin',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: kAzul))
          : RefreshIndicator(
        onRefresh: _cargarUsuarios,
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
                    'Gestión de Usuarios',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: kAzul.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_usuarios.length} usuarios',
                      style: const TextStyle(color: kAzul, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Consulta y administra el nombre y rol de todos los usuarios',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              _buildBuscadorYFiltro(),
              const SizedBox(height: 16),
              if (_error != null)
                _buildEstadoMensaje(icono: Icons.wifi_off, texto: _error!, color: kRojo)
              else if (_usuariosFiltrados.isEmpty)
                _buildEstadoMensaje(
                  icono: Icons.people_outline,
                  texto: 'No se encontraron usuarios.',
                  color: Colors.grey,
                )
              else
                ..._usuariosFiltrados.map(_buildUsuarioCard),
              const SizedBox(height: 24),
            ],
          ),
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
            hintText: 'Buscar por nombre o correo...',
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
            itemCount: _roles.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final rol = _roles[i];
              final activo = _filtroRol == rol;
              return ChoiceChip(
                label: Text(rol),
                selected: activo,
                onSelected: (_) => setState(() => _filtroRol = rol),
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

  Widget _buildUsuarioCard(Map<String, dynamic> u) {
    final id = u['ID_usuario'];
    final editando = _editandoId == id;
    final rolActual = (u['Rol'] ?? 'cliente').toString();
    final iniciales = (u['Nombre'] ?? '?')
        .toString()
        .split(' ')
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0])
        .join()
        .toUpperCase();

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
              CircleAvatar(
                radius: 20,
                backgroundColor: _colorRol(rolActual).withValues(alpha: 0.15),
                child: Text(
                  iniciales.isEmpty ? '?' : iniciales,
                  style: TextStyle(color: _colorRol(rolActual), fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    editando
                        ? TextField(
                      controller: _nombreEditCtrl,
                      style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                    )
                        : Text(
                      (u['Nombre'] ?? 'Sin nombre').toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      (u['Correo'] ?? '').toString(),
                      style: TextStyle(color: Colors.grey[600], fontSize: 12.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (editando) ...[
            Text('Rol', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.grey[700])),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: kGrisBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _rolEditado,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'administrador', child: Text('administrador')),
                    DropdownMenuItem(value: 'veterinario', child: Text('veterinario')),
                    DropdownMenuItem(value: 'cliente', child: Text('cliente')),
                  ],
                  onChanged: (v) => setState(() => _rolEditado = v ?? 'cliente'),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _guardando ? null : () => _guardarEdicion(id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kAzul,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                      _guardando ? 'Guardando...' : 'Guardar',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _guardando ? null : _cancelarEdicion,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[700],
                      side: BorderSide(color: Colors.grey[400]!),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Cancelar'),
                  ),
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: _bgRol(rolActual), borderRadius: BorderRadius.circular(20)),
                  child: Text(
                    rolActual,
                    style: TextStyle(color: _colorRol(rolActual), fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _abrirEdicion(u),
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
                    onPressed: () => _confirmarEliminar(u),
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
        ],
      ),
    );
  }
}