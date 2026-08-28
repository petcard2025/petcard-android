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
  // MASCOTAS
  // ============================================================

  Future<List<Map<String, dynamic>>> obtenerMascotas() async {
    final headers = await _headersConToken();
    final response = await _client.get(
      Uri.parse('$baseUrl/mascotas'),
      headers: headers,
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) {
        return List<Map<String, dynamic>>.from(decoded);
      }
      return [];
    }
    throw Exception('Error al obtener mascotas.');
  }

  // ============================================================
  // PLAN DE ALIMENTACION
  // ============================================================

  Future<List<Map<String, dynamic>>> obtenerPlanesAlimentacion() async {
    final headers = await _headersConToken();
    final response = await _client.get(
      Uri.parse('$baseUrl/alimentacion'),
      headers: headers,
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) {
        return List<Map<String, dynamic>>.from(decoded);
      }
      return [];
    }
    throw Exception('Error al obtener planes de alimentación.');
  }

  Future<List<Map<String, dynamic>>> obtenerPlanesPorMascota(
      int idMascota) async {
    final headers = await _headersConToken();
    final response = await _client.get(
      Uri.parse('$baseUrl/alimentacion/mascota/$idMascota'),
      headers: headers,
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) {
        return List<Map<String, dynamic>>.from(decoded);
      }
      return [];
    }
    throw Exception('Error al obtener planes de la mascota.');
  }

  Future<Map<String, dynamic>> crearPlanAlimentacion({
    required int idMascota,
    required String tipoDieta,
    String? frecuencia,
    String? alergias,
    String? horario,
    int? calorias,
    String? suplementos,
    String? comidas,
    String? fechaInicio,
    String? fechaFin,
    String? observaciones,
  }) async {
    final headers = await _headersConToken();
    final response = await _client.post(
      Uri.parse('$baseUrl/alimentacion'),
      headers: headers,
      body: jsonEncode({
        'ID_mascota': idMascota,
        'ID_servicio': 1,
        'Tipo_dieta': tipoDieta,
        'Frecuencia': frecuencia,
        'Alergias': alergias,
        'Horario': horario,
        'Calorias': calorias,
        'Suplementos': suplementos,
        'Comidas': comidas,
        'Fecha_inicio': fechaInicio,
        'Fecha_fin': fechaFin,
        'Observaciones': observaciones,
      }),
    );
    final data = _parseBody(response);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }
    throw Exception(data['error'] ?? 'Error al crear plan de alimentación.');
  }

  Future<Map<String, dynamic>> actualizarPlanAlimentacion(
    int idPlan, {
    required String tipoDieta,
    String? frecuencia,
    String? alergias,
    String? horario,
    int? calorias,
    String? suplementos,
    String? comidas,
    String? fechaInicio,
    String? fechaFin,
    String? observaciones,
  }) async {
    final headers = await _headersConToken();
    final response = await _client.put(
      Uri.parse('$baseUrl/alimentacion/$idPlan'),
      headers: headers,
      body: jsonEncode({
        'Tipo_dieta': tipoDieta,
        'Frecuencia': frecuencia,
        'Alergias': alergias,
        'Horario': horario,
        'Calorias': calorias,
        'Suplementos': suplementos,
        'Comidas': comidas,
        'Fecha_inicio': fechaInicio,
        'Fecha_fin': fechaFin,
        'Observaciones': observaciones,
      }),
    );
    final data = _parseBody(response);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }
    throw Exception(
        data['error'] ?? 'Error al actualizar plan de alimentación.');
  }

  Future<void> eliminarPlanAlimentacion(int idPlan) async {
    final headers = await _headersConToken();
    final response = await _client.delete(
      Uri.parse('$baseUrl/alimentacion/$idPlan'),
      headers: headers,
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }
    throw Exception('Error al eliminar plan de alimentación.');
  }

  // ============================================================
  // HELPER
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
}