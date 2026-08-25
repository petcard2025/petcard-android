import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  // Dispositivo físico por USB → computador (usa "adb reverse tcp:3001 tcp:3001")
  static const String baseUrl = 'https://127.0.0.1:3001/api';

  final _storage = const FlutterSecureStorage();
  static const _tokenKey = 'jwt_token';

  // ============================================================
  // CLIENTE HTTP QUE ACEPTA EL CERTIFICADO AUTOFIRMADO DE DESARROLLO
  // ⚠️ SOLO para 127.0.0.1 (tu backend local vía adb reverse). Nunca uses
  // esto para dominios externos/producción — ahí sí debe validarse
  // el certificado normalmente.
  // ============================================================
  static http.Client _clienteHttp() {
    final httpClient = HttpClient()
      ..badCertificateCallback = (cert, host, port) {
        return host == '127.0.0.1'; // solo confía en tu backend local
      };
    return IOClient(httpClient);
  }

  final http.Client _client = _clienteHttp();

  // ============================================================
  // TOKEN LOCAL (JWT propio, guardado en el dispositivo)
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
      throw Exception('No hay sesión activa.');
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ============================================================
  // LOGIN
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

    print('LOGIN STATUS: ${response.statusCode}');
    print('LOGIN RESPUESTA: ${response.body}');

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

  // ============================================================
  // REGISTRO (usa tu endpoint normal de usuarios)
  // ============================================================

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

    print('REGISTRO STATUS: ${response.statusCode}');
    print('REGISTRO RESPUESTA: ${response.body}');

    final data = _parseBody(response);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }

    throw Exception(data['error'] ?? 'Error al registrarse.');
  }

  // ============================================================
  // OBTENER MI USUARIO
  // ============================================================

  Future<Map<String, dynamic>> obtenerMiUsuario() async {
    final headers = await _headersConToken();

    final response = await _client.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: headers,
    );

    final data = _parseBody(response);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }

    throw Exception(data['error'] ?? 'No se pudo obtener el usuario.');
  }

  // ============================================================
  // RECUPERAR CONTRASEÑA
  // ⚠️ El backend aún no envía correos reales — solo genera el
  // token. Falta implementar el envío por email en el servidor.
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
  // LOGOUT
  // ============================================================

  Future<void> logout() async {
    await borrarToken();
  }

  // ============================================================
  // ADMIN · ALIMENTACIÓN (planes nutricionales)
  // ============================================================

  Future<List<Map<String, dynamic>>> obtenerPlanesAlimentacion() async {
    final headers = await _headersConToken();
    final response = await _client.get(Uri.parse('$baseUrl/alimentacion'), headers: headers);
    return _parseLista(response, 'No se pudieron obtener los planes.');
  }

  Future<void> actualizarPlanAlimentacion(
      dynamic id, Map<String, dynamic> datos) async {
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
    final response =
    await _client.delete(Uri.parse('$baseUrl/alimentacion/$id'), headers: headers);
    _verificarOk(response, 'No se pudo eliminar el plan.');
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

  // ============================================================
  // ADMIN · SERVICIOS
  // ============================================================

  Future<List<Map<String, dynamic>>> obtenerServicios() async {
    final headers = await _headersConToken();
    final response = await _client.get(Uri.parse('$baseUrl/servicios'), headers: headers);
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
    final response =
    await _client.delete(Uri.parse('$baseUrl/servicios/$id'), headers: headers);
    _verificarOk(response, 'No se pudo eliminar el servicio.');
  }

  // ============================================================
  // ADMIN · NOTIFICACIONES
  // ============================================================

  Future<List<Map<String, dynamic>>> obtenerNotificaciones() async {
    final headers = await _headersConToken();
    final response = await _client.get(Uri.parse('$baseUrl/notificaciones'), headers: headers);
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
    final response =
    await _client.delete(Uri.parse('$baseUrl/notificaciones/$id'), headers: headers);
    _verificarOk(response, 'No se pudo eliminar la notificación.');
  }

  // ============================================================
  // ADMIN · USUARIOS
  // ============================================================

  Future<List<Map<String, dynamic>>> obtenerUsuarios() async {
    final headers = await _headersConToken();
    final response = await _client.get(Uri.parse('$baseUrl/usuarios'), headers: headers);
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
    final response =
    await _client.delete(Uri.parse('$baseUrl/usuarios/$id'), headers: headers);
    _verificarOk(response, 'No se pudo eliminar el usuario.');
  }

  // ============================================================
  // MASCOTAS (usado por formularios de admin)
  // ============================================================

  Future<List<Map<String, dynamic>>> obtenerMascotasAdmin() async {
    final headers = await _headersConToken();
    final response = await _client.get(Uri.parse('$baseUrl/mascotas'), headers: headers);
    return _parseLista(response, 'No se pudieron obtener las mascotas.');
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

  /// Decodifica una respuesta que debe ser una lista (arrays JSON del backend).
  List<Map<String, dynamic>> _parseLista(http.Response response, String mensajeError) {
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

  /// Lanza una excepción legible si la respuesta no fue exitosa.
  void _verificarOk(http.Response response, String mensajeError) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    final data = _parseBody(response);
    throw Exception(data['error'] ?? mensajeError);
  }
}