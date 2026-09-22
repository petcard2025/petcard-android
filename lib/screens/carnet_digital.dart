import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../services/api_service.dart';

class CarnetDigitalScreen extends StatefulWidget {
  final int idMascota;
  final String nombreMascota;
  final String especie;
  final String raza;
  final String sexo;
  final double peso;
  final String? fechaNacimiento;

  const CarnetDigitalScreen({
    super.key,
    required this.idMascota,
    required this.nombreMascota,
    required this.especie,
    required this.raza,
    required this.sexo,
    required this.peso,
    this.fechaNacimiento,
  });

  @override
  State<CarnetDigitalScreen> createState() => _CarnetDigitalScreenState();
}

class _CarnetDigitalScreenState extends State<CarnetDigitalScreen> {
  static const Color kBlue = Color(0xFF3B82F6);
  static const Color kYellow = Color(0xFFFCD34D);
  static const Color kSuccess = Color(0xFF10B981);

  final ApiService _api = ApiService();

  bool _isLoading = true;
  String? _error;
  String? _fotoPath;
  String _nombrePropietario = '';
  String _emailPropietario = '';
  String _telefonoPropietario = '';
  List<Map<String, dynamic>> _vacunas = [];

  // ------------------------------------------------------------
  // Igual que en la web: estado de vacunación calculado
  // ------------------------------------------------------------
  bool _esAplicada(dynamic estado) =>
      estado == 'Aplicada' || estado == 'Completada' || estado == 'Completo' || estado == 'aplicada';
  bool _esAtrasada(dynamic estado) =>
      estado == 'Atrasada' || estado == 'atrasada';

  int get _aplicadas => _vacunas.where((v) => _esAplicada(v['Estado'])).length;
  int get _pendientes => _vacunas.length - _aplicadas;
  int get _pct => _vacunas.isEmpty
      ? 0
      : ((_aplicadas / _vacunas.length) * 100).round();
  List<Map<String, dynamic>> get _proximas => _vacunas
      .where((v) => !_esAplicada(v['Estado']))
      .take(2)
      .toList();

  Color _estadoColor(dynamic estado) {
    if (_esAplicada(estado)) return kSuccess;
    if (_esAtrasada(estado)) return const Color(0xFFDC2626);
    return const Color(0xFFCA8A04);
  }

  String _estadoIcono(dynamic estado) {
    if (_esAplicada(estado)) return '✓';
    if (_esAtrasada(estado)) return '✖';
    return '⚠';
  }

  String _badgeLabel(dynamic estado) {
    if (_esAtrasada(estado)) return 'Atrasada';
    if (estado == 'Proxima' || estado == 'proxima') return 'Próxima Dosis';
    return 'Pendiente';
  }

  // ------------------------------------------------------------
  // Formulario "Agregar Vacuna" (igual al de la web)
  // ------------------------------------------------------------
  final _nombreVacunaCtrl = TextEditingController();
  final _fechaAplicacionCtrl = TextEditingController();
  final _proximaDosisCtrl = TextEditingController();
  final _loteCtrl = TextEditingController();
  final _observacionesCtrl = TextEditingController();
  String _estadoVacuna = 'Aplicada';
  bool _guardandoVacuna = false;

  static const List<String> _vacunasSugeridas = [
    'Antirrábica',
    'Triple Felina',
    'Parvovirus',
    'Moquillo',
    'Leptospirosis',
    'Bordetella',
    'Rabia',
    'Leucemia Felina',
    'Panleucopenia',
    'Calicivirus',
    'Rinotraqueitis',
    'Hepatitis Infecciosa',
    'Parainfluenza',
    'Coronavirus',
  ];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  @override
  void dispose() {
    _nombreVacunaCtrl.dispose();
    _fechaAplicacionCtrl.dispose();
    _proximaDosisCtrl.dispose();
    _loteCtrl.dispose();
    _observacionesCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      final usuarioStr = prefs.getString('petcard_usuario_actual');
      if (usuarioStr != null) {
        final usuario = jsonDecode(usuarioStr);
        final nombre = usuario['Nombre'] ?? usuario['nombre'] ?? '';
        final apellido = usuario['Apellido'] ?? usuario['apellido'] ?? '';
        _nombrePropietario = '$nombre $apellido'.trim();
        _emailPropietario = usuario['Correo'] ?? usuario['correo'] ?? '';
        _telefonoPropietario = usuario['Telefono'] ?? usuario['telefono'] ?? '';
      }

      _fotoPath = prefs.getString('foto_mascota_${widget.idMascota}');

      final todasVacunas = await _api.obtenerVacunas();
      _vacunas = todasVacunas
          .where((v) => v['ID_mascota'] == widget.idMascota)
          .toList();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      debugPrint('Error cargando carnet: $_error');
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  void _limpiarFormularioVacuna() {
    _nombreVacunaCtrl.clear();
    _fechaAplicacionCtrl.clear();
    _proximaDosisCtrl.clear();
    _loteCtrl.clear();
    _observacionesCtrl.clear();
    _estadoVacuna = 'Aplicada';
  }

  Future<void> _elegirFecha(
      TextEditingController controller, StateSetter setModalState) async {
    final ahora = DateTime.now();
    final fechaActual = DateTime.tryParse(controller.text);
    final elegida = await showDatePicker(
      context: context,
      initialDate: fechaActual ?? ahora,
      firstDate: DateTime(ahora.year - 20),
      lastDate: DateTime(ahora.year + 20),
    );
    if (elegida != null) {
      controller.text =
      '${elegida.year.toString().padLeft(4, '0')}-${elegida.month.toString().padLeft(2, '0')}-${elegida.day.toString().padLeft(2, '0')}';
      setModalState(() {});
    }
  }

  Future<void> _guardarVacuna() async {
    final nombre = _nombreVacunaCtrl.text.trim();
    if (nombre.isEmpty) return;

    setState(() => _guardandoVacuna = true);
    try {
      await _api.crearVacuna({
        'ID_mascota': widget.idMascota,
        'ID_servicio': 2,
        'Nombre_vacuna': nombre,
        'Fecha_aplicacion': _fechaAplicacionCtrl.text.trim().isEmpty
            ? null
            : _fechaAplicacionCtrl.text.trim(),
        'Proxima_dosis': _proximaDosisCtrl.text.trim().isEmpty
            ? null
            : _proximaDosisCtrl.text.trim(),
        'Lote': _loteCtrl.text.trim(),
        'Observaciones': _observacionesCtrl.text.trim(),
        'Estado': _estadoVacuna,
      });

      if (!mounted) return;
      Navigator.pop(context); // cierra el modal
      await _cargarDatos(); // refresca la lista de vacunas
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Vacuna registrada correctamente')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '❌ Error al guardar vacuna: ${e.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _guardandoVacuna = false);
    }
  }

  void _mostrarFormularioVacuna() {
    _limpiarFormularioVacuna();
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header verde, igual que en la web
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFFDCFCE7), Color(0xFFF0FDF4)],
                          ),
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.vaccines,
                                  color: Color(0xFF16A34A)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Agregar Vacuna',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Color(0xFF14532D),
                                    ),
                                  ),
                                  Text(
                                    'Registra una nueva vacuna para ${widget.nombreMascota}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF166534),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 20),
                              onPressed: () => Navigator.pop(dialogContext),
                            ),
                          ],
                        ),
                      ),

                      // Body con el formulario
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _labelVacuna('NOMBRE DE LA VACUNA',
                                  obligatorio: true),
                              const SizedBox(height: 6),
                              Autocomplete<String>(
                                optionsBuilder: (valor) {
                                  if (valor.text.isEmpty) {
                                    return const Iterable<String>.empty();
                                  }
                                  return _vacunasSugeridas.where((v) => v
                                      .toLowerCase()
                                      .contains(valor.text.toLowerCase()));
                                },
                                onSelected: (v) {
                                  _nombreVacunaCtrl.text = v;
                                  setModalState(() {});
                                },
                                fieldViewBuilder:
                                    (context, controller, focusNode, _) {
                                  return TextField(
                                    controller: controller,
                                    focusNode: focusNode,
                                    onChanged: (v) {
                                      _nombreVacunaCtrl.text = v;
                                      setModalState(() {});
                                    },
                                    decoration: _inputDecoration(
                                        'Ej: Antirrábica, Parvovirus...'),
                                  );
                                },
                              ),
                              const SizedBox(height: 16),

                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        _labelVacuna('FECHA DE APLICACIÓN',
                                            icon: Icons.calendar_today),
                                        const SizedBox(height: 6),
                                        TextField(
                                          controller: _fechaAplicacionCtrl,
                                          readOnly: true,
                                          onTap: () => _elegirFecha(
                                              _fechaAplicacionCtrl,
                                              setModalState),
                                          decoration:
                                          _inputDecoration('dd/mm/aaaa'),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        _labelVacuna('PRÓXIMA DOSIS',
                                            icon: Icons.access_time),
                                        const SizedBox(height: 6),
                                        TextField(
                                          controller: _proximaDosisCtrl,
                                          readOnly: true,
                                          onTap: () => _elegirFecha(
                                              _proximaDosisCtrl,
                                              setModalState),
                                          decoration:
                                          _inputDecoration('dd/mm/aaaa'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        _labelVacuna('LOTE / SERIE'),
                                        const SizedBox(height: 6),
                                        TextField(
                                          controller: _loteCtrl,
                                          decoration:
                                          _inputDecoration('Ej: A-1234'),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        _labelVacuna('ESTADO'),
                                        const SizedBox(height: 6),
                                        DropdownButtonFormField<String>(
                                          initialValue: _estadoVacuna,
                                          isExpanded: true,
                                          decoration: _inputDecoration(null),
                                          items: const [
                                            DropdownMenuItem(
                                              value: 'Aplicada',
                                              child: Text('✅ Aplicada',
                                                  overflow:
                                                  TextOverflow.ellipsis),
                                            ),
                                            DropdownMenuItem(
                                              value: 'Proxima',
                                              child: Text('🔔 Próxima',
                                                  overflow:
                                                  TextOverflow.ellipsis),
                                            ),
                                            DropdownMenuItem(
                                              value: 'Atrasada',
                                              child: Text('⚠️ Atrasada',
                                                  overflow:
                                                  TextOverflow.ellipsis),
                                            ),
                                          ],
                                          onChanged: (v) {
                                            setModalState(() {
                                              _estadoVacuna = v ?? 'Aplicada';
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              _labelVacuna('OBSERVACIONES / REACCIONES'),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _observacionesCtrl,
                                maxLines: 3,
                                decoration: _inputDecoration(
                                    'Ej: Sin reacciones adversas. Aplicada en clínica veterinaria...'),
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ),

                      // Footer con botones
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(dialogContext),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('Cancelar'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: (_nombreVacunaCtrl.text
                                    .trim()
                                    .isEmpty ||
                                    _guardandoVacuna)
                                    ? null
                                    : _guardarVacuna,
                                icon: _guardandoVacuna
                                    ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                    : const Icon(Icons.check, size: 18),
                                label: const Text('Guardar Vacuna'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF16A34A),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _labelVacuna(String texto,
      {bool obligatorio = false, IconData? icon}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 13, color: Colors.grey[600]),
          const SizedBox(width: 4),
        ],
        Flexible(
          child: Text(
            texto,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
              letterSpacing: 0.3,
            ),
          ),
        ),
        if (obligatorio)
          const Text(' *', style: TextStyle(color: Colors.red, fontSize: 12)),
      ],
    );
  }

  InputDecoration _inputDecoration(String? hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
        borderSide: const BorderSide(color: Color(0xFF16A34A), width: 1.5),
      ),
    );
  }

  String _calcularEdad() {
    if (widget.fechaNacimiento == null || widget.fechaNacimiento!.isEmpty) {
      return '—';
    }
    final nacimiento = DateTime.tryParse(widget.fechaNacimiento!);
    if (nacimiento == null) return '—';
    final ahora = DateTime.now();
    int anios = ahora.year - nacimiento.year;
    if (ahora.month < nacimiento.month ||
        (ahora.month == nacimiento.month && ahora.day < nacimiento.day)) {
      anios--;
    }
    if (anios < 0) return '—';
    if (anios == 0) return 'Menos de 1 año';
    return '$anios años';
  }

  String _formatearFecha(String? fecha) {
    if (fecha == null || fecha.isEmpty) return '—';
    try {
      final dt = DateTime.parse(fecha);
      const meses = [
        'ene', 'feb', 'mar', 'abr', 'may', 'jun',
        'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
      ];
      return '${dt.day} ${meses[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return fecha;
    }
  }

  // ============================================================
  // PDF REDISEÑADO
  // ============================================================
  Future<void> _descargarPDF() async {
    final pdf = pw.Document();

    pw.MemoryImage? fotoPdf;
    if (_fotoPath != null && _fotoPath!.isNotEmpty) {
      try {
        final bytes = await File(_fotoPath!).readAsBytes();
        fotoPdf = pw.MemoryImage(bytes);
      } catch (e) {
        debugPrint('No se pudo cargar la foto: $e');
      }
    }

    // Colores del PDF
    final azulPetcard = PdfColor.fromInt(0xFF2563EB);
    final azulOscuro = PdfColor.fromInt(0xFF1E3A5F);
    final grisClaro = PdfColor.fromInt(0xFFF1F5F9);
    final grisTexto = PdfColor.fromInt(0xFF64748B);
    final verde = PdfColor.fromInt(0xFF16A34A);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ══════════════════════════════════════════════════
              // HEADER CON DEGRADADO AZUL
              // ══════════════════════════════════════════════════
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  gradient: pw.LinearGradient(
                    colors: [azulPetcard, azulOscuro],
                    begin: pw.Alignment.topLeft,
                    end: pw.Alignment.bottomRight,
                  ),
                  borderRadius: pw.BorderRadius.circular(12),
                ),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Container(
                      width: 50,
                      height: 50,
                      decoration: pw.BoxDecoration(
                        color: PdfColors.white,
                        borderRadius: pw.BorderRadius.circular(12),
                      ),
                      alignment: pw.Alignment.center,
                      child: pw.Text(
                        '🐾',
                        style: pw.TextStyle(fontSize: 26),
                      ),
                    ),
                    pw.SizedBox(width: 14),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'PETCARD',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 22,
                            fontWeight: pw.FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Carnet Digital de Mascota',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    pw.Spacer(),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: pw.BoxDecoration(
                        color: verde,
                        borderRadius: pw.BorderRadius.circular(20),
                      ),
                      child: pw.Text(
                        'VÁLIDO',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // ══════════════════════════════════════════════════
              // CARD DE LA MASCOTA
              // ══════════════════════════════════════════════════
              pw.Container(
                padding: const pw.EdgeInsets.all(18),
                decoration: pw.BoxDecoration(
                  color: grisClaro,
                  borderRadius: pw.BorderRadius.circular(10),
                ),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Foto o ícono
                    pw.Container(
                      width: 90,
                      height: 90,
                      decoration: pw.BoxDecoration(
                        color: PdfColors.white,
                        borderRadius: pw.BorderRadius.circular(10),
                      ),
                      alignment: pw.Alignment.center,
                      child: fotoPdf != null
                          ? pw.ClipRRect(
                        horizontalRadius: 10,
                        verticalRadius: 10,
                        child: pw.Image(
                          fotoPdf,
                          width: 90,
                          height: 90,
                          fit: pw.BoxFit.cover,
                        ),
                      )
                          : pw.Text(
                        '🐾',
                        style: pw.TextStyle(fontSize: 40),
                      ),
                    ),
                    pw.SizedBox(width: 16),

                    // Datos de la mascota
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            widget.nombreMascota,
                            style: pw.TextStyle(
                              fontSize: 22,
                              fontWeight: pw.FontWeight.bold,
                              color: azulOscuro,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            '${widget.especie} · ${widget.raza}',
                            style: pw.TextStyle(
                              fontSize: 12,
                              color: grisTexto,
                            ),
                          ),
                          pw.SizedBox(height: 12),
                          // Grid de datos
                          pw.Wrap(
                            spacing: 20,
                            runSpacing: 8,
                            children: [
                              _pdfDato('EDAD', _calcularEdad(), azulOscuro),
                              _pdfDato('PESO', '${widget.peso} kg', azulOscuro),
                              _pdfDato('SEXO', widget.sexo, azulOscuro),
                              _pdfDato('ID CARNET', 'PET-${widget.idMascota.toString().padLeft(6, '0')}', azulOscuro),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // ══════════════════════════════════════════════════
              // DATOS DEL PROPIETARIO
              // ══════════════════════════════════════════════════
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(14),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: grisClaro, width: 2),
                  borderRadius: pw.BorderRadius.circular(10),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      children: [
                        pw.Text('', style: pw.TextStyle(fontSize: 14)),
                        pw.SizedBox(width: 6),
                        pw.Text(
                          'PROPIETARIO',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: grisTexto,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      _nombrePropietario.isEmpty ? 'Sin nombre' : _nombrePropietario,
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: azulOscuro,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Row(
                      children: [
                        pw.Text(
                          '${_telefonoPropietario.isEmpty ? "—" : _telefonoPropietario}',
                          style: pw.TextStyle(fontSize: 11, color: grisTexto),
                        ),
                        pw.SizedBox(width: 16),
                        pw.Text(
                          '${_emailPropietario.isEmpty ? "—" : _emailPropietario}',
                          style: pw.TextStyle(fontSize: 11, color: grisTexto),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // ══════════════════════════════════════════════════
              // VACUNAS REGISTRADAS
              // ══════════════════════════════════════════════════
              pw.Text(
                'VACUNAS REGISTRADAS',
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: azulOscuro,
                ),
              ),
              pw.SizedBox(height: 10),

              if (_vacunas.isEmpty)
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(14),
                  decoration: pw.BoxDecoration(
                    color: grisClaro,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Text(
                    'No hay vacunas registradas para esta mascota.',
                    style: pw.TextStyle(fontSize: 11, color: grisTexto),
                  ),
                )
              else
                pw.Table(
                  border: pw.TableBorder.all(color: grisClaro, width: 1),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(2.5),
                    1: const pw.FlexColumnWidth(1.5),
                    2: const pw.FlexColumnWidth(1.8),
                    3: const pw.FlexColumnWidth(1.8),
                  },
                  children: [
                    // Encabezados
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: azulOscuro),
                      children: [
                        _pdfCeldaHeader('VACUNA'),
                        _pdfCeldaHeader('LOTE'),
                        _pdfCeldaHeader('APLICADA'),
                        _pdfCeldaHeader('PRÓXIMA'),
                      ],
                    ),
                    // Filas
                    ..._vacunas.asMap().entries.map((entry) {
                      final index = entry.key;
                      final v = entry.value;
                      final esPar = index % 2 == 0;
                      return pw.TableRow(
                        decoration: pw.BoxDecoration(
                          color: esPar ? PdfColors.white : grisClaro,
                        ),
                        children: [
                          _pdfCeldaTexto(v['Nombre_vacuna'] ?? 'Sin nombre'),
                          _pdfCeldaTexto(v['Lote'] ?? '—'),
                          _pdfCeldaTexto(_formatearFecha(v['Fecha_aplicacion'])),
                          _pdfCeldaTexto(_formatearFecha(v['Proxima_dosis'])),
                        ],
                      );
                    }),
                  ],
                ),

              pw.Spacer(),

              // ══════════════════════════════════════════════════
              // FOOTER
              // ══════════════════════════════════════════════════
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: azulOscuro,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      '© 2026 PetCard',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 9,
                      ),
                    ),
                    pw.Text(
                      'Documento oficial generado por PetCard',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    try {
      await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Carnet generado correctamente')),
        );
      }
    } catch (e) {
      debugPrint('Error PDF: $e');
    }
  }

  // Helpers para el PDF
  pw.Widget _pdfDato(String label, String value, PdfColor color) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 8,
            color: PdfColor.fromInt(0xFF64748B),
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    );
  }

  pw.Widget _pdfCeldaHeader(String texto) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        texto,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  pw.Widget _pdfCeldaTexto(String texto) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        texto,
        style: pw.TextStyle(
          fontSize: 10,
          color: PdfColor.fromInt(0xFF1A1A2E),
        ),
      ),
    );
  }

  // ============================================================
  // BUILD (pantalla)
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: const [
            Icon(Icons.pets, color: kBlue, size: 28),
            SizedBox(width: 8),
            Text('PetCard',
                style: TextStyle(
                    color: Color(0xFF1E293B),
                    fontWeight: FontWeight.bold,
                    fontSize: 20)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_error != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  ' ${_error ?? 'Error al cargar datos'}',
                  style: const TextStyle(
                      color: Color(0xFFB91C1C), fontSize: 13),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Encabezado verde "Carnet de Vacunación" (igual que la web) ──
            _buildCarnetHeader(),
            const SizedBox(height: 16),

            // ── Botón agregar vacuna ──
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _mostrarFormularioVacuna,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.add, size: 18, color: Color(0xFF16A34A)),
                label: const Text(
                  'Agregar Vacuna',
                  style: TextStyle(
                      color: Color(0xFF16A34A), fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // ── Tabla de vacunas (Estado, Vacuna, F.Programada, F.Aplicada, Lote, Obs.) ──
            _buildTablaVacunas(),
            const SizedBox(height: 16),

            // ── Observaciones médicas ──
            _buildObservacionesMedicas(),
            const SizedBox(height: 20),

            // ── Estado de vacunación (%, barra, stats) ──
            _buildEstadoVacunacion(),
            const SizedBox(height: 16),

            // ── Próximas vacunas ──
            _buildProximasVacunas(),
            const SizedBox(height: 16),

            // ── Información del carnet ──
            _buildInformacionCarnet(),
            const SizedBox(height: 12),

            // ── Botones Descargar PDF / Imprimir ──
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _descargarPDF,
                    icon: const Icon(Icons.download, color: Colors.white, size: 18),
                    label: const Text('Descargar PDF',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kBlue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      elevation: 2,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _descargarPDF,
                    icon: const Icon(Icons.print, size: 18, color: kBlue),
                    label: const Text('Imprimir',
                        style: TextStyle(color: kBlue, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: kBlue),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // Encabezado verde "Carnet de Vacunación" (equivalente a
  // .vacuna-header de la web)
  // ============================================================
  Widget _buildCarnetHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSuccess,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Carnet de Vacunación',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('${widget.nombreMascota} · ${widget.especie}',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Veterinario:',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85), fontSize: 11)),
              const Text('Dr. José García',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
              const SizedBox(height: 2),
              Text('Matrícula: 47789',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85), fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Tabla de vacunas, con scroll horizontal (igual columnas que
  // la tabla de la web)
  // ============================================================
  Widget _buildTablaVacunas() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!),
      ),
      padding: const EdgeInsets.all(12),
      child: _vacunas.isEmpty
          ? Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text('Sin vacunas registradas todavía.',
            style: TextStyle(color: Colors.grey[600], fontSize: 13)),
      )
          : SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xFF1D4ED8)),
          headingTextStyle: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
          dataTextStyle: const TextStyle(fontSize: 12, color: Color(0xFF111827)),
          columnSpacing: 18,
          columns: const [
            DataColumn(label: Text('Estado')),
            DataColumn(label: Text('Vacuna')),
            DataColumn(label: Text('F. Programada')),
            DataColumn(label: Text('F. Aplicada')),
            DataColumn(label: Text('Lote')),
            DataColumn(label: Text('Observaciones')),
          ],
          rows: _vacunas.map((v) {
            return DataRow(cells: [
              DataCell(Text(_estadoIcono(v['Estado']),
                  style: TextStyle(
                      color: _estadoColor(v['Estado']),
                      fontWeight: FontWeight.bold))),
              DataCell(Text(v['Nombre_vacuna'] ?? '—',
                  style: const TextStyle(
                      color: kBlue, fontWeight: FontWeight.bold))),
              DataCell(Text(_formatearFecha(v['Proxima_dosis']))),
              DataCell(Text(_formatearFecha(v['Fecha_aplicacion']))),
              DataCell(Text((v['Lote'] ?? '—').toString())),
              DataCell(SizedBox(
                width: 140,
                child: Text((v['Observaciones'] ?? '—').toString(),
                    overflow: TextOverflow.ellipsis, maxLines: 2),
              )),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildObservacionesMedicas() {
    final conObs = _vacunas.where((v) =>
    v['Observaciones'] != null && v['Observaciones'].toString().isNotEmpty);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Observaciones Médicas:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 6),
          if (conObs.isEmpty)
            Text('Sin observaciones registradas.',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]))
          else
            ...conObs.map((v) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('• ${v['Nombre_vacuna']}: ${v['Observaciones']}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700])),
            )),
        ],
      ),
    );
  }

  // ============================================================
  // Card "Estado de Vacunación" (% + barra + stats), igual a la
  // web
  // ============================================================
  Widget _buildEstadoVacunacion() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Estado de Vacunación',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 12),
          Center(
            child: Column(
              children: [
                Text('$_pct%',
                    style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A))),
                Text('Carnet de Vacunación',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _pct / 100,
              minHeight: 8,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: const AlwaysStoppedAnimation(Color(0xFFCA8A04)),
            ),
          ),
          const SizedBox(height: 12),
          _filaStat('Aplicadas:', '$_aplicadas'),
          _filaStat('Pendientes o demorar:', '$_pendientes'),
          _filaStat('Próximas:', '${_proximas.length}'),
        ],
      ),
    );
  }

  Widget _filaStat(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ============================================================
  // Card "Próximas Vacunas"
  // ============================================================
  Widget _buildProximasVacunas() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.schedule, size: 16, color: Color(0xFFEA580C)),
              SizedBox(width: 6),
              Text('Próximas Vacunas',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFFEA580C))),
            ],
          ),
          const SizedBox(height: 10),
          if (_proximas.isEmpty)
            Text('Sin vacunas pendientes.',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]))
          else
            ..._proximas.map((v) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(v['Nombre_vacuna'] ?? '—',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _esAtrasada(v['Estado'])
                              ? const Color(0xFFFEE2E2)
                              : const Color(0xFFFEF9C3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(_badgeLabel(v['Estado']),
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: _esAtrasada(v['Estado'])
                                    ? const Color(0xFFDC2626)
                                    : const Color(0xFFCA8A04))),
                      ),
                    ],
                  ),
                  Text('Próxima: ${_formatearFecha(v['Proxima_dosis'])}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            )),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/citas'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kSuccess,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Agendar Vacunación',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Card "Información del Carnet"
  // ============================================================
  Widget _buildInformacionCarnet() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.description, size: 16, color: Color(0xFF16A34A)),
              SizedBox(width: 6),
              Text('Información del Carnet',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF16A34A))),
            ],
          ),
          const SizedBox(height: 10),
          _filaInfo('Mascota:', widget.nombreMascota),
          _filaInfo('Especie:', widget.especie),
          _filaInfo('Raza:', widget.raza),
          _filaInfo('ID:', '${widget.idMascota}'),
          _filaInfo('Fecha de nacimiento:',
              widget.fechaNacimiento != null && widget.fechaNacimiento!.isNotEmpty
                  ? _formatearFecha(widget.fechaNacimiento)
                  : '—'),
          _filaInfo(
              'Próxima cita:',
              _proximas.isNotEmpty
                  ? _formatearFecha(_proximas.first['Proxima_dosis'])
                  : '—'),
        ],
      ),
    );
  }

  Widget _filaInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}