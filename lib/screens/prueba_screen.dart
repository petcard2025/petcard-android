// ============================================================
// PRUEBA SCREEN - Vista de prueba
// ============================================================

import 'package:flutter/material.dart';

class PruebaScreen extends StatefulWidget {
  const PruebaScreen({super.key});

  @override
  State<PruebaScreen> createState() => _PruebaScreenState();
}

class _PruebaScreenState extends State<PruebaScreen> {
  // ============================================================
  // VARIABLES DE ESTADO
  // ============================================================
  bool _mostrarPerfil = false;
  bool _mostrarMascotas = false;

  // Controladores Perfil
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidoController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _direccionController = TextEditingController();

  // Controladores Mascota
  final TextEditingController _mascotaNombreController =
      TextEditingController();
  final TextEditingController _mascotaEspecieController =
      TextEditingController();
  final TextEditingController _mascotaRazaController = TextEditingController();
  final TextEditingController _mascotaEdadController = TextEditingController();
  final TextEditingController _mascotaPesoController = TextEditingController();

  List<Map<String, String>> _mascotas = [];

  // ============================================================
  // FUNCIONES
  // ============================================================
  void _limpiarPerfil() {
    _nombreController.clear();
    _apellidoController.clear();
    _emailController.clear();
    _telefonoController.clear();
    _direccionController.clear();
  }

  void _limpiarMascota() {
    _mascotaNombreController.clear();
    _mascotaEspecieController.clear();
    _mascotaRazaController.clear();
    _mascotaEdadController.clear();
    _mascotaPesoController.clear();
  }

  void _guardarPerfil() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Perfil actualizado correctamente'),
        backgroundColor: Color(0xFF2563EB),
        duration: Duration(seconds: 2),
      ),
    );
    _limpiarPerfil();
    setState(() => _mostrarPerfil = false);
  }

  void _guardarMascota() {
    if (_mascotaNombreController.text.trim().isEmpty ||
        _mascotaEspecieController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Nombre y especie son obligatorios'),
          backgroundColor: Color(0xFFF59E0B),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _mascotas.add({
        'nombre': _mascotaNombreController.text.trim(),
        'especie': _mascotaEspecieController.text.trim(),
        'raza': _mascotaRazaController.text.trim(),
        'edad': _mascotaEdadController.text.trim(),
        'peso': _mascotaPesoController.text.trim(),
      });
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Mascota registrada correctamente'),
        backgroundColor: Color(0xFF2563EB),
        duration: Duration(seconds: 2),
      ),
    );

    _limpiarMascota();
    setState(() => _mostrarMascotas = false);
  }

  void _cancelarPerfil() {
    _limpiarPerfil();
    setState(() => _mostrarPerfil = false);
  }

  void _cancelarMascota() {
    _limpiarMascota();
    setState(() => _mostrarMascotas = false);
  }

  void _eliminarMascota(int index) {
    setState(() => _mascotas.removeAt(index));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🗑️ Mascota eliminada'),
        backgroundColor: Color(0xFFEF4444),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();
    _mascotaNombreController.dispose();
    _mascotaEspecieController.dispose();
    _mascotaRazaController.dispose();
    _mascotaEdadController.dispose();
    _mascotaPesoController.dispose();
    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2563EB), // AZUL
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
            onPressed: () {
              setState(() {
                _mostrarPerfil = false;
                _mostrarMascotas = false;
                _limpiarPerfil();
                _limpiarMascota();
                _mascotas.clear();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🔄 Todo reiniciado'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ==========================================================
                  // ENCABEZADO
                  // ==========================================================
                  const Text(
                    'Mi Cuenta',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Gestiona tu perfil y tus mascotas',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),

                  // ==========================================================
                  // BOTONES DE ACCIÓN
                  // ==========================================================
                  if (!_mostrarPerfil && !_mostrarMascotas) ...[
                    _buildBotonAccion(
                      icon: Icons.person,
                      label: 'Editar Perfil',
                      description: 'Actualiza tu información personal',
                      color: const Color(0xFF2563EB),
                      onPressed: () {
                        setState(() {
                          _mostrarPerfil = true;
                          _mostrarMascotas = false;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildBotonAccion(
                      icon: Icons.pets,
                      label: 'Mis Mascotas',
                      description: 'Gestiona tus mascotas registradas',
                      color: const Color(0xFF2563EB),
                      onPressed: () {
                        setState(() {
                          _mostrarMascotas = true;
                          _mostrarPerfil = false;
                        });
                      },
                    ),
                  ],

                  // ==========================================================
                  // FORMULARIO DE PERFIL
                  // ==========================================================
                  if (_mostrarPerfil) ...[
                    const SizedBox(height: 16),
                    _buildFormularioPerfil(),
                  ],

                  // ==========================================================
                  // FORMULARIO DE MASCOTAS
                  // ==========================================================
                  if (_mostrarMascotas) ...[
                    const SizedBox(height: 16),
                    _buildFormularioMascota(),
                  ],

                  // ==========================================================
                  // LISTA DE MASCOTAS
                  // ==========================================================
                  if (_mascotas.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Mis Mascotas',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._mascotas.asMap().entries.map((entry) {
                      final index = entry.key;
                      final mascota = entry.value;
                      return _buildMascotaCard(mascota, index);
                    }),
                  ],

                  // ==========================================================
                  // FOOTER
                  // ==========================================================
                  const SizedBox(height: 32),
                  Center(
                    child: Text(
                      'PetCard © 2026',
                      style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // WIDGETS
  // ============================================================

  Widget _buildBotonAccion({
    required IconData icon,
    required String label,
    required String description,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2), width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1A1A2E),
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildFormularioPerfil() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
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
                  Icon(Icons.person, size: 20, color: const Color(0xFF2563EB)),
                  const SizedBox(width: 8),
                  const Text(
                    'Editar Perfil',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: _cancelarPerfil,
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: Color(0xFFEF4444)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Actualiza tu información personal',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),

          LayoutBuilder(
            builder: (context, constraints) {
              final isSmall = constraints.maxWidth < 500;
              return Column(
                children: [
                  if (isSmall) ...[
                    _buildCampo('Nombre', _nombreController),
                    const SizedBox(height: 12),
                    _buildCampo('Apellido', _apellidoController),
                    const SizedBox(height: 12),
                    _buildCampo(
                      'Correo Electrónico',
                      _emailController,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    _buildCampo(
                      'Teléfono',
                      _telefonoController,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    _buildCampo('Dirección', _direccionController),
                  ] else ...[
                    Row(
                      children: [
                        Expanded(
                          child: _buildCampo('Nombre', _nombreController),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildCampo('Apellido', _apellidoController),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildCampo(
                            'Correo Electrónico',
                            _emailController,
                            keyboardType: TextInputType.emailAddress,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildCampo(
                            'Teléfono',
                            _telefonoController,
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildCampo('Dirección', _direccionController),
                  ],
                ],
              );
            },
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _guardarPerfil,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
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
      ),
    );
  }

  Widget _buildFormularioMascota() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
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
                  Icon(Icons.pets, size: 20, color: const Color(0xFF2563EB)),
                  const SizedBox(width: 8),
                  const Text(
                    'Registrar Mascota',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: _cancelarMascota,
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: Color(0xFFEF4444)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Ingresa los datos de tu nueva mascota',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),

          LayoutBuilder(
            builder: (context, constraints) {
              final isSmall = constraints.maxWidth < 500;
              return Column(
                children: [
                  if (isSmall) ...[
                    _buildCampo(
                      'Nombre de la mascota',
                      _mascotaNombreController,
                    ),
                    const SizedBox(height: 12),
                    _buildCampo('Especie', _mascotaEspecieController),
                    const SizedBox(height: 12),
                    _buildCampo('Raza', _mascotaRazaController),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildCampo('Edad', _mascotaEdadController),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildCampo(
                            'Peso (kg)',
                            _mascotaPesoController,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Expanded(
                          child: _buildCampo(
                            'Nombre de la mascota',
                            _mascotaNombreController,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildCampo(
                            'Especie',
                            _mascotaEspecieController,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildCampo('Raza', _mascotaRazaController),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildCampo('Edad', _mascotaEdadController),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildCampo(
                      'Peso (kg)',
                      _mascotaPesoController,
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ],
              );
            },
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _guardarMascota,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Guardar Mascota',
                style: TextStyle(
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

  Widget _buildCampo(
    String label,
    TextEditingController controller, {
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
              borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            isDense: true,
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
      ],
    );
  }

  Widget _buildMascotaCard(Map<String, String> mascota, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.pets, color: Color(0xFF2563EB), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mascota['nombre'] ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                Text(
                  '${mascota['especie'] ?? ''} • ${mascota['raza'] ?? ''} • ${mascota['edad'] ?? ''} • ${mascota['peso'] ?? ''} kg',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, size: 18, color: Colors.red[300]),
            onPressed: () => _eliminarMascota(index),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
