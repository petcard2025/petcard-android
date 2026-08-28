// ============================================================
// NOTIFICACIONES SCREEN - Réplica de la vista web
// (frontend/src/components/usuario/notificaciones.vue)
// Conectada al backend real vía ApiService, igual que Alimentación.
// ============================================================

import 'package:flutter/material.dart';
import '../services/api_service.dart';

class NotificacionesScreen extends StatefulWidget {
  const NotificacionesScreen({super.key});

  @override
  State<NotificacionesScreen> createState() => _NotificacionesScreenState();
}

class _Categoria {
  final String id;
  final String label;
  final String emoji;
  const _Categoria(this.id, this.label, this.emoji);
}

class _NotificacionesScreenState extends State<NotificacionesScreen> {
  // Colores (igual que el resto de la app)
  static const Color kAzul = Color(0xFF2563EB);
  static const Color kIndigo = Color(0xFF6366F1);
  static const Color kIndigoDark = Color(0xFF4338CA);
  static const Color kRojo = Color(0xFFEF4444);
  static const Color kVerde = Color(0xFF22C55E);
  static const Color kGrisTexto = Color(0xFF64748B);
  static const Color kGrisClaro = Color(0xFF94A3B8);
  static const Color kFondo = Color(0xFFF8F9FA);
  static const Color kBorde = Color(0xFFE2E8F0);

  static const List<_Categoria> _categorias = [
    _Categoria('todas', 'Todas', '🔔'),
    _Categoria('cita', 'Citas', '📅'),
    _Categoria('vacuna', 'Vacunas', '💉'),
    _Categoria('alimentacion', 'Alimentación', '🍖'),
    _Categoria('medicamentos', 'Medicamentos', '💊'),
    _Categoria('resultados', 'Resultados', '📋'),
  ];

  final ApiService _api = ApiService();

  bool _isLoading = true;
  String? _error;
  String _categoriaActiva = 'todas';
  List<Map<String, dynamic>> _notificaciones = [];

  @override
  void initState() {
    super.initState();
    _cargarNotificaciones();
  }

  Future<void> _cargarNotificaciones() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      _notificaciones = await _api.obtenerMisNotificaciones();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      debugPrint('Error cargando notificaciones: $e');
    }
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  // ------------------------------------------------------------
  // Categorización (igual lógica que en la web)
  // ------------------------------------------------------------
  String _categoriaDe(Map<String, dynamic> n) {
    final texto = '${n['Mensaje'] ?? ''} ${n['Tipo'] ?? ''}'.toLowerCase();
    if (texto.contains('cita')) return 'cita';
    if (texto.contains('vacuna')) return 'vacuna';
    if (texto.contains('aliment')) return 'alimentacion';
    if (texto.contains('medic') || texto.contains('dosis')) return 'medicamentos';
    if (texto.contains('resultado') || texto.contains('analisis')) return 'resultados';
    return 'sistema';
  }

  bool _leida(Map<String, dynamic> n) {
    final v = n['Leida'];
    return v == true || v == 1 || v == '1';
  }

  String _emojiCategoria(String cat) {
    const map = {
      'cita': '📅',
      'vacuna': '💉',
      'alimentacion': '🍖',
      'medicamentos': '💊',
      'resultados': '📋',
      'sistema': '🔔',
    };
    return map[cat] ?? '🔔';
  }

  Color _colorCategoria(String cat) {
    const map = {
      'cita': Color(0xFF4338CA), // indigo
      'vacuna': Color(0xFF166534), // verde
      'alimentacion': Color(0xFFC2410C), // naranja
      'medicamentos': Color(0xFF5B21B6), // morado
      'resultados': Color(0xFF92400E), // amarillo/ámbar
    };
    return map[cat] ?? const Color(0xFF374151);
  }

  Color _bgCategoria(String cat) {
    const map = {
      'cita': Color(0xFFEEF2FF),
      'vacuna': Color(0xFFDCFCE7),
      'alimentacion': Color(0xFFFFEDD5),
      'medicamentos': Color(0xFFEDE9FE),
      'resultados': Color(0xFFFEF9C3),
    };
    return map[cat] ?? const Color(0xFFF3F4F6);
  }

  String _tiempoRelativo(dynamic fechaRaw) {
    if (fechaRaw == null || fechaRaw.toString().isEmpty) return '';
    try {
      final fecha = DateTime.parse(fechaRaw.toString());
      final diff = DateTime.now().difference(fecha);
      final mins = diff.inMinutes;
      if (mins < 1) return 'Ahora mismo';
      if (mins < 60) return 'Hace $mins min';
      final horas = diff.inHours;
      if (horas < 24) return 'Hace $horas h';
      final dias = diff.inDays;
      return 'Hace $dias día${dias > 1 ? 's' : ''}';
    } catch (_) {
      return '';
    }
  }

  String _fechaFormateada(dynamic fechaRaw) {
    if (fechaRaw == null || fechaRaw.toString().isEmpty) return '';
    try {
      final f = DateTime.parse(fechaRaw.toString());
      const meses = [
        'ene', 'feb', 'mar', 'abr', 'may', 'jun',
        'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
      ];
      final hora = f.hour % 12 == 0 ? 12 : f.hour % 12;
      final ampm = f.hour >= 12 ? 'p. m.' : 'a. m.';
      final min = f.minute.toString().padLeft(2, '0');
      return '${f.day.toString().padLeft(2, '0')} ${meses[f.month - 1]} ${f.year}, $hora:$min $ampm';
    } catch (_) {
      return '';
    }
  }

  // ------------------------------------------------------------
  // Getters derivados
  // ------------------------------------------------------------
  List<Map<String, dynamic>> get _filtradas {
    if (_categoriaActiva == 'todas') return _notificaciones;
    return _notificaciones.where((n) => _categoriaDe(n) == _categoriaActiva).toList();
  }

  int get _noLeidas => _notificaciones.where((n) => !_leida(n)).length;

  Map<String, int> get _conteoCategorias {
    final totales = {
      'todas': 0, 'cita': 0, 'vacuna': 0, 'alimentacion': 0,
      'medicamentos': 0, 'resultados': 0,
    };
    for (final n in _notificaciones) {
      totales['todas'] = (totales['todas'] ?? 0) + 1;
      final cat = _categoriaDe(n);
      if (totales.containsKey(cat)) totales[cat] = (totales[cat] ?? 0) + 1;
    }
    return totales;
  }

  // ------------------------------------------------------------
  // Acciones (todas contra la base de datos real)
  // ------------------------------------------------------------
  Future<void> _marcarLeida(Map<String, dynamic> n) async {
    if (_leida(n)) return;
    final id = n['ID_notificacion'];
    setState(() => n['Leida'] = 1); // optimista
    try {
      await _api.marcarNotificacionLeida(id);
    } catch (e) {
      debugPrint('Error marcando como leída: $e');
      if (!mounted) return;
      setState(() => n['Leida'] = 0);
    }
  }

  Future<void> _marcarTodasLeidas() async {
    final ids = _notificaciones.where((n) => !_leida(n)).map((n) => n['ID_notificacion']).toList();
    if (ids.isEmpty) return;
    try {
      await _api.marcarMultiplesNotificacionesLeidas(ids);
      if (!mounted) return;
      setState(() {
        for (final n in _notificaciones) {
          n['Leida'] = 1;
        }
      });
    } catch (e) {
      debugPrint('Error marcando todas como leídas: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudieron marcar todas como leídas')),
        );
      }
    }
  }

  Future<void> _eliminar(Map<String, dynamic> n) async {
    final id = n['ID_notificacion'];
    final respaldo = List<Map<String, dynamic>>.from(_notificaciones);
    setState(() => _notificaciones.removeWhere((x) => x['ID_notificacion'] == id));
    try {
      await _api.eliminarNotificacion(id);
    } catch (e) {
      debugPrint('Error eliminando notificación: $e');
      if (!mounted) return;
      setState(() => _notificaciones = respaldo);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo eliminar la notificación')),
      );
    }
  }

  // ============================================================
  // UI
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kFondo,
      appBar: AppBar(
        backgroundColor: kAzul,
        elevation: 0,
        title: const Text('🔔 Notificaciones',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _cargarNotificaciones,
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: kAzul))
          : RefreshIndicator(
        onRefresh: _cargarNotificaciones,
        color: kAzul,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            if (_error != null) ...[_bannerError(_error!), const SizedBox(height: 14)],
            _buildCabecera(),
            const SizedBox(height: 16),
            _buildResumen(),
            const SizedBox(height: 16),
            _buildFiltros(),
            const SizedBox(height: 16),
            ..._buildListaNotificaciones(),
          ],
        ),
      ),
    );
  }

  Widget _bannerError(String mensaje) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: kRojo, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(mensaje, style: const TextStyle(color: kRojo, fontSize: 12.5))),
          TextButton(
            onPressed: _cargarNotificaciones,
            child: const Text('Reintentar', style: TextStyle(color: kRojo, fontSize: 12.5)),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // Cabecera: subtítulo + badge de no leídas + botón marcar todas
  // ------------------------------------------------------------
  Widget _buildCabecera() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mantente al día con la salud de tus mascotas',
            style: TextStyle(fontSize: 13, color: kGrisTexto)),
        const SizedBox(height: 12),
        Row(
          children: [
            if (_noLeidas > 0) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: kRojo, borderRadius: BorderRadius.circular(99)),
                child: Text('$_noLeidas sin leer',
                    style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: SizedBox(
                height: 36,
                child: ElevatedButton.icon(
                  onPressed: _noLeidas == 0 ? null : _marcarTodasLeidas,
                  icon: const Icon(Icons.check, size: 15, color: Colors.white),
                  label: const Text('Marcar todas como leídas',
                      style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kIndigo,
                    disabledBackgroundColor: const Color(0xFFC7D2FE),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // Resumen (Total / Sin leer / Leídas)
  // ------------------------------------------------------------
  Widget _buildResumen() {
    final total = _conteoCategorias['todas'] ?? 0;
    final leidas = total - _noLeidas;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorde),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Expanded(child: _statItem('Total', '$total', const Color(0xFF0F172A))),
          Container(width: 1, height: 30, color: kBorde),
          Expanded(child: _statItem('Sin leer', '$_noLeidas', kRojo)),
          Container(width: 1, height: 30, color: kBorde),
          Expanded(child: _statItem('Leídas', '$leidas', kVerde)),
        ],
      ),
    );
  }

  Widget _statItem(String label, String valor, Color color) {
    return Column(
      children: [
        Text(valor, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: kGrisTexto)),
      ],
    );
  }

  // ------------------------------------------------------------
  // Filtros por categoría (chips horizontales, como el sidebar web)
  // ------------------------------------------------------------
  Widget _buildFiltros() {
    final conteos = _conteoCategorias;
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categorias.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final cat = _categorias[i];
          final activo = _categoriaActiva == cat.id;
          final count = conteos[cat.id] ?? 0;
          return GestureDetector(
            onTap: () => setState(() => _categoriaActiva = cat.id),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: activo ? const Color(0xFFEEF2FF) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: activo ? kIndigoDark : kBorde),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(cat.emoji, style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 6),
                  Text(cat.label,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: activo ? FontWeight.bold : FontWeight.w500,
                        color: activo ? kIndigoDark : const Color(0xFF334155),
                      )),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: activo ? kIndigo : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text('$count',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: activo ? Colors.white : const Color(0xFF475569),
                        )),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ------------------------------------------------------------
  // Lista de notificaciones
  // ------------------------------------------------------------
  List<Widget> _buildListaNotificaciones() {
    final lista = _filtradas;

    if (lista.isEmpty) {
      return [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 48),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kBorde),
          ),
          child: Column(
            children: [
              const Text('📭', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 10),
              Text('No hay notificaciones en esta categoría.',
                  style: TextStyle(color: kGrisClaro, fontSize: 13)),
            ],
          ),
        ),
      ];
    }

    return lista.map((n) => _notifCard(n)).toList();
  }

  Widget _notifCard(Map<String, dynamic> n) {
    final cat = _categoriaDe(n);
    final leida = _leida(n);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: leida ? Colors.white : const Color(0xFFFAFBFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: leida ? kBorde : kIndigo, width: leida ? 1 : 1.4),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _marcarLeida(n),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10)),
                  alignment: Alignment.center,
                  child: Text(_emojiCategoria(cat), style: const TextStyle(fontSize: 18)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (n['Mensaje'] ?? '').toString(),
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 5,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(color: _bgCategoria(cat), borderRadius: BorderRadius.circular(99)),
                            child: Text(
                              (n['Tipo'] ?? cat).toString(),
                              style: TextStyle(color: _colorCategoria(cat), fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Text('·', style: TextStyle(color: kGrisTexto, fontSize: 11)),
                          Text((n['Canal'] ?? '').toString(), style: TextStyle(color: kGrisTexto, fontSize: 11)),
                          Text('·', style: TextStyle(color: kGrisTexto, fontSize: 11)),
                          Text(_tiempoRelativo(n['Fecha_envio']), style: TextStyle(color: kGrisTexto, fontSize: 11)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(_fechaFormateada(n['Fecha_envio']), style: TextStyle(color: kGrisClaro, fontSize: 10.5)),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Column(
                  children: [
                    leida
                        ? const Icon(Icons.check, size: 15, color: kVerde)
                        : Container(
                      width: 9,
                      height: 9,
                      decoration: const BoxDecoration(color: kIndigo, shape: BoxShape.circle),
                    ),
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: () => _eliminar(n),
                      child: Icon(Icons.delete_outline, size: 17, color: Colors.grey[400]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
