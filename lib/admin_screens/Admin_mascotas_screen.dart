// ============================================================
// ADMIN · MASCOTAS SCREEN
// Gestion de todas las mascotas del sistema
// ============================================================

import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AdminMascotasScreen extends StatefulWidget {
  const AdminMascotasScreen({super.key});

  @override
  State<AdminMascotasScreen> createState() => _AdminMascotasScreenState();
}

class _AdminMascotasScreenState extends State<AdminMascotasScreen> {
  static const Color kAzul = Color(0xFF2563EB);
  static const Color kRojo = Color(0xFFDC2626);
  static const Color kVerde = Color(0xFF16A34A);

  final ApiService _api = ApiService();

  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _mascotas = [];

  String _busqueda = '';
  String _filtroEspecie = 'Todas';

  // Formulario
  bool _mostrarFormulario = false;
  bool _editando = false;
  dynamic _mascotaEditandoId;

  final _nombreCtrl = TextEditingController();
  final _especieCtrl = TextEditingController();
  final _razaCtrl = TextEditingController();
  final _sexoCtrl = TextEditingController();
  final _pesoCtrl = TextEditingController();
  final _clienteCtrl = TextEditingController();
  final _fechaNacimientoCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _especieCtrl.dispose();
    _razaCtrl.dispose();
    _sexoCtrl.dispose();
    _pesoCtrl.dispose();
    _clienteCtrl.dispose();
    _fechaNacimientoCtrl.dispose();
    super.dispose();
  }

  // ─── VALIDACIONES ───
  String? _validarTexto(String? value, String campo) {
    if (value == null || value.trim().isEmpty) {
      return 'El $campo es obligatorio';
    }
    final texto = value.trim();
    final regex = RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$');
    if (!regex.hasMatch(texto)) {
      return 'El $campo no debe contener numeros';
    }
    return null;
  }

  String? _validarPeso(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El peso es obligatorio';
    }
    final peso = double.tryParse(value.trim().replaceAll(',', '.'));
    if (peso == null) {
      return 'Ingresa un numero valido';
    }
    if (peso <= 0) {
      return 'El peso debe ser mayor a 0';
    }
    if (peso > 150) {
      return 'El peso maximo es 150 kg';
    }
    return null;
  }

  String? _validarFechaNacimiento(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final fecha = DateTime.tryParse(value.trim());
    if (fecha == null) {
      return 'Formato invalido (YYYY-MM-DD)';
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
    int edad = ahora.year - nacimiento.year;
    if (ahora.month < nacimiento.month ||
        (ahora.month == nacimiento.month && ahora.day < nacimiento.day)) {
      edad--;
    }
    if (edad < 0) return null;
    if (edad == 0) return 'Menos de 1 año';
    return '$edad años';
  }

  // ─── CARGA DE DATOS ───
  Future<void> _cargarDatos() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      _mascotas = await _api.obtenerMascotasAdmin();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    }
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  List<Map<String, dynamic>> get _mascotasFiltradas {
    final texto = _busqueda.toLowerCase();
    return _mascotas.where((m) {
      final combinado = '${m['Nombre'] ?? ''} ${m['Nombre_dueno'] ?? ''}'.toLowerCase();
      final coincideBusqueda = combinado.contains(texto);
      final especie = (m['Especie'] ?? '').toString();
      final coincideEspecie = _filtroEspecie == 'Todas' || especie == _filtroEspecie;
      return coincideBusqueda && coincideEspecie;
    }).toList();
  }

  List<String> get _especies {
    final set = <String>{};
    for (final m in _mascotas) {
      final e = (m['Especie'] ?? '').toString();
      if (e.isNotEmpty) set.add(e);
    }
    return ['Todas', ...set];
  }

  void _limpiarFormulario() {
    _nombreCtrl.clear();
    _especieCtrl.clear();
    _razaCtrl.clear();
    _sexoCtrl.text = 'Macho';
    _pesoCtrl.clear();
    _clienteCtrl.clear();
    _fechaNacimientoCtrl.clear();
    _mascotaEditandoId = null;
    _editando = false;
  }

  void _abrirNuevo() {
    _limpiarFormulario();
    setState(() => _mostrarFormulario = true);
  }

  void _abrirEditar(Map<String, dynamic> m) {
    _mascotaEditandoId = m['ID_mascota'];
    _nombreCtrl.text = (m['Nombre'] ?? '').toString();
    _especieCtrl.text = (m['Especie'] ?? '').toString();
    _razaCtrl.text = (m['Raza'] ?? '').toString();
    _sexoCtrl.text = (m['Sexo'] ?? 'Macho').toString();
    _pesoCtrl.text = (m['Peso'] ?? '').toString();
    _clienteCtrl.text = (m['Nombre_dueno'] ?? '').toString();
    _fechaNacimientoCtrl.text = (m['Fecha_nacimiento'] ?? '').toString();
    _editando = true;
    setState(() => _mostrarFormulario = true);
  }

  Future<void> _guardarMascota() async {
    // Validaciones
    final nombreError = _validarTexto(_nombreCtrl.text, 'nombre');
    if (nombreError != null) {
      _mostrarAlerta('Atencion', nombreError);
      return;
    }

    final especieError = _validarTexto(_especieCtrl.text, 'especie');
    if (especieError != null) {
      _mostrarAlerta('Atencion', especieError);
      return;
    }

    final razaError = _validarTexto(_razaCtrl.text, 'raza');
    if (razaError != null) {
      _mostrarAlerta('Atencion', razaError);
      return;
    }

    final pesoError = _validarPeso(_pesoCtrl.text);
    if (pesoError != null) {
      _mostrarAlerta('Atencion', pesoError);
      return;
    }

    final fechaError = _validarFechaNacimiento(_fechaNacimientoCtrl.text);
    if (fechaError != null) {
      _mostrarAlerta('Atencion', fechaError);
      return;
    }

    final datos = {
      'Nombre': _nombreCtrl.text.trim(),
      'Especie': _especieCtrl.text.trim(),
      'Raza': _razaCtrl.text.trim(),
      'Sexo': _sexoCtrl.text.trim(),
      'Peso': double.tryParse(_pesoCtrl.text.trim()) ?? 0,
      'ID_cliente': int.tryParse(_clienteCtrl.text.trim()) ?? 0,
      'Fecha_nacimiento': _fechaNacimientoCtrl.text.trim().isEmpty
          ? null
          : _fechaNacimientoCtrl.text.trim(),
    };

    try {
      if (_editando) {
        await _api.actualizarMascota(_mascotaEditandoId, datos);
      } else {
        await _api.crearMascota(datos);
      }
      if (!mounted) return;
      setState(() => _mostrarFormulario = false);
      await _cargarDatos();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_editando ? '✅ Mascota actualizada' : '✅ Mascota creada'),
          backgroundColor: kVerde,
        ),
      );
    } catch (e) {
      _mostrarAlerta('Error', e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _confirmarEliminar(Map<String, dynamic> m) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar mascota?'),
        content: Text('¿Deseas eliminar a ${m['Nombre'] ?? ''}?'),
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
      await _api.eliminarMascota(m['ID_mascota']);
      await _cargarDatos();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🗑️ Mascota eliminada'), backgroundColor: Colors.red),
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

  String _getIconoEspecie(String especie) {
    final e = especie.toLowerCase();
    if (e.contains('gato')) return '🐱';
    if (e.contains('perro')) return '🐶';
    if (e.contains('ave')) return '🐦';
    if (e.contains('conejo')) return '🐰';
    return '🐾';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: kAzul,
        elevation: 0,
        title: const Text(
          'Mascotas · Admin',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: _mostrarFormulario
          ? null
          : FloatingActionButton.extended(
        onPressed: _abrirNuevo,
        backgroundColor: kAzul,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Nueva Mascota',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: Stack(
        children: [
          _buildBody(),
          if (_mostrarFormulario) _buildFormulario(),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: kAzul));
    }

    return RefreshIndicator(
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
                  'Gestion de Mascotas',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
              'Administra todas las mascotas del sistema',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            _buildBuscadorYFiltro(),
            const SizedBox(height: 16),
            if (_error != null)
              _buildEstadoMensaje(icono: Icons.wifi_off, texto: _error!, color: kRojo)
            else if (_mascotasFiltradas.isEmpty)
              _buildEstadoMensaje(
                icono: Icons.pets,
                texto: 'No se encontraron mascotas.',
                color: Colors.grey,
              )
            else
              ..._mascotasFiltradas.map(_buildMascotaCard),
            const SizedBox(height: 80),
          ],
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
            hintText: 'Buscar por nombre o dueno...',
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
            itemCount: _especies.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final especie = _especies[i];
              final activo = _filtroEspecie == especie;
              return ChoiceChip(
                label: Text(especie),
                selected: activo,
                onSelected: (_) => setState(() => _filtroEspecie = especie),
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
          Icon(icono, size: 40, color: color.withValues(alpha: 0.6)),
          const SizedBox(height: 10),
          Text(texto, style: TextStyle(color: Colors.grey[600], fontSize: 13.5)),
        ],
      ),
    );
  }

  Widget _buildMascotaCard(Map<String, dynamic> m) {
    final edad = _calcularEdadDesdeFecha(m['Fecha_nacimiento']);

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
              Text(_getIconoEspecie(m['Especie'] ?? ''), style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m['Nombre'] ?? 'Sin nombre',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    Text(
                      '${m['Especie'] ?? ''} · ${m['Raza'] ?? ''}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    if (edad != null)
                      Text(
                        '🎂 $edad',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: (m['Sexo'] == 'Hembra')
                      ? Colors.pink.withValues(alpha: 0.1)
                      : Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  m['Sexo'] ?? 'Macho',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: (m['Sexo'] == 'Hembra') ? Colors.pink : Colors.blue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '👤 Dueno: ${m['Nombre_dueno'] ?? 'Sin dueno'}',
            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
          ),
          if (m['Peso'] != null)
            Text(
              '⚖️ ${m['Peso']} kg',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          if (m['Fecha_nacimiento'] != null)
            Text(
              '🎂 Nacimiento: ${m['Fecha_nacimiento']}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _abrirEditar(m),
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
                  onPressed: () => _confirmarEliminar(m),
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

  // ============================================================
  // FORMULARIO
  // ============================================================
  Widget _buildFormulario() {
    return Container(
      color: Colors.black.withValues(alpha: 0.5),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 500,
              padding: const EdgeInsets.all(24),
              child: Form(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _editando ? 'Editar Mascota' : 'Nueva Mascota',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            setState(() => _mostrarFormulario = false);
                            _limpiarFormulario();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // NOMBRE - Validacion sin numeros
                    _campoTextoValidado(
                      label: 'Nombre',
                      controller: _nombreCtrl,
                      hint: 'Ej. Max',
                      validator: (value) => _validarTexto(value, 'nombre'),
                    ),
                    const SizedBox(height: 12),

                    // ESPECIE - Validacion sin numeros
                    _campoTextoValidado(
                      label: 'Especie',
                      controller: _especieCtrl,
                      hint: 'Ej. Perro, Gato',
                      validator: (value) => _validarTexto(value, 'especie'),
                    ),
                    const SizedBox(height: 12),

                    // RAZA - Validacion sin numeros
                    _campoTextoValidado(
                      label: 'Raza',
                      controller: _razaCtrl,
                      hint: 'Ej. Labrador',
                      validator: (value) => _validarTexto(value, 'raza'),
                    ),
                    const SizedBox(height: 12),

                    _buildDropdownBusqueda(
                      label: 'Sexo',
                      controller: _sexoCtrl,
                      opciones: ['Macho', 'Hembra'],
                    ),
                    const SizedBox(height: 12),

                    // PESO - Validacion 0-150 kg
                    _campoTextoValidado(
                      label: 'Peso (kg)',
                      controller: _pesoCtrl,
                      hint: 'Ej. 25',
                      keyboardType: TextInputType.number,
                      validator: _validarPeso,
                    ),
                    const SizedBox(height: 12),

                    // ID CLIENTE
                    _campoTexto(
                      'ID Cliente',
                      _clienteCtrl,
                      hint: 'ID del dueno',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),

                    // FECHA DE NACIMIENTO
                    _campoTextoValidado(
                      label: 'Fecha nacimiento',
                      controller: _fechaNacimientoCtrl,
                      hint: 'YYYY-MM-DD',
                      validator: _validarFechaNacimiento,
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _guardarMascota,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kAzul,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          _editando ? 'Actualizar' : 'Agregar',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _campoTexto(
      String label,
      TextEditingController controller, {
        String? hint,
        int maxLines = 1,
        TextInputType keyboardType = TextInputType.text,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[700])),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
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
    );
  }

  Widget _campoTextoValidado({
    required String label,
    required TextEditingController controller,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[700])),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
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
    );
  }

  Widget _buildDropdownBusqueda({
    required String label,
    required TextEditingController controller,
    required List<String> opciones,
  }) {
    return Column(
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
            child: DropdownButton<String>(
              value: controller.text.isNotEmpty ? controller.text : null,
              isExpanded: true,
              hint: Text('Selecciona...', style: TextStyle(color: Colors.grey[400])),
              items: opciones.map((opcion) {
                return DropdownMenuItem(
                  value: opcion,
                  child: Text(opcion),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => controller.text = value ?? '');
              },
            ),
          ),
        ),
      ],
    );
  }
}