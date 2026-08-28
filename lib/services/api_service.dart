import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  // Cambia esto según tu configuración
  static const String baseUrl = 'https://127.0.0.1:3001/api';

  final _storage = const FlutterSecureStorage();
  static const _tokenKey = 'jwt_token';
  static const _usuarioKey = 'usuario_actual';

  // Cliente HTTP que acepta certificado autofirmado
  static http.Client _clienteHttp() {
    final httpClient = HttpClient()
      ..badCertificateCallback = (cert, host, port) {
        return host == '127.0.0.1';
      };
    return IOClient(httpClient);
  }

  final http.Client _client = _clienteHttp();

  // ============================================================
  // USUARIO ACTUAL (decodificado del propio JWT)
  // ============================================================
  // AuthService no es un singleton, así que en pantallas distintas a
  // login se pierde el usuario en memoria. En cambio, el token JWT ya
  // trae ID_usuario, Nombre, Correo y Rol firmados por el backend, así
  // que los leemos directamente de ahí sin otra llamada al servidor.
  Future<Map<String, dynamic>?> obtenerMiUsuario() async {
    final token = await obtenerToken();
    if (token == null) return null;
    final partes = token.split('.');
    if (partes.length != 3) return null;
    try {
      String payload = partes[1];
      payload = payload.replaceAll('-', '+').replaceAll('_', '/');
      switch (payload.length % 4) {
        case 2:
          payload += '==';
          break;
        case 3:
          payload += '=';
          break;
      }
      final decoded = utf8.decode(base64.decode(payload));
      final map = jsonDecode(decoded);
      if (map is Map<String, dynamic>) return map;
      return null;
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // TOKEN
  // ============================================================
  Future<void> _guardarToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> obtenerToken() async {
    return _storage.read(key: _tokenKey);
  }

  Future<void> borrarToken() async {
    await _storage.delete(key: _tokenKey);
  }

  /// Guarda localmente los datos del usuario que devolvió el login
  /// (Nombre, Correo, Telefono, Rol) para poder mostrarlos luego en
  /// "Mi Perfil" sin depender de que AuthService siga vivo en memoria.
  Future<void> _guardarUsuarioLocal(Map<String, dynamic> usuario) async {
    await _storage.write(key: _usuarioKey, value: jsonEncode(usuario));
  }

  /// Datos del usuario guardados en el último login (Nombre, Correo,
  /// Telefono, Rol). Devuelve null si nunca se guardaron (p.ej. la
  /// sesión sigue activa de antes de este cambio) o si no hay sesión.
  Future<Map<String, dynamic>?> obtenerUsuarioGuardado() async {
    final raw = await _storage.read(key: _usuarioKey);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return null;
  }

  Future<Map<String, String>> _headersConToken() async {
    final token = await obtenerToken();
    if (token == null) {
      throw Exception('No hay sesión activa.');
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ============================================================
  // AUTH
  // ============================================================
  Future<Map<String, dynamic>> login({
    required String correo,
    required String contrasena,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'Correo': correo,
        'Contrasena': contrasena,
      }),
    );

    final data = _parseBody(response);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final token = data['token'] as String?;
      if (token == null) {
        throw Exception('El servidor no devolvió un token.');
      }
      await _guardarToken(token);
      final usuarioData = data['usuario'];
      if (usuarioData is Map<String, dynamic>) {
        await _guardarUsuarioLocal(usuarioData);
      }
      return data;
    }

    throw Exception(data['error'] ?? 'Error al iniciar sesión.');
  }

  Future<Map<String, dynamic>> registrarUsuario({
    required String nombre,
    required String correo,
    required String contrasena,
    String? telefono,
    String rol = 'cliente',
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/usuarios'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'Nombre': nombre,
        'Correo': correo,
        'Contrasena': contrasena,
        'Telefono': telefono,
        'Rol': rol,
      }),
    );

    final data = _parseBody(response);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }

    throw Exception(data['error'] ?? 'Error al registrarse.');
  }

  Future<void> logout() async {
    await borrarToken();
    await _storage.delete(key: _usuarioKey);
  }
// ============================================================
// RECUPERAR CONTRASEÑA
// ============================================================
  Future<void> solicitarRecuperacion(String correo) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/auth/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'Correo': correo}),
    );

    final data = _parseBody(response);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    throw Exception(data['error'] ?? 'No se pudo procesar la solicitud.');
  }
  // ============================================================
  // USUARIOS
  // ============================================================
  Future<List<Map<String, dynamic>>> obtenerUsuarios() async {
    final headers = await _headersConToken();
    final response = await _client.get(
      Uri.parse('$baseUrl/usuarios'),
      headers: headers,
    );
    return _parseLista(response, 'No se pudieron obtener los usuarios.');
  }

  Future<void> actualizarUsuario(dynamic id, Map<String, dynamic> datos) async {
    final headers = await _headersConToken();
    final response = await _client.put(
      Uri.parse('$baseUrl/usuarios/$id'),
      headers: headers,
      body: jsonEncode(datos),
    );
    _verificarOk(response, 'No se pudo actualizar el usuario.');
  }

  Future<void> eliminarUsuario(dynamic id) async {
    final headers = await _headersConToken();
    final response = await _client.delete(
      Uri.parse('$baseUrl/usuarios/$id'),
      headers: headers,
    );
    _verificarOk(response, 'No se pudo eliminar el usuario.');
  }

  // ============================================================
  // CLIENTES
  // ============================================================
  Future<List<Map<String, dynamic>>> obtenerClientes() async {
    final headers = await _headersConToken();
    final response = await _client.get(
      Uri.parse('$baseUrl/clientes'),
      headers: headers,
    );
    return _parseLista(response, 'No se pudieron obtener los clientes.');
  }

  /// Devuelve el registro de "cliente" (ID_cliente, Direccion, ID_usuario)
  /// asociado a un usuario, o null si el usuario no tiene cliente.
  Future<Map<String, dynamic>?> obtenerClientePorUsuario(dynamic idUsuario) async {
    final headers = await _headersConToken();
    final response = await _client.get(
      Uri.parse('$baseUrl/clientes/usuario/$idUsuario'),
      headers: headers,
    );
    final lista = _parseLista(response, 'No se pudo obtener el cliente.');
    return lista.isEmpty ? null : lista.first;
  }

  // ============================================================
  // MASCOTAS
  // ============================================================
  Future<List<Map<String, dynamic>>> obtenerMascotasAdmin() async {
    final headers = await _headersConToken();
    final response = await _client.get(
      Uri.parse('$baseUrl/mascotas'),
      headers: headers,
    );
    return _parseLista(response, 'No se pudieron obtener las mascotas.');
  }

  /// Mascotas de un cliente en particular (para dropdowns del cliente,
  /// no el listado completo de administrador).
  Future<List<Map<String, dynamic>>> obtenerMascotasPorCliente(dynamic idCliente) async {
    final headers = await _headersConToken();
    final response = await _client.get(
      Uri.parse('$baseUrl/mascotas/cliente/$idCliente'),
      headers: headers,
    );
    return _parseLista(response, 'No se pudieron obtener tus mascotas.');
  }

  Future<Map<String, dynamic>> crearMascota(Map<String, dynamic> datos) async {
    final headers = await _headersConToken();
    final response = await _client.post(
      Uri.parse('$baseUrl/mascotas'),
      headers: headers,
      body: jsonEncode(datos),
    );
    return _parseBodyOk(response, 'No se pudo crear la mascota.');
  }

  Future<void> actualizarMascota(dynamic id, Map<String, dynamic> datos) async {
    final headers = await _headersConToken();
    final response = await _client.put(
      Uri.parse('$baseUrl/mascotas/$id'),
      headers: headers,
      body: jsonEncode(datos),
    );
    _verificarOk(response, 'No se pudo actualizar la mascota.');
  }

  Future<void> eliminarMascota(dynamic id) async {
    final headers = await _headersConToken();
    final response = await _client.delete(
      Uri.parse('$baseUrl/mascotas/$id'),
      headers: headers,
    );
    _verificarOk(response, 'No se pudo eliminar la mascota.');
  }

  // ============================================================
  // MASCOTAS (SESIÓN ACTUAL) - "Mis mascotas" del cliente logueado
  // ============================================================

  /// ID_cliente del usuario que inició sesión. Si aún no tiene un
  /// registro de cliente (p. ej. se registró pero nunca agregó una
  /// mascota), lo crea automáticamente.
  Future<dynamic> obtenerIdClienteActual() async {
    final usuario = await obtenerMiUsuario();
    final idUsuario = usuario?['ID_usuario'];
    if (idUsuario == null) {
      throw Exception('No se pudo identificar al usuario de la sesión.');
    }

    final cliente = await obtenerClientePorUsuario(idUsuario);
    if (cliente != null) {
      return cliente['ID_cliente'];
    }

    // No existe todavía: se crea el registro de cliente para este usuario.
    final headers = await _headersConToken();
    final response = await _client.post(
      Uri.parse('$baseUrl/clientes'),
      headers: headers,
      body: jsonEncode({'Direccion': '', 'ID_usuario': idUsuario}),
    );
    final datosCliente = _parseBodyOk(
      response,
      'No se pudo registrar el perfil de cliente.',
    );
    return datosCliente['ID_cliente'];
  }

  /// Mascotas del usuario logueado.
  Future<List<Map<String, dynamic>>> obtenerMisMascotas() async {
    final idCliente = await obtenerIdClienteActual();
    return obtenerMascotasPorCliente(idCliente);
  }

  /// Crea una mascota y la asocia automáticamente al cliente logueado.
  Future<Map<String, dynamic>> crearMiMascota(Map<String, dynamic> datos) async {
    final idCliente = await obtenerIdClienteActual();
    final payload = {...datos, 'ID_cliente': idCliente};
    return crearMascota(payload);
  }
  // ============================================================
  // SERVICIOS
  // ============================================================
  Future<List<Map<String, dynamic>>> obtenerServicios() async {
    final headers = await _headersConToken();
    final response = await _client.get(
      Uri.parse('$baseUrl/servicios'),
      headers: headers,
    );
    return _parseLista(response, 'No se pudieron obtener los servicios.');
  }

  Future<void> crearServicio(Map<String, dynamic> datos) async {
    final headers = await _headersConToken();
    final response = await _client.post(
      Uri.parse('$baseUrl/servicios'),
      headers: headers,
      body: jsonEncode(datos),
    );
    _verificarOk(response, 'No se pudo crear el servicio.');
  }

  Future<void> actualizarServicio(dynamic id, Map<String, dynamic> datos) async {
    final headers = await _headersConToken();
    final response = await _client.put(
      Uri.parse('$baseUrl/servicios/$id'),
      headers: headers,
      body: jsonEncode(datos),
    );
    _verificarOk(response, 'No se pudo actualizar el servicio.');
  }

  Future<void> eliminarServicio(dynamic id) async {
    final headers = await _headersConToken();
    final response = await _client.delete(
      Uri.parse('$baseUrl/servicios/$id'),
      headers: headers,
    );
    _verificarOk(response, 'No se pudo eliminar el servicio.');
  }

  // ============================================================
  // PLANES DE ALIMENTACIÓN
  // ============================================================
  Future<List<Map<String, dynamic>>> obtenerPlanesAlimentacion() async {
    final headers = await _headersConToken();
    final response = await _client.get(
      Uri.parse('$baseUrl/alimentacion'),
      headers: headers,
    );
    return _parseLista(response, 'No se pudieron obtener los planes.');
  }

  Future<void> crearPlanAlimentacion(Map<String, dynamic> datos) async {
    final headers = await _headersConToken();
    final response = await _client.post(
      Uri.parse('$baseUrl/alimentacion'),
      headers: headers,
      body: jsonEncode(datos),
    );
    _verificarOk(response, 'No se pudo crear el plan.');
  }

  Future<void> actualizarPlanAlimentacion(dynamic id, Map<String, dynamic> datos) async {
    final headers = await _headersConToken();
    final response = await _client.put(
      Uri.parse('$baseUrl/alimentacion/$id'),
      headers: headers,
      body: jsonEncode(datos),
    );
    _verificarOk(response, 'No se pudo actualizar el plan.');
  }

  Future<void> eliminarPlanAlimentacion(dynamic id) async {
    final headers = await _headersConToken();
    final response = await _client.delete(
      Uri.parse('$baseUrl/alimentacion/$id'),
      headers: headers,
    );
    _verificarOk(response, 'No se pudo eliminar el plan.');
  }

  // ============================================================
  // NOTIFICACIONES
  // ============================================================
  Future<List<Map<String, dynamic>>> obtenerNotificaciones() async {
    final headers = await _headersConToken();
    final response = await _client.get(
      Uri.parse('$baseUrl/notificaciones'),
      headers: headers,
    );
    return _parseLista(response, 'No se pudieron obtener las notificaciones.');
  }

  Future<void> crearNotificacion(Map<String, dynamic> datos) async {
    final headers = await _headersConToken();
    final response = await _client.post(
      Uri.parse('$baseUrl/notificaciones'),
      headers: headers,
      body: jsonEncode(datos),
    );
    _verificarOk(response, 'No se pudo enviar la notificación.');
  }

  Future<void> marcarNotificacionLeida(dynamic id) async {
    final headers = await _headersConToken();
    final response = await _client.patch(
      Uri.parse('$baseUrl/notificaciones/$id/marcar-como-leida'),
      headers: headers,
    );
    _verificarOk(response, 'No se pudo marcar como leída.');
  }

  /// Notificaciones de un usuario en particular (para "Mis notificaciones").
  Future<List<Map<String, dynamic>>> obtenerNotificacionesPorUsuario(dynamic idUsuario) async {
    final headers = await _headersConToken();
    final response = await _client.get(
      Uri.parse('$baseUrl/notificaciones/usuario/$idUsuario'),
      headers: headers,
    );
    return _parseLista(response, 'No se pudieron obtener tus notificaciones.');
  }

  /// Notificaciones del usuario logueado, resolviendo el ID a partir del JWT.
  Future<List<Map<String, dynamic>>> obtenerMisNotificaciones() async {
    final usuario = await obtenerMiUsuario();
    final idUsuario = usuario?['ID_usuario'];
    if (idUsuario == null) {
      throw Exception('No se pudo identificar al usuario de la sesión.');
    }
    return obtenerNotificacionesPorUsuario(idUsuario);
  }

  /// Marca varias notificaciones como leídas de una sola vez.
  Future<void> marcarMultiplesNotificacionesLeidas(List<dynamic> ids) async {
    final headers = await _headersConToken();
    final response = await _client.patch(
      Uri.parse('$baseUrl/notificaciones/marcar-como-leidas/bulk'),
      headers: headers,
      body: jsonEncode({'ids': ids}),
    );
    _verificarOk(response, 'No se pudieron marcar las notificaciones como leídas.');
  }

  Future<void> eliminarNotificacion(dynamic id) async {
    final headers = await _headersConToken();
    final response = await _client.delete(
      Uri.parse('$baseUrl/notificaciones/$id'),
      headers: headers,
    );
    _verificarOk(response, 'No se pudo eliminar la notificación.');
  }

  // ============================================================
  // CITAS
  // ============================================================
  Future<List<Map<String, dynamic>>> obtenerCitasAdmin() async {
    final headers = await _headersConToken();
    final response = await _client.get(
      Uri.parse('$baseUrl/citas'),
      headers: headers,
    );
    return _parseLista(response, 'No se pudieron obtener las citas.');
  }

  Future<Map<String, dynamic>> crearCita(Map<String, dynamic> datos) async {
    final headers = await _headersConToken();
    final response = await _client.post(
      Uri.parse('$baseUrl/citas'),
      headers: headers,
      body: jsonEncode(datos),
    );
    return _parseBodyOk(response, 'No se pudo crear la cita.');
  }

  Future<void> actualizarCita(dynamic id, Map<String, dynamic> datos) async {
    final headers = await _headersConToken();
    final response = await _client.put(
      Uri.parse('$baseUrl/citas/$id'),
      headers: headers,
      body: jsonEncode(datos),
    );
    _verificarOk(response, 'No se pudo actualizar la cita.');
  }

  /// Tu backend solo permite cambiar el "Estado" de una cita vía PATCH
  /// (el PUT no acepta ese campo), por eso este método es aparte.
  Future<void> cambiarEstadoCita(dynamic id, String estado) async {
    final headers = await _headersConToken();
    final response = await _client.patch(
      Uri.parse('$baseUrl/citas/$id'),
      headers: headers,
      body: jsonEncode({'Estado': estado}),
    );
    _verificarOk(response, 'No se pudo cambiar el estado de la cita.');
  }

  /// Horas ya ocupadas de un veterinario en una fecha (evita doble cita).
  Future<List<String>> obtenerHorasOcupadas({
    required dynamic idVeterinario,
    required String fecha,
  }) async {
    final headers = await _headersConToken();
    final response = await _client.get(
      Uri.parse('$baseUrl/citas/horas-ocupadas?ID_veterinario=$idVeterinario&Fecha=$fecha'),
      headers: headers,
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body);
      final horas = decoded['horasOcupadas'];
      if (horas is List) return horas.map((e) => e.toString()).toList();
    }
    return [];
  }

  Future<void> eliminarCita(dynamic id) async {
    final headers = await _headersConToken();
    final response = await _client.delete(
      Uri.parse('$baseUrl/citas/$id'),
      headers: headers,
    );
    _verificarOk(response, 'No se pudo eliminar la cita.');
  }

  // ============================================================
  // VACUNAS
  // ============================================================
  Future<List<Map<String, dynamic>>> obtenerVacunas() async {
    final headers = await _headersConToken();
    final response = await _client.get(
      Uri.parse('$baseUrl/vacunas'),
      headers: headers,
    );
    return _parseLista(response, 'No se pudieron obtener las vacunas.');
  }

  Future<Map<String, dynamic>> crearVacuna(Map<String, dynamic> datos) async {
    final headers = await _headersConToken();
    final response = await _client.post(
      Uri.parse('$baseUrl/vacunas'),
      headers: headers,
      body: jsonEncode(datos),
    );
    return _parseBodyOk(response, 'No se pudo crear la vacuna.');
  }

  Future<void> actualizarVacuna(dynamic id, Map<String, dynamic> datos) async {
    final headers = await _headersConToken();
    final response = await _client.put(
      Uri.parse('$baseUrl/vacunas/$id'),
      headers: headers,
      body: jsonEncode(datos),
    );
    _verificarOk(response, 'No se pudo actualizar la vacuna.');
  }

  Future<void> eliminarVacuna(dynamic id) async {
    final headers = await _headersConToken();
    final response = await _client.delete(
      Uri.parse('$baseUrl/vacunas/$id'),
      headers: headers,
    );
    _verificarOk(response, 'No se pudo eliminar la vacuna.');
  }

  // ============================================================
  // VETERINARIOS
  // ============================================================
  Future<List<Map<String, dynamic>>> obtenerVeterinarios() async {
    final headers = await _headersConToken();
    final response = await _client.get(
      Uri.parse('$baseUrl/veterinarios'),
      headers: headers,
    );
    return _parseLista(response, 'No se pudieron obtener los veterinarios.');
  }

  // ============================================================
  // HELPERS
  // ============================================================
  Map<String, dynamic> _parseBody(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {};
    } catch (_) {
      return {};
    }
  }

  Map<String, dynamic> _parseBodyOk(
      http.Response response,
      String mensajeError,
      ) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) return decoded;
        return {};
      } catch (_) {
        return {};
      }
    }
    final data = _parseBody(response);
    throw Exception(data['error'] ?? mensajeError);
  }

  List<Map<String, dynamic>> _parseLista(
      http.Response response,
      String mensajeError,
      ) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
        return [];
      } catch (_) {
        return [];
      }
    }
    final data = _parseBody(response);
    throw Exception(data['error'] ?? mensajeError);
  }

  void _verificarOk(http.Response response, String mensajeError) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    final data = _parseBody(response);
    throw Exception(data['error'] ?? mensajeError);
  }
}