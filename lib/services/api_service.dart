import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  // Android Emulator → computador
  static const String baseUrl = 'https://10.0.2.2:3001/api';

  final _storage = const FlutterSecureStorage();
  static const _tokenKey = 'jwt_token';

  // ============================================================
  // CLIENTE HTTP QUE ACEPTA EL CERTIFICADO AUTOFIRMADO DE DESARROLLO
  // ⚠️ SOLO para 10.0.2.2 (tu backend local). Nunca uses esto
  // para dominios externos/producción — ahí sí debe validarse
  // el certificado normalmente.
  // ============================================================
  static http.Client _clienteHttp() {
    final httpClient = HttpClient()
      ..badCertificateCallback = (cert, host, port) {
        return host == '10.0.2.2'; // solo confía en tu backend local
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
      print('DEBUG - Error: No se encontró token en el almacenamiento.');
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
      Uri.parse('$baseUrl/login'),
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
  // ⚠️ El backend aún no envía correos reales — solo genera el
  // token. Falta implementar el envío por email en el servidor.
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
  // LOGOUT
  // ============================================================

  Future<void> logout() async {
    await borrarToken();
  }

  // ============================================================
  // CRUD GENÉRICO (citas, alimentación, servicios, mascotas...)
  // Reutiliza el mismo token y el mismo cliente HTTP que confía
  // en el certificado de desarrollo. Úsalo para cualquier endpoint
  // protegido que devuelva/reciba JSON.
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
  // HELPER
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
}