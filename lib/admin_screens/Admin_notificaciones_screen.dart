// ============================================================
// ADMIN · NOTIFICACIONES SCREEN
// ============================================================

import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AdminNotificacionesScreen extends StatefulWidget {
  const AdminNotificacionesScreen({super.key});

  @override
  State<AdminNotificacionesScreen> createState() => _AdminNotificacionesScreenState();
}

class _AdminNotificacionesScreenState extends State<AdminNotificacionesScreen> {
  static const Color kAzul = Color(0xFF2563EB);
  static const Color kRojo = Color(0xFFDC2626);

  final ApiService _api = ApiService();

  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _notificaciones = [];
  List<Map<String, dynamic>> _usuarios = [];

  String _busqueda = '';
  String _filtroTipo = 'Todos';
  String _filtroLeida = 'Todas';
  final List<String> _opcionesLeida = ['Todas', 'Leídas', 'No leídas'];

  dynamic _usuarioSeleccionadoId;
  String _tipoSeleccionado = 'General';
  String _canalSeleccionado = 'Sistema';
  final TextEditingController _mensajeCtrl = TextEditingController();
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  @override
  void dispose() {
    _mensajeCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final resultados = await Future.wait([
        _api.obtenerNotificaciones(),
        _api.obtenerUsuarios(),
      ]);
      _notificaciones = resultados[0];
      _usuarios = resultados[1];
      _notificaciones.sort((a, b) {
        final fa = DateTime.tryParse((a['Fecha_envio'] ?? '').toString()) ?? DateTime(2000);
        final fb = DateTime.tryParse((b['Fecha_envio'] ?? '').toString()) ?? DateTime(2000);
        return fb.compareTo(fa);
      });
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    }
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  List<String> get _tipos {
    final set = <String>{};
    for (final n in _notificaciones) {
      final t = (n['Tipo'] ?? '').toString();
      if (t.isNotEmpty) set.add(t);
    }
    return ['Todos', ...set];
  }

  List<Map<String, dynamic>> get _notificacionesFiltradas {
    final texto = _busqueda.toLowerCase();
    return _notificaciones.where((n) {
      final combinado = '${n['Mensaje'] ?? ''} ${n['Nombre_usuario'] ?? ''}'.toLowerCase();
      final coincideBusqueda = combinado.contains(texto);
      final coincideTipo = _filtroTipo == 'Todos' || n['Tipo'] == _filtroTipo;
      final leida = (num.tryParse('${n['Leida']}') ?? 0) == 1;
      final coincideLeida = _filtroLeida == 'Todas' ||
          (_filtroLeida == 'Leídas' && leida) ||
          (_filtroLeida == 'No leídas' && !leida);
      return coincideBusqueda && coincideTipo && coincideLeida;
    }).toList();
  }

  void _abrirNueva() {
    _usuarioSeleccionadoId = null;
    _tipoSeleccionado = 'General';
    _canalSeleccionado = 'Sistema';
    _mensajeCtrl.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => _buildFormulario(setSheetState),
      ),
    );
  }

  Future<void> _enviarNotificacion() async {
    if (_usuarioSeleccionadoId == null || _mensajeCtrl.text.trim().isEmpty) {
      _mostrarAlerta('Atención', 'Selecciona el usuario y escribe un mensaje.');
      return;
    }
    setState(() => _enviando = true);
    try {
      await _api.crearNotificacion({
        'ID_usuario': _usuarioSeleccionadoId,
        'Mensaje': _mensajeCtrl.text.trim(),
        'Tipo': _tipoSeleccionado,
        'Canal': _canalSeleccionado,
      });
      if (!mounted) return;
      Navigator.pop(context);
      await _cargarDatos();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Notificación enviada'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } catch (e) {
      _mostrarAlerta('Error', e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<void> _marcarLeida(Map<String, dynamic> n) async {
    try {
      await _api.marcarNotificacionLeida(n['ID_notificacion']);
      setState(() => n['Leida'] = 1);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Marcada como leída'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } catch (e) {
      _mostrarAlerta('Error', 'No se pudo marcar como leída.');
    }
  }

  Future<void> _confirmarEliminar(Map<String, dynamic> n) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar notificación?'),
        content: const Text('Esta acción no se puede deshacer.'),
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
      await _api.eliminarNotificacion(n['ID_notificacion']);
      await _cargarDatos();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🗑️ Notificación eliminada'),
          backgroundColor: Colors.red,
        ),
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

  String _iconoTipo(String tipo) {
    final t = tipo.toLowerCase();
    if (t.contains('cita')) return '📅';
    if (t.contains('vacuna')) return '💉';
    if (t.contains('aliment')) return '🍽️';
    return '🔔';
  }

  String _formatearFecha(String? iso) {
    final f = DateTime.tryParse(iso ?? '');
    if (f == null) return '';
    return '${f.day.toString().padLeft(2, '0')}/${f.month.toString().padLeft(2, '0')}/${f.year} '
        '${f.hour.toString().padLeft(2, '0')}:${f.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: kAzul,
        elevation: 0,
        title: const Text(
          'Notificaciones · Admin',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirNueva,
        backgroundColor: kAzul,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Nueva Notificación',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
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
                    'Notificaciones',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: kAzul.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_notificaciones.length}',
                      style: const TextStyle(color: kAzul, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Consulta y envía notificaciones a los usuarios',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              _buildBuscadorYFiltros(),
              const SizedBox(height: 16),
              if (_error != null)
                _buildEstadoMensaje(icono: Icons.wifi_off, texto: _error!, color: kRojo)
              else if (_notificacionesFiltradas.isEmpty)
                _buildEstadoMensaje(
                  icono: Icons.notifications_none,
                  texto: 'No hay notificaciones.',
                  color: Colors.grey,
                )
              else
                ..._notificacionesFiltradas.map(_buildNotifCard),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBuscadorYFiltros() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          onChanged: (v) => setState(() => _busqueda = v),
          decoration: InputDecoration(
            hintText: 'Buscar por mensaje o usuario...',
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
        Row(
          children: [
            Expanded(
              child: _dropdownFiltro(
                'Tipo',
                _filtroTipo,
                _tipos,
                    (v) => setState(() => _filtroTipo = v!),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _dropdownFiltro(
                'Estado',
                _filtroLeida,
                _opcionesLeida,
                    (v) => setState(() => _filtroLeida = v!),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _dropdownFiltro(
      String label,
      String valor,
      List<String> opciones,
      void Function(String?) onChanged,
      ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: valor,
          isExpanded: true,
          icon: const Icon(Icons.expand_more, size: 18),
          items: opciones
              .map(
                (o) => DropdownMenuItem(
              value: o,
              child: Text(o, style: const TextStyle(fontSize: 13)),
            ),
          )
              .toList(),
          onChanged: onChanged,
        ),
      ),
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

  Widget _buildNotifCard(Map<String, dynamic> n) {
    final leida = (num.tryParse('${n['Leida']}') ?? 0) == 1;
    final tipo = (n['Tipo'] ?? '').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border(
          left: BorderSide(
            color: leida ? Colors.grey[300]! : kAzul,
            width: 4,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Opacity(
        opacity: leida ? 0.75 : 1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_iconoTipo(tipo), style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (n['Nombre_usuario'] ?? 'Usuario').toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (tipo.isNotEmpty)
                            _badge(tipo, kAzul, const Color(0xFFEFF6FF)),
                          _badge(
                            (n['Canal'] ?? '').toString(),
                            Colors.grey[700]!,
                            const Color(0xFFF3F4F6),
                          ),
                          if (!leida)
                            _badge('No leída', const Color(0xFFCA8A04), const Color(0xFFFEF9C3)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text((n['Mensaje'] ?? '').toString(), style: const TextStyle(fontSize: 13.5)),
            const SizedBox(height: 6),
            Text(
              _formatearFecha(n['Fecha_envio']?.toString()),
              style: TextStyle(fontSize: 11.5, color: Colors.grey[500]),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                if (!leida) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _marcarLeida(n),
                      icon: const Icon(Icons.done, size: 16),
                      label: const Text('Marcar leída'),
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
                ],
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmarEliminar(n),
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
      ),
    );
  }

  Widget _badge(String texto, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        texto,
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ============================================================
  // FORMULARIO
  // ============================================================
  Widget _buildFormulario(void Function(void Function()) setSheetState) {
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
            mainAxisSize: MainAxisSize.min,
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
                      'Nueva Notificación',
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
              const SizedBox(height: 12),
              _dropdown<dynamic>(
                label: 'Usuario',
                value: _usuarioSeleccionadoId,
                items: _usuarios
                    .map(
                      (u) => DropdownMenuItem(
                    value: u['ID_usuario'],
                    child: Text(
                      '${u['Nombre'] ?? 'Sin nombre'} (${u['Rol'] ?? ''})',
                    ),
                  ),
                )
                    .toList(),
                onChanged: (v) => setSheetState(() => _usuarioSeleccionadoId = v),
              ),
              _dropdown<String>(
                label: 'Tipo',
                value: _tipoSeleccionado,
                items: const [
                  DropdownMenuItem(value: 'General', child: Text('General')),
                  DropdownMenuItem(value: 'cita', child: Text('cita')),
                  DropdownMenuItem(value: 'vacuna', child: Text('vacuna')),
                  DropdownMenuItem(value: 'alimentacion', child: Text('alimentacion')),
                ],
                onChanged: (v) => setSheetState(() => _tipoSeleccionado = v ?? 'General'),
              ),
              _dropdown<String>(
                label: 'Canal',
                value: _canalSeleccionado,
                items: const [
                  DropdownMenuItem(value: 'Sistema', child: Text('Sistema')),
                  DropdownMenuItem(value: 'SMS', child: Text('SMS')),
                ],
                onChanged: (v) => setSheetState(() => _canalSeleccionado = v ?? 'Sistema'),
              ),
              _campoTexto('Mensaje', _mensajeCtrl, hint: 'Escribe el mensaje...', maxLines: 3),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _enviando ? null : _enviarNotificacion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kAzul,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    _enviando ? 'Enviando...' : 'Enviar',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
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

  Widget _dropdown<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
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
              child: DropdownButton<T>(
                value: value,
                isExpanded: true,
                hint: const Text('Selecciona...'),
                items: items,
                onChanged: onChanged,
              ),
            ),
          ),
        ],
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