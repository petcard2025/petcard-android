import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {

static const String baseUrl = 'https://10.0.2.2:3001/api';

  final _storage = const FlutterSecureStorage();
  static const _tokenKey = 'jwt_token';


  static http.Client _clienteHttp() {
    final httpClient = HttpClient()
      ..badCertificateCallback = (cert, host, port) {
        return host == '10.0.2.2';
      };
    return IOClient(httpClient);
  }

  final http.Client _client = _clienteHttp();

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

  Future<Map<String, String>> _headersConToken() async {
    final token = await obtenerToken();
    if (token == null) {
      print('DEBUG - Error: No se encontró token en el almacenamiento.');
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
      Uri.parse('$baseUrl/login'),
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
  // ============================================================
  // OBTENER MI USUARIO
  // ============================================================

  Future<Map<String, dynamic>> obtenerMiUsuario() async {
    final headers = await _headersConToken();

    print('DEBUG - Consultando /auth/me...');
    final response = await _client.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: headers,
    );

    print('DEBUG - /auth/me STATUS: ${response.statusCode}');
    print('DEBUG - /auth/me BODY: ${response.body}');

    final data = _parseBody(response);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }

    throw Exception(data['error'] ?? 'Error del servidor (${response.statusCode})');
  }
// ============================================================
// RECUPERAR CONTRASEÑA
// ============================================================
  Future<void> solicitarRecuperacion(String correo) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/forgot-password'),
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
  // CRUD GENÉRICO (usado por pantallas de veterinario: citas,
  // alimentación propia, etc.) Reutiliza el mismo token y el mismo
  // cliente HTTP que confía en el certificado de desarrollo.
  // ============================================================

  /// GET que devuelve una lista (p. ej. /citas, /alimentacion, /servicios)
  Future<List<dynamic>> obtenerLista(String endpoint) async {
    final headers = await _headersConToken();
    final response = await _client.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is List) return decoded;
      return [];
    }

    final data = _parseBody(response);
    throw Exception(data['error'] ?? 'Error al consultar $endpoint');
  }

  /// GET que devuelve un solo objeto (p. ej. /citas/5)
  Future<Map<String, dynamic>> obtenerUno(String endpoint) async {
    final headers = await _headersConToken();
    final response = await _client.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    );

    final data = _parseBody(response);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }
    throw Exception(data['error'] ?? 'Error al consultar $endpoint');
  }

  /// POST — crear un registro
  Future<Map<String, dynamic>> crear(
      String endpoint, Map<String, dynamic> body) async {
    final headers = await _headersConToken();
    final response = await _client.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );

    final data = _parseBody(response);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }
    throw Exception(data['error'] ?? 'Error al crear en $endpoint');
  }

  /// PUT — actualizar un registro existente
  Future<Map<String, dynamic>> actualizar(
      String endpoint, Map<String, dynamic> body) async {
    final headers = await _headersConToken();
    final response = await _client.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );

    final data = _parseBody(response);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }
    throw Exception(data['error'] ?? 'Error al actualizar $endpoint');
  }

  /// DELETE — eliminar un registro
  Future<void> eliminar(String endpoint) async {
    final headers = await _headersConToken();
    final response = await _client.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }
    final data = _parseBody(response);
    throw Exception(data['error'] ?? 'Error al eliminar $endpoint');
  }

  // ============================================================
  // HELPERS
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
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
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
