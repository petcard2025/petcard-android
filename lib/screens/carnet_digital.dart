import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';

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

  bool _isLoading = true;
  Map<String, dynamic>? _mascota;
  String _nombrePropietario = 'Carlitos Pinzón';
  String _emailPropietario = 'carlitos@mail.com';
  final String _telefonoPropietario = '300 123 4567';

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usuarioStr = prefs.getString('petcard_usuario_actual');
      if (usuarioStr != null) {
        final usuario = jsonDecode(usuarioStr);
        final nombre = usuario['Nombre'] ?? usuario['nombre'] ?? '';
        final apellido = usuario['Apellido'] ?? usuario['apellido'] ?? '';
        setState(() {
          _nombrePropietario = '$nombre $apellido'.trim();
          if (_nombrePropietario.isEmpty) _nombrePropietario = 'Carlitos Pinzón';
          _emailPropietario = usuario['Correo'] ?? usuario['correo'] ?? 'carlitos@mail.com';
        });
      }
      final mascotasStr = prefs.getString('petcard_mascotas') ?? '[]';
      final List<dynamic> mascotas = jsonDecode(mascotasStr);
      if (mascotas.isNotEmpty) {
        setState(() {
          _mascota = Map<String, dynamic>.from(mascotas.first);
        });
      }
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _descargarPDF() async {
    final pdf = pw.Document();

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
                      pw.Text('Mascota: ${_mascota?['nombre'] ?? 'Benyi'}', style: pw.TextStyle(fontSize: 18)),
                      pw.Text('Especie: ${_mascota?['especie'] ?? 'Perro'}'),
                      pw.Text('Raza: ${_mascota?['raza'] ?? 'Frespuder'}'),
                      pw.Text('Edad: ${_mascota?['edad'] ?? '10 años'}'),
                      pw.Text('Peso: ${_mascota?['peso'] ?? '28'} kg'),
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
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  const SizedBox(height: 24),
                  const Text('Últimos servicios', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  const SizedBox(height: 12),
                  _buildHistoryItem('10 jun 2026', 'Vacunación', 'Completado', true),
                  _buildHistoryItem('01 ago 2026', 'Peluquería', 'Completado', true),
                  _buildHistoryItem('15 sep 2026', 'Consulta Veterinaria', 'Pendiente', false),
                ],
              ),
            ),
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
              Container(width: 64, height: 64, decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle), child: const Icon(Icons.pets, color: kYellow, size: 36)),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_mascota?['nombre'] ?? 'Benyi', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  Text('${_mascota?['especie'] ?? 'Perro'} · ${_mascota?['raza'] ?? 'Frespuder'}', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                _buildDetailRow('EDAD', _mascota?['edad'] ?? '10 años', 'PESO', '${_mascota?['peso'] ?? '28'} kg'),
                const SizedBox(height: 12),
                _buildDetailRow('RAZA', _mascota?['raza'] ?? 'Frespuder', 'SEXO', 'Hembra'),
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
                Text(_nombrePropietario, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    const Icon(Icons.phone, color: Colors.white60, size: 10),
                    const SizedBox(width: 4),
                    Text(_telefonoPropietario, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                    const SizedBox(width: 12),
                    const Icon(Icons.email, color: Colors.white60, size: 10),
                    const SizedBox(width: 4),
                    Text(_emailPropietario, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [Text('Emisión: 24 ago 2026', style: TextStyle(color: Colors.white38, fontSize: 9)), Text('Vencimiento: 24 ago 2027', style: TextStyle(color: Colors.white38, fontSize: 9))],
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

  Widget _buildHistoryItem(String date, String service, String status, bool completed) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.2)))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(service, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), Text(date, style: const TextStyle(color: Colors.grey, fontSize: 12))]),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(color: completed ? const Color(0xFFD1FAE5) : const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(12)),
            child: Text(status.toUpperCase(), style: TextStyle(color: completed ? const Color(0xFF059669) : const Color(0xFFD97706), fontSize: 9, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
