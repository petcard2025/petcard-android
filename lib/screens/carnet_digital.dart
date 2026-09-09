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

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      // Datos del propietario
      final usuarioStr = prefs.getString('petcard_usuario_actual');
      if (usuarioStr != null) {
        final usuario = jsonDecode(usuarioStr);
        final nombre = usuario['Nombre'] ?? usuario['nombre'] ?? '';
        final apellido = usuario['Apellido'] ?? usuario['apellido'] ?? '';
        _nombrePropietario = '$nombre $apellido'.trim();
        _emailPropietario = usuario['Correo'] ?? usuario['correo'] ?? '';
        _telefonoPropietario = usuario['Telefono'] ?? usuario['telefono'] ?? '';
      }

      // Foto de la mascota específica
      _fotoPath = prefs.getString('foto_mascota_${widget.idMascota}');

      // Vacunas de esta mascota
      final todasVacunas = await _api.obtenerVacunas();
      _vacunas = todasVacunas
          .where((v) => v['ID_mascota'] == widget.idMascota)
          .toList();

      // Si no hay vacunas, mostrar mensaje
      if (_vacunas.isEmpty) {
        _error = 'Esta mascota no tiene vacunas registradas aún.';
      }
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      debugPrint('Error cargando carnet: $_error');
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  // ─── CALCULAR EDAD ───
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

  // ─── FORMATEAR FECHA ───
  String _formatearFecha(String? fecha) {
    if (fecha == null || fecha.isEmpty) return '—';
    try {
      final dt = DateTime.parse(fecha);
      const meses = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
      return '${dt.day} ${meses[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return fecha;
    }
  }

  // ─── PDF ───
  Future<void> _descargarPDF() async {
    final pdf = pw.Document();

    pw.MemoryImage? fotoPdf;
    if (_fotoPath != null && _fotoPath!.isNotEmpty) {
      try {
        final bytes = await File(_fotoPath!).readAsBytes();
        fotoPdf = pw.MemoryImage(bytes);
      } catch (e) {
        debugPrint('No se pudo cargar la foto para el PDF: $e');
      }
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text('PETCARD - CARNET DIGITAL', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 20),
                pw.Container(
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(border: pw.Border.all(width: 2)),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      if (fotoPdf != null) ...[
                        pw.Center(
                          child: pw.ClipOval(
                            child: pw.Image(fotoPdf, width: 90, height: 90, fit: pw.BoxFit.cover),
                          ),
                        ),
                        pw.SizedBox(height: 14),
                      ],
                      pw.Text('Mascota: ${widget.nombreMascota}', style: pw.TextStyle(fontSize: 18)),
                      pw.Text('Especie: ${widget.especie}'),
                      pw.Text('Raza: ${widget.raza}'),
                      pw.Text('Edad: ${_calcularEdad()}'),
                      pw.Text('Peso: ${widget.peso} kg'),
                      pw.Divider(),
                      pw.Text('Propietario: $_nombrePropietario'),
                      pw.Text('Contacto: $_telefonoPropietario'),
                      pw.Text('Email: $_emailPropietario'),
                      pw.Divider(),
                      pw.Text('VACUNAS REGISTRADAS:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      if (_vacunas.isEmpty)
                        pw.Text('No hay vacunas registradas para esta mascota.')
                      else
                        ..._vacunas.map((v) => pw.Text(
                          '• ${v['Nombre_vacuna'] ?? 'Sin nombre'} - ${_formatearFecha(v['Fecha_aplicacion'])}'
                              '${v['Proxima_dosis'] != null ? ' (Próxima: ${_formatearFecha(v['Proxima_dosis'])})' : ''}',
                        )),
                    ],
                  ),
                ),
              ],
            ),
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
            Text('PetCard', style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 20)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
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
                  '⚠️ ${_error ?? 'Error al cargar datos'}',
                  style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 13),
                ),
              ),
              const SizedBox(height: 16),
            ],
            const Text('Carnet Digital', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            const Text('Identificación oficial de tu mascota', style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
            const SizedBox(height: 20),
            _buildCarnetCard(),
            const SizedBox(height: 24),

            // Lista de vacunas
            if (_vacunas.isNotEmpty) ...[
              const Text(
                'Vacunas Registradas',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 12),
              ..._vacunas.map((v) => _buildVacunaCard(v)),
              const SizedBox(height: 12),
            ],

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _descargarPDF,
                icon: const Icon(Icons.download, color: Colors.white),
                label: const Text('Descargar PDF', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kBlue,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                  elevation: 4,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ─── CIRCULO DE FOTO ───
  Widget _buildAvatarMascota() {
    if (_fotoPath != null && _fotoPath!.isNotEmpty) {
      return ClipOval(
        child: Image.file(
          File(_fotoPath!),
          width: 64,
          height: 64,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.pets, color: kYellow, size: 36),
          ),
        ),
      );
    }
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.pets, color: kYellow, size: 36),
    );
  }

  // ─── TARJETA CARRUSEL ───
  Widget _buildCarnetCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A5F), Color(0xFF2D4A7A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A5F).withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.pets, color: kYellow, size: 24),
                  SizedBox(width: 8),
                  Text('PetCard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: kSuccess,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('VÁLIDO', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildAvatarMascota(),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.nombreMascota, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    Text('${widget.especie} · ${widget.raza}', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildDetailRow('EDAD', _calcularEdad(), 'PESO', '${widget.peso} kg'),
                const SizedBox(height: 12),
                _buildDetailRow('RAZA', widget.raza, 'SEXO', widget.sexo),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.person, color: Colors.white60, size: 14),
                    SizedBox(width: 4),
                    Text('PROPIETARIO', style: TextStyle(color: Colors.white60, fontSize: 9, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _nombrePropietario.isEmpty ? '-' : _nombrePropietario,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    const Icon(Icons.phone, color: Colors.white60, size: 10),
                    const SizedBox(width: 4),
                    Text(
                      _telefonoPropietario.isEmpty ? '-' : _telefonoPropietario,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.email, color: Colors.white60, size: 10),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _emailPropietario.isEmpty ? '-' : _emailPropietario,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label1, String value1, String label2, String value2) {
    return Row(
      children: [
        Expanded(child: _buildDetailItem(label1, value1)),
        Expanded(child: _buildDetailItem(label2, value2)),
      ],
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 8, fontWeight: FontWeight.bold)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }

  // ─── TARJETA DE VACUNA ───
  Widget _buildVacunaCard(Map<String, dynamic> v) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: kBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.medical_services, color: kBlue, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  v['Nombre_vacuna'] ?? 'Vacuna',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  'Aplicada: ${_formatearFecha(v['Fecha_aplicacion'])}'
                      '${v['Proxima_dosis'] != null ? ' · Próxima: ${_formatearFecha(v['Proxima_dosis'])}' : ''}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                if (v['Lote'] != null && v['Lote'].toString().isNotEmpty)
                  Text(
                    'Lote: ${v['Lote']}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: (v['Estado'] == 'Aplicada' || v['Estado'] == 'Completada')
                  ? const Color(0xFFDCFCE7)
                  : const Color(0xFFFEF9C3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              v['Estado'] ?? 'Pendiente',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: (v['Estado'] == 'Aplicada' || v['Estado'] == 'Completada')
                    ? const Color(0xFF16A34A)
                    : const Color(0xFFCA8A04),
              ),
            ),
          ),
        ],
      ),
    );
  }
}