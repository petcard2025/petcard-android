// ============================================================
// MIS MASCOTAS SCREEN - Gestión de mascotas
// Conectada al backend real (Node/Express + MySQL) a través de
// ApiService, igual que se hizo con el módulo de usuarios.
// ============================================================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../services/api_service.dart';
import 'carnet_digital.dart';

class MisMascotasScreen extends StatefulWidget {
  const MisMascotasScreen({super.key});

  @override
  State<MisMascotasScreen> createState() => _MisMascotasScreenState();
}

class _MisMascotasScreenState extends State<MisMascotasScreen> {
  // ============================================================
  // API Y VARIABLES DE ESTADO
  // ============================================================
  final ApiService _api = ApiService();

  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _mascotas = [];
  bool _mostrarFormulario = false;
  bool _editando = false;
  bool _guardando = false;

  // Controladores para el formulario
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _especieController = TextEditingController();
  final TextEditingController _razaController = TextEditingController();
  final TextEditingController _pesoController = TextEditingController();
  final TextEditingController _fechaNacimientoController = TextEditingController();
  String _sexoSeleccionado = 'Macho';
  Map<String, dynamic>? _mascotaEditando;

  // Foto de la mascota
  final ImagePicker _imagePicker = ImagePicker();
  File? _fotoSeleccionada;
  String? _fotoPathExistente;

  // ============================================================
  // COLORES
  // ============================================================
  static const Color kAzul = Color(0xFF2563EB);
  static const Color kRojo = Color(0xFFDC2626);

  // ============================================================
  // CICLO DE VIDA
  // ============================================================
  @override
  void initState() {
    super.initState();
    _cargarMascotas();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _especieController.dispose();
    _razaController.dispose();
    _pesoController.dispose();
    _fechaNacimientoController.dispose();
    super.dispose();
  }

  // ============================================================
  // FUNCIONES DE VALIDACIÓN
  // ============================================================
  String? _validarTexto(String? value, String campo) {
    if (value == null || value.trim().isEmpty) {
      return 'El $campo es obligatorio';
    }
    final texto = value.trim();
    final regex = RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$');
    if (!regex.hasMatch(texto)) {
      return 'El $campo no debe contener números';
    }
    return null;
  }

  String? _validarPeso(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El peso es obligatorio';
    }
    final peso = double.tryParse(value.trim().replaceAll(',', '.'));
    if (peso == null) {
      return 'Ingresa un número válido';
    }
    if (peso <= 0) {
      return 'El peso debe ser mayor a 0';
    }
    if (peso > 150) {
      return 'El peso máximo es 150 kg';
    }
    return null;
  }

  String? _validarFechaNacimiento(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Opcional
    }
    final fecha = DateTime.tryParse(value.trim());
    if (fecha == null) {
      return 'Formato inválido (YYYY-MM-DD)';
    }
    if (fecha.isAfter(DateTime.now())) {
      return 'La fecha no puede ser futura';
    }
    return null;
  }

  String? _calcularEdadDesdeFecha(String? fechaNacimiento) {
    if (fechaNacimiento == null || fechaNacimiento.isEmpty) return null;
    final nacimiento = DateTime.tryParse(fechaNacimiento);
    if (nacimiento == null) return null;
    final ahora = DateTime.now();
    int anios = ahora.year - nacimiento.year;
    if (ahora.month < nacimiento.month ||
        (ahora.month == nacimiento.month && ahora.day < nacimiento.day)) {
      anios--;
    }
    if (anios < 0) return null;
    if (anios == 0) return 'Menos de 1 año';
    return '$anios años';
  }

  // ============================================================
  // FOTO DE LA MASCOTA
  // ============================================================
  Future<void> _mostrarOpcionesFoto() async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: Text(
                    'Foto de la mascota',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera, color: kAzul),
                title: const Text('Tomar foto'),
                onTap: () {
                  Navigator.pop(context);
                  _seleccionarFoto(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: kAzul),
                title: const Text('Elegir de la galería'),
                onTap: () {
                  Navigator.pop(context);
                  _seleccionarFoto(ImageSource.gallery);
                },
              ),
              if (_fotoSeleccionada != null || _fotoPathExistente != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text('Quitar foto', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _fotoSeleccionada = null;
                      _fotoPathExistente = null;
                    });
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _seleccionarFoto(ImageSource fuente) async {
    try {
      final XFile? imagen = await _imagePicker.pickImage(
        source: fuente,
        imageQuality: 80,
        maxWidth: 1200,
      );
      if (imagen == null) return;
      setState(() {
        _fotoSeleccionada = File(imagen.path);
        _fotoPathExistente = null;
      });
    } catch (e) {
      if (!mounted) return;
      _mostrarAlerta(
        'Error',
        '❌ No se pudo acceder a la cámara o galería. Verifica los permisos de la app.',
      );
    }
  }

  Future<String?> _guardarFotoPermanente(File foto, dynamic idMascota) async {
    try {
      final directorioApp = await getApplicationDocumentsDirectory();
      final carpetaFotos = Directory('${directorioApp.path}/mascotas_fotos');
      if (!await carpetaFotos.exists()) {
        await carpetaFotos.create(recursive: true);
      }
      final extension = foto.path.split('.').last;
      final nuevoPath = '${carpetaFotos.path}/mascota_$idMascota.$extension';
      final nuevoArchivo = await foto.copy(nuevoPath);
      return nuevoArchivo.path;
    } catch (e) {
      debugPrint('Error guardando foto: $e');
      return null;
    }
  }

  Future<void> _guardarFotoLocal(dynamic idMascota, String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('foto_mascota_$idMascota', path);
  }

  Future<void> _eliminarFotoLocal(dynamic idMascota) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('foto_mascota_$idMascota');
  }

  // ============================================================
  // CARGA DE DATOS
  // ============================================================
  Future<void> _cargarMascotas() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final mascotas = await _api.obtenerMisMascotas();
      final prefs = await SharedPreferences.getInstance();

      for (final mascota in mascotas) {
        final id = mascota['ID_mascota'];
        final fotoLocal = prefs.getString('foto_mascota_$id');
        if (fotoLocal != null) {
          mascota['foto'] = fotoLocal;
        }
      }

      _mascotas = mascotas;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      debugPrint('Error cargando mascotas: $_error');
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  // ============================================================
  // GUARDAR MASCOTA
  // ============================================================
  Future<void> _guardarMascota() async {
    // Validaciones
    final nombreError = _validarTexto(_nombreController.text, 'nombre');
    if (nombreError != null) {
      _mostrarAlerta('Error', nombreError);
      return;
    }

    final especieError = _validarTexto(_especieController.text, 'especie');
    if (especieError != null) {
      _mostrarAlerta('Error', especieError);
      return;
    }

    final razaError = _validarTexto(_razaController.text, 'raza');
    if (razaError != null) {
      _mostrarAlerta('Error', razaError);
      return;
    }

    final pesoError = _validarPeso(_pesoController.text);
    if (pesoError != null) {
      _mostrarAlerta('Error', pesoError);
      return;
    }

    final fechaError = _validarFechaNacimiento(_fechaNacimientoController.text);
    if (fechaError != null) {
      _mostrarAlerta('Error', fechaError);
      return;
    }

    setState(() => _guardando = true);

    try {
      final datos = {
        'Nombre': _nombreController.text.trim(),
        'Especie': _especieController.text.trim(),
        'Raza': _razaController.text.trim(),
        'Sexo': _sexoSeleccionado,
        'Peso': double.tryParse(_pesoController.text.trim().replaceAll(',', '.')),
        'Fecha_nacimiento': _fechaNacimientoController.text.trim().isEmpty
            ? null
            : _fechaNacimientoController.text.trim(),
      };

      final creada = await _api.crearMiMascota(datos);

      final idMascota = creada['ID_mascota'];
      if (_fotoSeleccionada != null && idMascota != null) {
        final fotoPath = await _guardarFotoPermanente(_fotoSeleccionada!, idMascota);
        if (fotoPath != null) {
          await _guardarFotoLocal(idMascota, fotoPath);
        }
      }

      _limpiarFormulario();
      if (!mounted) return;
      setState(() {
        _mostrarFormulario = false;
        _editando = false;
        _guardando = false;
      });

      await _cargarMascotas();
      if (!mounted) return;
      _mostrarAlerta('Éxito', '✅ Mascota registrada correctamente');
    } catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      _mostrarAlerta('Error', '❌ ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }

  // ============================================================
  // ACTUALIZAR MASCOTA
  // ============================================================
  Future<void> _actualizarMascota() async {
    // Validaciones
    final nombreError = _validarTexto(_nombreController.text, 'nombre');
    if (nombreError != null) {
      _mostrarAlerta('Error', nombreError);
      return;
    }

    final especieError = _validarTexto(_especieController.text, 'especie');
    if (especieError != null) {
      _mostrarAlerta('Error', especieError);
      return;
    }

    final razaError = _validarTexto(_razaController.text, 'raza');
    if (razaError != null) {
      _mostrarAlerta('Error', razaError);
      return;
    }

    final pesoError = _validarPeso(_pesoController.text);
    if (pesoError != null) {
      _mostrarAlerta('Error', pesoError);
      return;
    }

    final fechaError = _validarFechaNacimiento(_fechaNacimientoController.text);
    if (fechaError != null) {
      _mostrarAlerta('Error', fechaError);
      return;
    }

    final idMascota = _mascotaEditando?['ID_mascota'];
    if (idMascota == null) {
      _mostrarAlerta('Error', '❌ No se encontró la mascota a actualizar');
      return;
    }

    setState(() => _guardando = true);

    try {
      final datos = {
        'Nombre': _nombreController.text.trim(),
        'Especie': _especieController.text.trim(),
        'Raza': _razaController.text.trim(),
        'Sexo': _sexoSeleccionado,
        'Peso': double.tryParse(_pesoController.text.trim().replaceAll(',', '.')),
        'Fecha_nacimiento': _fechaNacimientoController.text.trim().isEmpty
            ? null
            : _fechaNacimientoController.text.trim(),
      };

      await _api.actualizarMascota(idMascota, datos);

      if (_fotoSeleccionada != null) {
        final fotoPath = await _guardarFotoPermanente(_fotoSeleccionada!, idMascota);
        if (fotoPath != null) {
          await _guardarFotoLocal(idMascota, fotoPath);
        }
      } else if (_fotoPathExistente == null) {
        await _eliminarFotoLocal(idMascota);
      }

      _limpiarFormulario();
      if (!mounted) return;
      setState(() {
        _mostrarFormulario = false;
        _editando = false;
        _mascotaEditando = null;
        _guardando = false;
      });

      await _cargarMascotas();
      if (!mounted) return;
      _mostrarAlerta('Éxito', '✅ Mascota actualizada correctamente');
    } catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      _mostrarAlerta('Error', '❌ ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }

  // ============================================================
  // ELIMINAR MASCOTA
  // ============================================================
  Future<void> _eliminarMascota(dynamic id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar mascota'),
        content: const Text('¿Estás seguro que deseas eliminar esta mascota?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _api.eliminarMascota(id);
        await _eliminarFotoLocal(id);
        await _cargarMascotas();
        if (!mounted) return;
        _mostrarAlerta('Éxito', '✅ Mascota eliminada correctamente');
      } catch (e) {
        _mostrarAlerta('Error', '❌ ${e.toString().replaceFirst('Exception: ', '')}');
      }
    }
  }

  // ============================================================
  // EDICIÓN
  // ============================================================
  void _editarMascota(Map<String, dynamic> mascota) {
    setState(() {
      _mascotaEditando = mascota;
      _editando = true;
      _mostrarFormulario = true;
      _nombreController.text = (mascota['Nombre'] ?? '').toString();
      _especieController.text = (mascota['Especie'] ?? '').toString();
      _razaController.text = (mascota['Raza'] ?? '').toString();
      _sexoSeleccionado = (mascota['Sexo'] ?? 'Macho').toString();
      _pesoController.text = mascota['Peso'] != null ? mascota['Peso'].toString() : '';
      _fechaNacimientoController.text = (mascota['Fecha_nacimiento'] ?? '').toString();
      _fotoSeleccionada = null;
      _fotoPathExistente = mascota['foto'];
    });
  }

  void _limpiarFormulario() {
    _nombreController.clear();
    _especieController.clear();
    _razaController.clear();
    _pesoController.clear();
    _fechaNacimientoController.clear();
    _sexoSeleccionado = 'Macho';
    _mascotaEditando = null;
    _editando = false;
    _fotoSeleccionada = null;
    _fotoPathExistente = null;
  }

  void _mostrarAlerta(String titulo, String mensaje) {
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

  IconData _getIconForEspecie(String especie) {
    final especieLower = especie.toLowerCase();
    if (especieLower.contains('perro') || especieLower.contains('gato')) {
      return Icons.pets;
    }
    if (especieLower.contains('ave') || especieLower.contains('pajaro')) {
      return Icons.flight;
    }
    return Icons.pets;
  }

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: kAzul,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.pets, color: Colors.white, size: 24),
            const SizedBox(width: 8),
            const Text(
              'Mis Mascotas',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _isLoading ? null : _cargarMascotas,
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () {
              setState(() {
                _mostrarFormulario = true;
                _editando = false;
                _limpiarFormulario();
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _cargarMascotas,
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
                    'Mis Mascotas',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: kAzul.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_mascotas.length} mascotas',
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
                'Gestiona la información de tus mascotas',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 20),

              if (_error != null && !_mostrarFormulario) _buildErrorState(),
              if (_mostrarFormulario) _buildFormularioMascota(),
              if (_error == null) ...[
                if (_mascotas.isEmpty && !_mostrarFormulario)
                  _buildEmptyState()
                else if (!_mostrarFormulario)
                  ..._mascotas.map((mascota) => _buildMascotaCard(mascota)),
              ],
              const SizedBox(height: 20),

              if (!_mostrarFormulario)
                Center(
                  child: TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _mostrarFormulario = true;
                        _editando = false;
                        _limpiarFormulario();
                      });
                    },
                    icon: const Icon(Icons.add, color: kAzul),
                    label: const Text(
                      'Agregar nueva mascota',
                      style: TextStyle(
                        color: kAzul,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // WIDGETS
  // ============================================================
  Widget _buildErrorState() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red[400], size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'No se pudieron cargar tus mascotas',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _error ?? '',
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: _cargarMascotas,
            icon: const Icon(Icons.refresh, size: 16, color: kAzul),
            label: const Text(
              'Reintentar',
              style: TextStyle(color: kAzul, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormularioMascota() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Form(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      _editando ? Icons.edit : Icons.pets,
                      size: 18,
                      color: kAzul,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _editando ? 'Editar Mascota' : 'Registra tu Mascota',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () {
                    setState(() {
                      _mostrarFormulario = false;
                      _limpiarFormulario();
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _editando
                  ? 'Actualiza los datos de tu mascota'
                  : 'Ingresa los datos básicos de tu nueva mascota',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),

            Center(child: _buildSelectorFoto()),
            const SizedBox(height: 20),

            // NOMBRE - Validación sin números
            _buildCampoFormulario(
              label: 'Nombre de la mascota',
              hint: 'Ej. Max',
              controller: _nombreController,
              validator: (value) => _validarTexto(value, 'nombre'),
            ),
            const SizedBox(height: 12),

            // ESPECIE - Validación sin números
            _buildCampoFormulario(
              label: 'Especie',
              hint: 'Ej. Perro, Gato, Ave',
              controller: _especieController,
              validator: (value) => _validarTexto(value, 'especie'),
            ),
            const SizedBox(height: 12),

            // RAZA - Validación sin números
            _buildCampoFormulario(
              label: 'Raza',
              hint: 'Ej. Labrador',
              controller: _razaController,
              validator: (value) => _validarTexto(value, 'raza'),
            ),
            const SizedBox(height: 12),

            // SEXO
            _buildSelectorSexo(),
            const SizedBox(height: 12),

            // PESO - Validación 0-150 kg
            _buildCampoFormulario(
              label: 'Peso (kg)',
              hint: 'Ej. 15',
              controller: _pesoController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: _validarPeso,
            ),
            const SizedBox(height: 12),

            // FECHA DE NACIMIENTO
            _buildCampoFormulario(
              label: 'Fecha de nacimiento',
              hint: 'YYYY-MM-DD',
              controller: _fechaNacimientoController,
              validator: _validarFechaNacimiento,
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _guardando
                    ? null
                    : (_editando ? _actualizarMascota : _guardarMascota),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kAzul,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _guardando
                    ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : Text(
                  _editando ? 'Actualizar Mascota' : 'Guardar mascota',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCampoFormulario({
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            isDense: true,
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildSelectorSexo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sexo',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _sexoSeleccionado,
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: 'Macho', child: Text('Macho')),
                DropdownMenuItem(value: 'Hembra', child: Text('Hembra')),
              ],
              onChanged: (valor) {
                setState(() => _sexoSeleccionado = valor ?? 'Macho');
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectorFoto() {
    final tieneFotoNueva = _fotoSeleccionada != null;
    final tieneFotoExistente = !tieneFotoNueva && _fotoPathExistente != null;

    Widget contenidoCirculo;
    if (tieneFotoNueva) {
      contenidoCirculo = ClipOval(
        child: Image.file(
          _fotoSeleccionada!,
          width: 96,
          height: 96,
          fit: BoxFit.cover,
        ),
      );
    } else if (tieneFotoExistente) {
      contenidoCirculo = ClipOval(
        child: Image.file(
          File(_fotoPathExistente!),
          width: 96,
          height: 96,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Icon(
            Icons.pets,
            size: 36,
            color: Colors.grey[400],
          ),
        ),
      );
    } else {
      contenidoCirculo = Icon(
        Icons.add_a_photo_outlined,
        size: 30,
        color: Colors.grey[400],
      );
    }

    return GestureDetector(
      onTap: _mostrarOpcionesFoto,
      child: Stack(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: kAzul.withValues(alpha: 0.08),
              border: Border.all(
                color: kAzul.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Center(child: contenidoCirculo),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: kAzul,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt,
                size: 14,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.pets, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No tienes mascotas registradas',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Agrega tu primera mascota para comenzar',
            style: TextStyle(fontSize: 13, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildMascotaCard(Map<String, dynamic> mascota) {
    final edad = _calcularEdadDesdeFecha(mascota['Fecha_nacimiento']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: kAzul.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: (mascota['foto'] != null && mascota['foto'].toString().isNotEmpty)
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.file(
                    File(mascota['foto']),
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      _getIconForEspecie(mascota['Especie'] ?? ''),
                      color: kAzul,
                      size: 28,
                    ),
                  ),
                )
                    : Icon(
                  _getIconForEspecie(mascota['Especie'] ?? ''),
                  color: kAzul,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mascota['Nombre'] ?? 'Sin nombre',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${mascota['Especie'] ?? ''} • ${mascota['Raza'] ?? ''} • ${mascota['Sexo'] ?? ''}'
                          '${mascota['Peso'] != null ? ' • ${mascota['Peso']} kg' : ''}',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                    if (edad != null)
                      Text(
                        '🎂 $edad',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // BOTON "VER CARNET" - SEPARADO
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CarnetDigitalScreen(
                      idMascota: mascota['ID_mascota'],
                      nombreMascota: mascota['Nombre'] ?? 'Sin nombre',
                      especie: mascota['Especie'] ?? '',
                      raza: mascota['Raza'] ?? '',
                      sexo: mascota['Sexo'] ?? '',
                      peso: (mascota['Peso'] ?? 0).toDouble(),
                      fechaNacimiento: mascota['Fecha_nacimiento'],
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.medical_services, size: 16),
              label: const Text('Ver carnet de vacunas'),
              style: OutlinedButton.styleFrom(
                foregroundColor: kAzul,
                side: const BorderSide(color: kAzul),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // BOTONES EDITAR Y ELIMINAR
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _editarMascota(mascota),
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
                  onPressed: () => _eliminarMascota(mascota['ID_mascota']),
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
}