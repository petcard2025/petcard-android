// PANTALLA DE PERFIL DE USUARIO
// Reemplaza la vista de Vue.js con estilos similares

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// ============================================================
// MODELO DE USUARIO
// ============================================================
class Usuario {
  final String documento;
  final String tipoDocumento;
  final String nombre;
  final String apellido;
  final String email;
  final String telefono;
  final String direccion;
  final String emergencia;
  final String rol;

  Usuario({
    required this.documento,
    required this.tipoDocumento,
    required this.nombre,
    required this.apellido,
    required this.email,
    required this.telefono,
    required this.direccion,
    required this.emergencia,
    required this.rol,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      documento: json['documento'] ?? '',
      tipoDocumento: json['tipoDocumento'] ?? '',
      nombre: json['Nombre'] ?? json['nombre'] ?? '',
      apellido: json['Apellido'] ?? json['apellido'] ?? '',
      email: json['Correo'] ?? json['email'] ?? '',
      telefono: json['Telefono'] ?? json['telefono'] ?? '',
      direccion: json['Direccion'] ?? json['direccion'] ?? '',
      emergencia: json['Emergencia'] ?? json['emergencia'] ?? '',
      rol: json['Rol'] ?? json['rol'] ?? 'cliente',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'documento': documento,
      'tipoDocumento': tipoDocumento,
      'Nombre': nombre,
      'Apellido': apellido,
      'Correo': email,
      'Telefono': telefono,
      'Direccion': direccion,
      'Emergencia': emergencia,
      'Rol': rol,
    };
  }
}

// ============================================================
// PANTALLA PRINCIPAL
// ============================================================
class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  // VARIABLES DE ESTADO
  Usuario? _usuarioActual;
  bool _enEdicion = false;
  bool _isLoading = true;

  // CONTROLADORES DE FORMULARIO
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidoController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _direccionController = TextEditingController();
  final TextEditingController _emergenciaController = TextEditingController();

  // ============================================================
  // CICLO DE VIDA
  // ============================================================
  @override
  void initState() {
    super.initState();
    _cargarUsuario();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();
    _emergenciaController.dispose();
    super.dispose();
  }

  // ============================================================
  // FUNCIONES DE CARGA Y GUARDADO
  // ============================================================
  Future<void> _cargarUsuario() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final usuarioStr = prefs.getString('petcard_usuario_actual');

      if (usuarioStr != null) {
        final Map<String, dynamic> json = jsonDecode(usuarioStr);
        _usuarioActual = Usuario.fromJson(json);
        _actualizarCampos();
      }
    } catch (e) {
      print('Error cargando usuario: $e');
    }

    setState(() => _isLoading = false);
  }

  void _actualizarCampos() {
    if (_usuarioActual == null) return;

    _nombreController.text = _usuarioActual!.nombre;
    _apellidoController.text = _usuarioActual!.apellido;
    _emailController.text = _usuarioActual!.email;
    _telefonoController.text = _usuarioActual!.telefono;
    _direccionController.text = _usuarioActual!.direccion;
    _emergenciaController.text = _usuarioActual!.emergencia;
  }

  void _toggleEdicion() {
    if (_enEdicion) {
      _guardarCambios();
    }
    setState(() {
      _enEdicion = !_enEdicion;
    });
  }

  Future<void> _guardarCambios() async {
    if (_usuarioActual == null) return;

    // Validaciones
    if (_nombreController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty) {
      _mostrarAlerta('Error', '⚠️ Nombre y email son obligatorios');
      return;
    }

    if (!_isValidEmail(_emailController.text.trim())) {
      _mostrarAlerta('Error', '⚠️ Email no válido');
      return;
    }

    // Actualizar usuario
    _usuarioActual = Usuario(
      documento: _usuarioActual!.documento,
      tipoDocumento: _usuarioActual!.tipoDocumento,
      nombre: _nombreController.text.trim(),
      apellido: _apellidoController.text.trim(),
      email: _emailController.text.trim(),
      telefono: _telefonoController.text.trim(),
      direccion: _direccionController.text.trim(),
      emergencia: _emergenciaController.text.trim(),
      rol: _usuarioActual!.rol,
    );

    // Guardar en SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final usuariosStr = prefs.getString('petcard_usuarios') ?? '[]';
      List<dynamic> usuarios = jsonDecode(usuariosStr);

      final index = usuarios.indexWhere(
        (u) =>
            u['documento'] == _usuarioActual!.documento &&
            u['tipoDocumento'] == _usuarioActual!.tipoDocumento,
      );

      if (index != -1) {
        usuarios[index] = _usuarioActual!.toJson();
        prefs.setString('petcard_usuarios', jsonEncode(usuarios));
      }

      prefs.setString(
        'petcard_usuario_actual',
        jsonEncode(_usuarioActual!.toJson()),
      );

      setState(() => _enEdicion = false);
      _mostrarAlerta('Éxito', '✅ Perfil actualizado correctamente');
    } catch (e) {
      print('Error guardando usuario: $e');
      _mostrarAlerta('Error', '❌ Error al guardar los cambios');
    }
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return emailRegex.hasMatch(email);
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

  // ============================================================
  // NAVEGACIÓN
  // ============================================================
  void _irAMascotas() {
    Navigator.pushNamed(context, '/mis-mascotas');
  }

  void _irACitas() {
    Navigator.pushNamed(context, '/citas');
  }

  void _irACarnet() {
    Navigator.pushNamed(context, '/carnet');
  }

  void _irANotificaciones() {
    Navigator.pushNamed(context, '/notificaciones');
  }

  void _cerrarSesion() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('petcard_token');
              await prefs.remove('petcard_usuario_actual');
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            },
            child: const Text(
              'Cerrar sesión',
              style: TextStyle(color: Colors.red),
            ),
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
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 920;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPerfilBanner(),
                  const SizedBox(height: 20),
                  if (isWide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 2, child: _buildFormulario()),
                        const SizedBox(width: 20),
                        Expanded(
                          flex: 1,
                          child: Column(
                            children: [
                              _buildAccionesRapidas(),
                              const SizedBox(height: 16),
                              _buildEstadoSesion(),
                              const SizedBox(height: 16),
                              _buildEstadisticas(),
                            ],
                          ),
                        ),
                      ],
                    )
                  else
                    Column(
                      children: [
                        _buildFormulario(),
                        const SizedBox(height: 16),
                        _buildAccionesRapidas(),
                        const SizedBox(height: 16),
                        _buildEstadoSesion(),
                        const SizedBox(height: 16),
                        _buildEstadisticas(),
                      ],
                    ),
                  const SizedBox(height: 24),
                  _buildFooter(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // WIDGETS
  // ============================================================

  Widget _buildPerfilBanner() {
    final nombre = _usuarioActual != null
        ? '${_usuarioActual!.nombre} ${_usuarioActual!.apellido}'
        : 'Cargando...';
    final rol = _usuarioActual != null
        ? _usuarioActual!.rol
        : 'Por favor inicia sesión';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.28),
                    width: 2,
                  ),
                ),
                child: const Icon(Icons.pets, color: Colors.white, size: 34),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombre,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      rol.toUpperCase(),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _usuarioActual != null
                          ? 'Tu información está segura y lista para gestionar tus servicios.'
                          : 'Completa tu sesión para empezar a disfrutar PetCard.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildPill(Icons.verified_user, 'Perfil activo'),
              _buildPill(Icons.shield_outlined, 'Datos protegidos'),
              _buildPill(Icons.schedule, 'Actualizado hoy'),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (_usuarioActual != null) ...[
                _buildBannerBoton(
                  icon: Icons.edit_outlined,
                  label: _enEdicion ? 'Guardar' : 'Editar',
                  onPressed: _toggleEdicion,
                ),
                _buildBannerBoton(
                  icon: Icons.logout_outlined,
                  label: 'Cerrar sesión',
                  onPressed: _cerrarSesion,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerBoton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16, color: Colors.white),
      label: Text(label, style: const TextStyle(color: Colors.white)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: Colors.white.withValues(alpha: 0.7)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
    );
  }

  Widget _buildFormulario() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEE7FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    size: 18,
                    color: Color(0xFF7C3AED),
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Información personal',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Actualiza tus datos de contacto y mantenimiento para una experiencia más completa.',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final useTwoColumns = constraints.maxWidth >= 640;

                return Column(
                  children: [
                    if (useTwoColumns)
                      Row(
                        children: [
                          Expanded(
                            child: _buildCampo(
                              label: 'Nombre',
                              controller: _nombreController,
                              enabled: _enEdicion,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildCampo(
                              label: 'Apellido',
                              controller: _apellidoController,
                              enabled: _enEdicion,
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          _buildCampo(
                            label: 'Nombre',
                            controller: _nombreController,
                            enabled: _enEdicion,
                          ),
                          const SizedBox(height: 16),
                          _buildCampo(
                            label: 'Apellido',
                            controller: _apellidoController,
                            enabled: _enEdicion,
                          ),
                        ],
                      ),
                    const SizedBox(height: 16),
                    if (useTwoColumns)
                      Row(
                        children: [
                          Expanded(
                            child: _buildCampo(
                              label: 'Correo electrónico',
                              controller: _emailController,
                              enabled: _enEdicion,
                              keyboardType: TextInputType.emailAddress,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildCampo(
                              label: 'Teléfono',
                              controller: _telefonoController,
                              enabled: _enEdicion,
                              keyboardType: TextInputType.phone,
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          _buildCampo(
                            label: 'Correo electrónico',
                            controller: _emailController,
                            enabled: _enEdicion,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 16),
                          _buildCampo(
                            label: 'Teléfono',
                            controller: _telefonoController,
                            enabled: _enEdicion,
                            keyboardType: TextInputType.phone,
                          ),
                        ],
                      ),
                    const SizedBox(height: 16),
                    _buildCampo(
                      label: 'Dirección',
                      controller: _direccionController,
                      enabled: _enEdicion,
                    ),
                    const SizedBox(height: 16),
                    _buildCampo(
                      label: 'Contacto de emergencia',
                      controller: _emergenciaController,
                      enabled: _enEdicion,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCampo({
    required String label,
    required TextEditingController controller,
    required bool enabled,
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
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            filled: true,
            fillColor: enabled ? Colors.white : const Color(0xFFF4F6F8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            isDense: true,
          ),
          style: TextStyle(color: enabled ? Colors.black87 : Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildAccionesRapidas() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3ECFF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.flash_on,
                    size: 18,
                    color: Color(0xFF7C3AED),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Acciones rápidas',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildAccionBoton(
              icon: Icons.pets,
              label: 'Gestionar mascotas',
              onPressed: _irAMascotas,
            ),
            _buildAccionBoton(
              icon: Icons.calendar_today,
              label: 'Programar cita',
              onPressed: _irACitas,
            ),
            _buildAccionBoton(
              icon: Icons.medical_services,
              label: 'Carnet de vacunas',
              onPressed: _irACarnet,
            ),
            _buildAccionBoton(
              icon: Icons.notifications,
              label: 'Recordatorios',
              onPressed: _irANotificaciones,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccionBoton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
          color: const Color(0xFFFCFCFD),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF7C3AED)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildEstadoSesion() {
    final prefs = FutureBuilder(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        final token = snapshot.data?.getString('petcard_token') ?? '';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F0FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.security,
                    size: 18,
                    color: Color(0xFF7C3AED),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Estado de la sesión',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: token.isNotEmpty
                          ? Colors.green[100]
                          : Colors.orange[100],
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      token.isNotEmpty ? 'Activa' : 'Pendiente',
                      style: TextStyle(
                        color: token.isNotEmpty
                            ? Colors.green[800]
                            : Colors.orange[800],
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buildEstadoRow('JWT activo', token.isNotEmpty ? 'Sí' : 'No'),
            if (token.isNotEmpty)
              _buildEstadoRow(
                'Token (inicio)',
                token.length > 18 ? '${token.substring(0, 18)}...' : token,
              ),
          ],
        );
      },
    );

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(padding: const EdgeInsets.all(16), child: prefs),
    );
  }

  Widget _buildEstadoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? const Color(0xFF1A1A2E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstadisticas() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F7EE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.analytics,
                    size: 18,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Resumen',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildEstadoRow('Mascotas registradas', '3'),
            _buildEstadoRow('Citas programadas', '2'),
            _buildEstadoRow('Vacunas al día', '100%', valueColor: Colors.green),
            _buildEstadoRow(
              'Recordatorios activos',
              '5',
              valueColor: const Color(0xFF7C3AED),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 760;

          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFooterBrand(),
                const SizedBox(height: 16),
                _buildFooterColumna(
                  titulo: 'Servicios',
                  items: ['Consulta generales', 'Vacunación', 'Cirugías'],
                ),
                const SizedBox(height: 12),
                _buildFooterColumna(
                  titulo: 'Contacto',
                  items: [
                    '+1 234 567 8901',
                    'info@petcard.com',
                    'Calle Principal 123, Ciudad',
                  ],
                ),
                const SizedBox(height: 12),
                _buildFooterColumna(
                  titulo: 'Horarios',
                  items: [
                    'Lunes - Viernes: 8:00 AM - 7:00 PM',
                    'Sábados: 9:00 AM - 6:00 PM',
                    'Domingos: 10:00 AM - 4:00 PM',
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.white24, height: 32),
                const Center(
                  child: Text(
                    '© 2026 PetCard. Todos los derechos reservados.',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ),
              ],
            );
          }

          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: _buildFooterBrand()),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildFooterColumna(
                      titulo: 'Servicios',
                      items: ['Consulta generales', 'Vacunación', 'Cirugías'],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildFooterColumna(
                      titulo: 'Contacto',
                      items: [
                        '+1 234 567 8901',
                        'info@petcard.com',
                        'Calle Principal 123, Ciudad',
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildFooterColumna(
                      titulo: 'Horarios',
                      items: [
                        'Lunes - Viernes: 8:00 AM - 7:00 PM',
                        'Sábados: 9:00 AM - 6:00 PM',
                        'Domingos: 10:00 AM - 4:00 PM',
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(color: Colors.white24, height: 32),
              const Center(
                child: Text(
                  '© 2026 PetCard. Todos los derechos reservados.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFooterBrand() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.pets, color: Colors.white, size: 22),
            const SizedBox(width: 8),
            const Text(
              'PetCard',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Comprometidos con brindar toda la atención profesional que tu mascota necesita.',
          style: TextStyle(color: Colors.grey[400], fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildFooterColumna({
    required String titulo,
    required List<String> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              item,
              style: TextStyle(color: Colors.grey[400], fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }
}
