import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../services/api_service.dart';

class CarnetDigitalScreen extends StatefulWidget {
  const CarnetDigitalScreen({super.key});

  @override
  State<CarnetDigitalScreen> createState() => _CarnetDigitalScreenState();
}

class _CarnetDigitalScreenState extends State<CarnetDigitalScreen> {
  static const Color kBlue = Color(0xFF3B82F6);
  static const Color kBlueDark = Color(0xFF1E3A5F);
  static const Color kYellow = Color(0xFFFCD34D);
  static const Color kSuccess = Color(0xFF10B981);

  final ApiService _api = ApiService();

  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _mascota;
  // Ruta local de la foto (el backend aún no guarda archivos, así que se
  // busca igual que en "Mis mascotas": cacheada en SharedPreferences con
  // la clave 'foto_mascota_<ID_mascota>').
  String? _fotoPath;
  String _nombrePropietario = '';
  String _emailPropietario = '';
  String _telefonoPropietario = '';

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

      // Datos del propietario (guardados al iniciar sesión).
      final usuarioStr = prefs.getString('petcard_usuario_actual');
      if (usuarioStr != null) {
        final usuario = jsonDecode(usuarioStr);
        final nombre = usuario['Nombre'] ?? usuario['nombre'] ?? '';
        final apellido = usuario['Apellido'] ?? usuario['apellido'] ?? '';
        _nombrePropietario = '$nombre $apellido'.trim();
        _emailPropietario = usuario['Correo'] ?? usuario['correo'] ?? '';
        _telefonoPropietario = usuario['Telefono'] ?? usuario['telefono'] ?? '';
      }

      // Mascotas reales del cliente logueado (mismo dato que "Mis mascotas").
      final mascotas = await _api.obtenerMisMascotas();
      if (mascotas.isNotEmpty) {
        _mascota = mascotas.first;
        final id = _mascota?['ID_mascota'];
        _fotoPath = prefs.getString('foto_mascota_$id');
      }
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      debugPrint('Error cargando carnet: $_error');
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  // Calcula la edad en años a partir de "Fecha_nacimiento" (YYYY-MM-DD).
  String _calcularEdad() {
    final fechaRaw = _mascota?['Fecha_nacimiento'];
    if (fechaRaw == null) return '—';
    final nacimiento = DateTime.tryParse(fechaRaw.toString());
    if (nacimiento == null) return '—';
    final ahora = DateTime.now();
    int anios = ahora.year - nacimiento.year;
    if (ahora.month < nacimiento.month ||
        (ahora.month == nacimiento.month && ahora.day < nacimiento.day)) {
      anios--;
    }
    if (anios < 0) return '—';
    if (anios == 0) return 'Menos de 1 año';
    return anios == 1 ? '1 año' : '$anios años';
  }

  Future<void> _descargarPDF() async {
    final pdf = pw.Document();

    // Si la mascota tiene foto local, se incrusta en el PDF.
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
                      pw.Text('Mascota: ${_mascota?['Nombre'] ?? 'Sin nombre'}', style: pw.TextStyle(fontSize: 18)),
                      pw.Text('Especie: ${_mascota?['Especie'] ?? '-'}'),
                      pw.Text('Raza: ${_mascota?['Raza'] ?? '-'}'),
                      pw.Text('Edad: ${_calcularEdad()}'),
                      pw.Text('Peso: ${_mascota?['Peso'] ?? '-'} kg'),
                      pw.Divider(),
                      pw.Text('Propietario: $_nombrePropietario'),
                      pw.Text('Contacto: $_telefonoPropietario'),
                      pw.Text('Email: $_emailPropietario'),
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
          : _mascota == null
          ? _buildSinMascotas()
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
                  '⚠️ No se pudieron cargar todos tus datos: $_error',
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
          ],
        ),
      ),
    );
  }

  Widget _buildSinMascotas() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.pets, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text(
              'Aún no tienes mascotas registradas',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 8),
            Text(
              'Registra tu primera mascota en "Mis mascotas" para generar su carnet digital.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  // Círculo con la foto real de la mascota (si existe una guardada en el
  // dispositivo) o un ícono de respaldo cuando todavía no tiene foto.
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
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
            child: const Icon(Icons.pets, color: kYellow, size: 36),
          ),
        ),
      );
    }
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
      child: const Icon(Icons.pets, color: kYellow, size: 36),
    );
  }

  Widget _buildCarnetCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1E3A5F), Color(0xFF2D4A7A)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: const Color(0xFF1E3A5F).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: const [Icon(Icons.pets, color: kYellow, size: 24), SizedBox(width: 8), Text('PetCard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18))]),
              Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: kSuccess, borderRadius: BorderRadius.circular(20)), child: const Text('VÁLIDO', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
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
                    Text(_mascota?['Nombre'] ?? 'Sin nombre', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    Text('${_mascota?['Especie'] ?? '-'} · ${_mascota?['Raza'] ?? '-'}', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                _buildDetailRow('EDAD', _calcularEdad(), 'PESO', '${_mascota?['Peso'] ?? '-'} kg'),
                const SizedBox(height: 12),
                _buildDetailRow('RAZA', _mascota?['Raza'] ?? '-', 'SEXO', _mascota?['Sexo'] ?? '-'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: const [Icon(Icons.person, color: Colors.white60, size: 14), SizedBox(width: 4), Text('PROPIETARIO', style: TextStyle(color: Colors.white60, fontSize: 9, fontWeight: FontWeight.bold))]),
                const SizedBox(height: 4),
                Text(_nombrePropietario.isEmpty ? '-' : _nombrePropietario, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    const Icon(Icons.phone, color: Colors.white60, size: 10),
                    const SizedBox(width: 4),
                    Text(_telefonoPropietario.isEmpty ? '-' : _telefonoPropietario, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                    const SizedBox(width: 12),
                    const Icon(Icons.email, color: Colors.white60, size: 10),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _emailPropietario.isEmpty ? '-' : _emailPropietario,
                        style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
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
    return Row(children: [Expanded(child: _buildDetailItem(label1, value1)), Expanded(child: _buildDetailItem(label2, value2))]);
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(color: Colors.white60, fontSize: 8, fontWeight: FontWeight.bold)), Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold))]);
  }
}
