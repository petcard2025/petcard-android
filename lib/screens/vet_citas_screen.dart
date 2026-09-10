import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'vet_dashboard_screen.dart'; // reutiliza VetColors y el modelo Cita

class VetCitasScreen extends StatefulWidget {
  final String nombreVeterinario;
  final String? idVeterinario;

  const VetCitasScreen({
    super.key,
    required this.nombreVeterinario,
    this.idVeterinario,
  });

  @override
  State<VetCitasScreen> createState() => _VetCitasScreenState();
}

class _VetCitasScreenState extends State<VetCitasScreen> {
  List<Cita> _citas = [];
  bool _cargando = false;
  String? _error;
  String _busqueda = '';
  String _filtroEstado = 'Todos';
  final _hoy = DateTime.now();

  final _searchController = TextEditingController();
  final ApiService _api = ApiService();
  final AuthService _auth = AuthService();

  @override
  void initState() {
    super.initState();
    _verificarAcceso();
    _cargarCitas();
  }

  Future<void> _verificarAcceso() async {
    if (!mounted) return;
    final activa = await _auth.haySesionActiva();
    if (!activa && mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarCitas() async {
    if (!mounted) return;
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final data = await _api.obtenerLista('/citas');
      final todas =
      data.map((e) => Cita.fromJson(e as Map<String, dynamic>)).toList();

      final propias = todas.where((c) {
        if (c.idVeterinario != null && widget.idVeterinario != null) {
          return c.idVeterinario == widget.idVeterinario;
        }
        return true;
      }).toList();

      if (mounted) setState(() => _citas = propias);
    } catch (e) {
      if (mounted) setState(() => _error = 'Error al cargar citas.');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  String _estadoCita(Cita c) {
    if (c.confirmada) return 'Confirmada';
    final d = c.fechaDate;
    if (d != null) {
      final soloFecha = DateTime(d.year, d.month, d.day);
      final hoySoloFecha = DateTime(_hoy.year, _hoy.month, _hoy.day);
      if (soloFecha.isBefore(hoySoloFecha)) return 'Pasada';
    }
    return 'Pendiente';
  }

  List<Cita> get _citasFiltradas {
    return _citas.where((c) {
      final texto =
      '${c.nombreMascota ?? ''} ${c.nombreCliente ?? ''} ${c.nombreServicio ?? ''}'
          .toLowerCase();
      final coincideTexto = texto.contains(_busqueda.toLowerCase());
      final estado = _estadoCita(c);
      final coincideEstado = _filtroEstado == 'Todos' || estado == _filtroEstado;
      return coincideTexto && coincideEstado;
    }).toList()
      ..sort((a, b) {
        final da = '${a.fecha ?? ''} ${a.hora ?? ''}';
        final db = '${b.fecha ?? ''} ${b.hora ?? ''}';
        return da.compareTo(db);
      });
  }

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'Confirmada':
        return VetColors.green;
      case 'Pendiente':
        return VetColors.yellow;
      default:
        return VetColors.muted;
    }
  }

  Color _bgEstado(String estado) {
    switch (estado) {
      case 'Confirmada':
        return VetColors.greenBg;
      case 'Pendiente':
        return VetColors.yellowBg;
      default:
        return const Color(0xFFF3F4F6);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: VetColors.blue,
        elevation: 0,
        title: const Text('Mis Citas',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
      ),
      body: RefreshIndicator(
        onRefresh: _cargarCitas,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Citas asignadas a ${widget.nombreVeterinario} · confirma y registra observaciones',
                    style: const TextStyle(fontSize: 12.5, color: VetColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _busqueda = v),
                    decoration: InputDecoration(
                      hintText: 'Buscar por mascota, cliente o servicio...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: VetColors.border),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _filtroEstado,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: VetColors.border),
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'Todos', child: Text('Todos')),
                            DropdownMenuItem(value: 'Pendiente', child: Text('Pendiente')),
                            DropdownMenuItem(value: 'Confirmada', child: Text('Confirmada')),
                            DropdownMenuItem(value: 'Pasada', child: Text('Pasada')),
                          ],
                          onChanged: (v) => setState(() => _filtroEstado = v ?? 'Todos'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text('${_citasFiltradas.length} result.',
                          style: const TextStyle(fontSize: 12, color: VetColors.muted)),
                    ],
                  ),
                ],
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: VetColors.redBg, borderRadius: BorderRadius.circular(10)),
                  child: Text('⚠️ $_error', style: const TextStyle(color: VetColors.red)),
                ),
              ),
            Expanded(
              child: _cargando
                  ? const Center(child: CircularProgressIndicator(color: VetColors.blue))
                  : _citasFiltradas.isEmpty
                  ? const Center(
                  child: Text('No se encontraron citas con ese filtro.',
                      style: TextStyle(color: VetColors.muted)))
                  : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: _citasFiltradas.length,
                itemBuilder: (context, i) {
                  final cita = _citasFiltradas[i];
                  final estado = _estadoCita(cita);
                  return _CitaCard(
                    cita: cita,
                    estado: estado,
                    color: _colorEstado(estado),
                    bg: _bgEstado(estado),
                    onTap: () => _abrirDetalle(cita, estado),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _abrirDetalle(Cita cita, String estado) {
    final d = cita.fechaDate;
    final fechaTexto = d != null ? DateFormat('dd/MM/yyyy').format(d) : '-';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Detalle de la cita',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 16, color: VetColors.text)),
              const SizedBox(height: 14),
              _detailRow('Mascota', cita.nombreMascota ?? '—'),
              _detailRow('Dueño', cita.nombreCliente ?? '—'),
              _detailRow('Servicio', cita.nombreServicio ?? '—'),
              _detailRow('Fecha', fechaTexto),
              _detailRow('Hora', cita.hora ?? '—'),
              const SizedBox(height: 8),
              const Text('Observaciones registradas',
                  style: TextStyle(
                      fontSize: 12.5, color: VetColors.muted, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  border: Border.all(color: VetColors.border),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  cita.observaciones?.isNotEmpty == true
                      ? cita.observaciones!
                      : 'Sin observaciones aún.',
                  style: const TextStyle(fontSize: 13, color: VetColors.text),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cerrar'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: estado == 'Pasada'
                          ? null
                          : () {
                        Navigator.pop(context);
                        _abrirConfirmar(cita);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: VetColors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(cita.confirmada ? 'Editar' : 'Confirmar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: VetColors.muted, fontWeight: FontWeight.w600, fontSize: 13)),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.right,
                style: const TextStyle(color: VetColors.text, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  void _abrirConfirmar(Cita cita) {
    final obsController = TextEditingController(text: cita.observaciones ?? '');
    bool guardando = false;
    String? mensajeExito;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Confirmar cita — ${cita.nombreMascota ?? ''}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 15, color: VetColors.text)),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: VetColors.greenBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${cita.fecha ?? ''} · ${cita.hora ?? ''}',
                          style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF166534))),
                      Text('Servicio: ${cita.nombreServicio ?? ''}',
                          style: const TextStyle(color: Color(0xFF166534), fontSize: 13)),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const Text('Observaciones clínicas',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: VetColors.text)),
                const SizedBox(height: 6),
                TextField(
                  controller: obsController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Anota el diagnóstico, tratamiento, indicaciones...',
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: VetColors.border),
                    ),
                  ),
                ),
                if (mensajeExito != null) ...[
                  const SizedBox(height: 10),
                  Text(mensajeExito!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: VetColors.green, fontWeight: FontWeight.w700)),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: guardando ? null : () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: guardando
                            ? null
                            : () async {
                          setModalState(() => guardando = true);
                          try {
                            await _api.actualizar('/citas/${cita.id}', {
                              'Observaciones': obsController.text,
                            });
                            setModalState(() {
                              mensajeExito = '✅ Cita confirmada y observaciones guardadas.';
                            });
                            await _cargarCitas();
                            await Future.delayed(const Duration(milliseconds: 900));
                            if (context.mounted) Navigator.pop(context);
                          } catch (e) {
                            setModalState(() => guardando = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Error al guardar. Inténtalo de nuevo.')),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: VetColors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: guardando
                            ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                            : const Text('Confirmar y guardar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        });
      },
    );
  }
}

class _CitaCard extends StatelessWidget {
  final Cita cita;
  final String estado;
  final Color color;
  final Color bg;
  final VoidCallback onTap;

  const _CitaCard({
    required this.cita,
    required this.estado,
    required this.color,
    required this.bg,
    required this.onTap,
  });

  String _iniciales(String? nombre) {
    if (nombre == null || nombre.trim().isEmpty) return '?';
    final partes = nombre.trim().split(' ');
    return partes.where((p) => p.isNotEmpty).take(2).map((p) => p[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    final d = cita.fechaDate;
    final fechaTexto = d != null ? DateFormat('dd/MM/yyyy').format(d) : '-';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: VetColors.border),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: VetColors.blueBg,
              child: Text(_iniciales(cita.nombreMascota),
                  style: const TextStyle(
                      color: VetColors.blue, fontWeight: FontWeight.w800, fontSize: 12)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(cita.nombreMascota ?? 'Mascota',
                            style: const TextStyle(fontWeight: FontWeight.w700, color: VetColors.text)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
                        child: Text(estado,
                            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: color)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text('${cita.nombreServicio ?? ''} · $fechaTexto ${cita.hora ?? ''}',
                      style: const TextStyle(fontSize: 12, color: VetColors.textSecondary)),
                  Text(cita.nombreCliente ?? '',
                      style: const TextStyle(fontSize: 11.5, color: VetColors.muted)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: VetColors.muted),
          ],
        ),
      ),
    );
  }
}