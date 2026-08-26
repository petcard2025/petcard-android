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

  // Controladores para el formulario de nueva mascota
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _especieController = TextEditingController();
  final TextEditingController _razaController = TextEditingController();
  final TextEditingController _pesoController = TextEditingController();
  String _sexoSeleccionado = 'Macho';

  // Controladores para edición
  Map<String, dynamic>? _mascotaEditando;
  bool _editando = false;
  bool _guardando = false;

  // Foto de la mascota (cámara o galería). El backend todavía no soporta
  // subir archivos, así que la foto se guarda de forma local en el
  // dispositivo y se asocia al ID_mascota real que devuelve la API.
  final ImagePicker _imagePicker = ImagePicker();
  File? _fotoSeleccionada; // Foto nueva elegida en esta sesión del formulario
  String? _fotoPathExistente; // Ruta ya guardada, cuando se está editando

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
    super.dispose();
  }

  // ============================================================
  // FOTO DE LA MASCOTA (cámara / galería)
  // ============================================================

  // Muestra un panel para elegir entre tomar una foto o buscarla en galería
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
                leading: const Icon(Icons.photo_camera, color: Color(0xFF7C3AED)),
                title: const Text('Tomar foto'),
                onTap: () {
                  Navigator.pop(context);
                  _seleccionarFoto(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFF7C3AED)),
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

  // Abre la cámara o la galería según la fuente elegida
  Future<void> _seleccionarFoto(ImageSource fuente) async {
    try {
      final XFile? imagen = await _imagePicker.pickImage(
        source: fuente,
        imageQuality: 80, // comprime un poco para no llenar el almacenamiento
        maxWidth: 1200,
      );

      if (imagen == null) return; // el usuario canceló

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
      debugPrint('Error seleccionando foto: $e');
    }
  }

  // Copia la foto elegida a una carpeta permanente de la app, para que
  // siga existiendo aunque el archivo temporal de la cámara/galería se borre
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

  // Como el backend aún no guarda fotos, la ruta local se cachea en
  // SharedPreferences usando el ID_mascota real de la base de datos.
  Future<void> _guardarFotoLocal(dynamic idMascota, String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('foto_mascota_$idMascota', path);
  }

  Future<void> _eliminarFotoLocal(dynamic idMascota) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('foto_mascota_$idMascota');
  }

  // ============================================================
  // CARGA DE DATOS (desde la API / base de datos real)
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
  // GUARDAR MASCOTA (crear en la base de datos vía API)
  // ============================================================
  Future<void> _guardarMascota() async {
    // Validaciones
    if (_nombreController.text.trim().isEmpty ||
        _especieController.text.trim().isEmpty) {
      _mostrarAlerta('Error', '⚠️ Nombre y especie son obligatorios');
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
        'Fecha_nacimiento': null,
      };

      // Se registra en la base de datos y se asocia automáticamente
      // al cliente correspondiente al usuario que inició sesión.
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
      _mostrarAlerta(
        'Error',
        '❌ ${e.toString().replaceFirst('Exception: ', '')}',
      );
      debugPrint('Error guardando mascota: $e');
    }
  }

  // ============================================================
  // ACTUALIZAR MASCOTA (edita el registro en la base de datos)
  // ============================================================
  Future<void> _actualizarMascota() async {
    if (_nombreController.text.trim().isEmpty ||
        _especieController.text.trim().isEmpty) {
      _mostrarAlerta('Error', '⚠️ Nombre y especie son obligatorios');
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
        'Fecha_nacimiento': _mascotaEditando?['Fecha_nacimiento'],
      };

      await _api.actualizarMascota(idMascota, datos);

      // Si el usuario eligió una foto nueva, la copiamos a una ubicación
      // permanente; si pulsó "Quitar foto", borramos la referencia local.
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
      _mostrarAlerta(
        'Error',
        '❌ ${e.toString().replaceFirst('Exception: ', '')}',
      );
      debugPrint('Error actualizando mascota: $e');
    }
  }

  // ============================================================
  // ELIMINAR MASCOTA (se desactiva en la base de datos)
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
        _mostrarAlerta(
          'Error',
          '❌ ${e.toString().replaceFirst('Exception: ', '')}',
        );
        debugPrint('Error eliminando mascota: $e');
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
      _fotoSeleccionada = null;
      _fotoPathExistente = mascota['foto'];
    });
  }

  void _limpiarFormulario() {
    _nombreController.clear();
    _especieController.clear();
    _razaController.clear();
    _pesoController.clear();
    _sexoSeleccionado = 'Macho';
    _mascotaEditando = null;
    _editando = false;
    _fotoSeleccionada = null;
    _fotoPathExistente = null;
  }

  // ============================================================
  // UTILIDADES
  // ============================================================
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

  // ============================================================
  // CONSTRUCCIÓN DE LA INTERFAZ
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF7C3AED),
        elevation: 0,
        title: Row(
          children: [
            Icon(Icons.pets, color: Colors.white, size: 24),
            const SizedBox(width: 8),
            const Text(
              'PETCARD',
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
              // ==========================================================
              // TÍTULO Y CONTADOR
              // ==========================================================
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
                      color: const Color(0xFF7C3AED).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_mascotas.length} mascotas',
                      style: const TextStyle(
                        color: Color(0xFF7C3AED),
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

              // ==========================================================
              // ERROR AL CARGAR DESDE LA API
              // ==========================================================
              if (_error != null && !_mostrarFormulario) _buildErrorState(),

              // ==========================================================
              // FORMULARIO DE NUEVA MASCOTA
              // ==========================================================
              if (_mostrarFormulario) _buildFormularioMascota(),

              // ==========================================================
              // LISTA DE MASCOTAS
              // ==========================================================
              if (_error == null) ...[
                if (_mascotas.isEmpty && !_mostrarFormulario)
                  _buildEmptyState()
                else if (!_mostrarFormulario)
                  ..._mascotas.map((mascota) => _buildMascotaCard(mascota)),
              ],

              const SizedBox(height: 20),

              // ==========================================================
              // BOTÓN AGREGAR MASCOTA (cuando no hay formulario)
              // ==========================================================
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
                    icon: const Icon(Icons.add, color: Color(0xFF7C3AED)),
                    label: const Text(
                      'Agregar nueva mascota',
                      style: TextStyle(
                        color: Color(0xFF7C3AED),
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
  // WIDGET - ESTADO DE ERROR (falla la conexión con la API)
  // ============================================================
  Widget _buildErrorState() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
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
            icon: const Icon(Icons.refresh, size: 16, color: Color(0xFF7C3AED)),
            label: const Text(
              'Reintentar',
              style: TextStyle(color: Color(0xFF7C3AED), fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // WIDGETS - FORMULARIO DE MASCOTA
  // ============================================================
  Widget _buildFormularioMascota() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
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
                    color: const Color(0xFF7C3AED),
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

          // Foto de la mascota
          Center(child: _buildSelectorFoto()),
          const SizedBox(height: 20),

          // Nombre
          _buildCampoFormulario(
            label: 'Nombre de la mascota',
            hint: 'Ej. Benyi',
            controller: _nombreController,
          ),
          const SizedBox(height: 12),

          // Especie
          _buildCampoFormulario(
            label: 'Especie',
            hint: 'Ej. Perro, Gato, Ave',
            controller: _especieController,
          ),
          const SizedBox(height: 12),

          // Raza
          _buildCampoFormulario(
            label: 'Raza',
            hint: 'Ej. Labrador',
            controller: _razaController,
          ),
          const SizedBox(height: 12),

          // Sexo y Peso en Row
          Row(
            children: [
              Expanded(child: _buildSelectorSexo()),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCampoFormulario(
                  label: 'Peso (kg)',
                  hint: 'Ej. 15',
                  controller: _pesoController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Botón Guardar
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _guardando
                  ? null
                  : (_editando ? _actualizarMascota : _guardarMascota),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
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
    );
  }

  // ============================================================
  // WIDGET - SELECTOR DE SEXO
  // ============================================================
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

  // ============================================================
  // WIDGET - SELECTOR DE FOTO (cámara / galería)
  // ============================================================
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
              color: const Color(0xFF7C3AED).withOpacity(0.08),
              border: Border.all(
                color: const Color(0xFF7C3AED).withOpacity(0.3),
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
                color: Color(0xFF7C3AED),
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

  Widget _buildCampoFormulario({
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
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
        TextField(
          controller: controller,
          keyboardType: keyboardType,
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
              borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 2),
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

  // ============================================================
  // WIDGETS - TARJETA DE MASCOTA
  // ============================================================
  Widget _buildMascotaCard(Map<String, dynamic> mascota) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar (foto de la mascota, o ícono si no tiene)
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withOpacity(0.1),
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
                  color: const Color(0xFF7C3AED),
                  size: 28,
                ),
              ),
            )
                : Icon(
              _getIconForEspecie(mascota['Especie'] ?? ''),
              color: const Color(0xFF7C3AED),
              size: 28,
            ),
          ),
          const SizedBox(width: 14),

          // Información
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
              ],
            ),
          ),

          // Botones de acción
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.edit, size: 18, color: Colors.grey[600]),
                onPressed: () => _editarMascota(mascota),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: Colors.red[300],
                ),
                onPressed: () => _eliminarMascota(mascota['ID_mascota']),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getIconForEspecie(String especie) {
    final especieLower = especie.toLowerCase();
    if (especieLower.contains('perro')) return Icons.pets;
    if (especieLower.contains('gato')) return Icons.pets;
    if (especieLower.contains('ave') || especieLower.contains('pajaro')) {
      return Icons.flight;
    }
    if (especieLower.contains('pez')) return Icons.set_meal;
    if (especieLower.contains('conejo')) return Icons.pets;
    return Icons.pets;
  }

  // ============================================================
  // WIDGETS - ESTADO VACÍO
  // ============================================================
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
}
