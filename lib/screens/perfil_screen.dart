// ============================================================
// PERFIL SCREEN - Gestión de perfil de usuario
// ============================================================

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  // ============================================================
  // VARIABLES DE ESTADO
  // ============================================================
  bool _isLoading = true;
  bool _enEdicion = false;
  bool _guardando = false;

  // Datos del usuario
  String _nombre = '';
  String _apellido = '';
  String _email = '';
  String _telefono = '';
  String _direccion = '';
  String _emergencia = '';

  // Controladores
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
  // CARGA DE DATOS
  // ============================================================
  Future<void> _cargarUsuario() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final usuarioStr = prefs.getString('petcard_usuario_actual');

      if (usuarioStr != null) {
        final Map<String, dynamic> json = jsonDecode(usuarioStr);
        _nombre = json['Nombre'] ?? json['nombre'] ?? '';
        _apellido = json['Apellido'] ?? json['apellido'] ?? '';
        _email = json['Correo'] ?? json['email'] ?? '';
        _telefono = json['Telefono'] ?? json['telefono'] ?? '';
        _direccion = json['Direccion'] ?? json['direccion'] ?? '';
        _emergencia = json['Emergencia'] ?? json['emergencia'] ?? '';

        _nombreController.text = _nombre;
        _apellidoController.text = _apellido;
        _emailController.text = _email;
        _telefonoController.text = _telefono;
        _direccionController.text = _direccion;
        _emergenciaController.text = _emergencia;
      }
    } catch (e) {
      print('Error cargando usuario: $e');
    }

    setState(() => _isLoading = false);
  }

  // ============================================================
  // GUARDAR CAMBIOS
  // ============================================================
  Future<void> _guardarCambios() async {
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

    setState(() => _guardando = true);

    try {
      final prefs = await SharedPreferences.getInstance();

      // Actualizar datos
      final Map<String, dynamic> usuarioActualizado = {
        'Nombre': _nombreController.text.trim(),
        'Apellido': _apellidoController.text.trim(),
        'Correo': _emailController.text.trim(),
        'Telefono': _telefonoController.text.trim(),
        'Direccion': _direccionController.text.trim(),
        'Emergencia': _emergenciaController.text.trim(),
      };

      // Actualizar en SharedPreferences
      await prefs.setString(
        'petcard_usuario_actual',
        jsonEncode(usuarioActualizado),
      );

      // Actualizar lista de usuarios
      final usuariosStr = prefs.getString('petcard_usuarios') ?? '[]';
      List<dynamic> usuarios = jsonDecode(usuariosStr);

      final index = usuarios.indexWhere(
            (u) =>
        u['documento'] == prefs.getString('petcard_documento') &&
            u['tipoDocumento'] == prefs.getString('petcard_tipo_documento'),
      );

      if (index != -1) {
        usuarios[index] = {...usuarios[index], ...usuarioActualizado};
        await prefs.setString('petcard_usuarios', jsonEncode(usuarios));
      }

      // Actualizar variables locales
      _nombre = usuarioActualizado['Nombre']!;
      _apellido = usuarioActualizado['Apellido']!;
      _email = usuarioActualizado['Correo']!;
      _telefono = usuarioActualizado['Telefono']!;
      _direccion = usuarioActualizado['Direccion']!;
      _emergencia = usuarioActualizado['Emergencia']!;

      setState(() {
        _enEdicion = false;
        _guardando = false;
      });

      _mostrarAlerta('Éxito', '✅ Perfil actualizado correctamente');
    } catch (e) {
      setState(() => _guardando = false);
      _mostrarAlerta('Error', '❌ Error al guardar los cambios');
      print('Error guardando usuario: $e');
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
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: _irANotificaciones,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==========================================================
            // BANNER DE PERFIL
            // ==========================================================
            _buildPerfilBanner(),

            const SizedBox(height: 24),

            // ==========================================================
            // INFORMACIÓN PERSONAL
            // ==========================================================
            _buildInformacionPersonal(),

            const SizedBox(height: 16),

            // ==========================================================
            // ACCIONES RÁPIDAS
            // ==========================================================
            _buildAccionesRapidas(),

            const SizedBox(height: 16),

            // ==========================================================
            // ESTADÍSTICAS
            // ==========================================================
            _buildEstadisticas(),

            const SizedBox(height: 32),

            // ==========================================================
            // FOOTER
            // ==========================================================
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // WIDGETS - BANNER DE PERFIL
  // ============================================================
  Widget _buildPerfilBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$_nombre $_apellido',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Usuario de PetCard',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildBannerBoton(
                  icon: Icons.edit,
                  label: _enEdicion ? 'Guardar' : 'Editar',
                  onPressed: () {
                    if (_enEdicion) {
                      _guardarCambios();
                    } else {
                      setState(() => _enEdicion = true);
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildBannerBoton(
                  icon: Icons.logout,
                  label: 'Cerrar Sesión',
                  onPressed: _cerrarSesion,
                ),
              ),
            ],
          ),
          if (_guardando) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(
              color: Colors.white,
              backgroundColor: Colors.white24,
            ),
            const SizedBox(height: 4),
            const Text(
              'Guardando cambios...',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
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
      label: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Colors.white),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        minimumSize: const Size(0, 36),
      ),
    );
  }

  // ============================================================
  // WIDGETS - INFORMACIÓN PERSONAL
  // ============================================================
  Widget _buildInformacionPersonal() {
    return Container(
      padding: const EdgeInsets.all(20),
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
            children: [
              Icon(Icons.person_outline, size: 18, color: Colors.grey[600]),
              const SizedBox(width: 8),
              const Text(
                'Información Personal',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Gestiona tu información de contacto y datos personales',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 20),

          // Nombre y Apellido
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
          ),
          const SizedBox(height: 16),

          // Email y Teléfono
          Row(
            children: [
              Expanded(
                child: _buildCampo(
                  label: 'Correo Electrónico',
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
          ),
          const SizedBox(height: 16),

          // Dirección
          _buildCampo(
            label: 'Dirección',
            controller: _direccionController,
            enabled: _enEdicion,
          ),
          const SizedBox(height: 16),

          // Contacto de Emergencia
          _buildCampo(
            label: 'Contacto de Emergencia',
            controller: _emergenciaController,
            enabled: _enEdicion,
          ),

          if (_enEdicion) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _guardarCambios,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Guardar Cambios',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ],
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
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          style: TextStyle(color: enabled ? Colors.black87 : Colors.grey[600]),
          decoration: InputDecoration(
            filled: true,
            fillColor: enabled ? Colors.white : const Color(0xFFF5F5F5),
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
          ),
        ),
      ],
    );
  }

  // ============================================================
  // WIDGETS - ACCIONES RÁPIDAS
  // ============================================================
  Widget _buildAccionesRapidas() {
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
            children: [
              Icon(Icons.flash_on, size: 18, color: Colors.grey[600]),
              const SizedBox(width: 8),
              const Text(
                'Acciones Rápidas',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildAccionBoton(
            icon: Icons.pets,
            label: 'Gestionar Mascotas',
            onPressed: _irAMascotas,
          ),
          _buildAccionBoton(
            icon: Icons.calendar_today,
            label: 'Programar Cita',
            onPressed: _irACitas,
          ),
          _buildAccionBoton(
            icon: Icons.medical_services,
            label: 'Ver Carnet de Vacunas',
            onPressed: _irACarnet,
          ),
          _buildAccionBoton(
            icon: Icons.notifications,
            label: 'Configurar Recordatorios',
            onPressed: _irANotificaciones,
          ),
        ],
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
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF7C3AED)),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // WIDGETS - ESTADÍSTICAS
  // ============================================================
  Widget _buildEstadisticas() {
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
            children: [
              Icon(Icons.analytics, size: 18, color: Colors.grey[600]),
              const SizedBox(width: 8),
              const Text(
                'Estadísticas',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildEstadisticaRow('Mascotas registradas', '3'),
          _buildEstadisticaRow('Citas programadas', '2'),
          _buildEstadisticaRow(
            'Vacunas al día',
            '100%',
            valueColor: Colors.green,
          ),
          _buildEstadisticaRow(
            'Recordatorios activos',
            '5',
            valueColor: const Color(0xFF7C3AED),
          ),
        ],
      ),
    );
  }

  Widget _buildEstadisticaRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: valueColor ?? const Color(0xFF1A1A2E),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // WIDGETS - FOOTER
  // ============================================================
  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Text(
            '© 2024 PetCard. Todos los derechos reservados.',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
