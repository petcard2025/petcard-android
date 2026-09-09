import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AuthService {
  // Patrón Singleton
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final ApiService _apiService = ApiService();

  Map<String, dynamic>? _usuarioActual;
  Map<String, dynamic>? get usuarioActual => _usuarioActual;

  Future<void> _persistirUsuario(Map<String, dynamic> usuario) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('petcard_usuario_actual', jsonEncode(usuario));
    _usuarioActual = usuario;
  }

  /// ─── LOGIN ───
  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final respuesta = await _apiService.login(
        correo: email.trim(),
        contrasena: password.trim(),
      );

      final usuario = respuesta['usuario'] ?? respuesta['user'];
      if (usuario != null) {
        await _persistirUsuario(usuario);
      }
      return respuesta;
    } catch (e) {
      throw AuthException(_mensajeAmigable(e.toString()));
    }
  }

  /// ─── REGISTRO ───
  Future<Map<String, dynamic>> signUp({
    required String name,
    required String email,
    required String password,
    String? telefono,
    String? rol,
  }) async {
    try {
      return await _apiService.registrarUsuario(
        nombre: name.trim(),
        correo: email.trim(),
        contrasena: password.trim(),
        telefono: telefono,
        rol: rol ?? 'cliente',
      );
    } catch (e) {
      throw AuthException(_mensajeAmigable(e.toString()));
    }
  }

  /// ─── RECUPERAR CONTRASEÑA ───
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _apiService.solicitarRecuperacion(email.trim());
    } catch (e) {
      throw AuthException(_mensajeAmigable(e.toString()));
    }
  }

  /// ─── CERRAR SESIÓN ───
  Future<void> signOut() async {
    await _apiService.logout();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('petcard_usuario_actual');
    _usuarioActual = null;
  }

  /// ─── VERIFICAR SESIÓN ACTIVA ───
  Future<bool> haySesionActiva() async {
    final token = await _apiService.obtenerToken();
    if (token == null) return false;

    if (_usuarioActual != null) return true;

    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString('petcard_usuario_actual');
    if (userStr != null) {
      _usuarioActual = jsonDecode(userStr);
      return true;
    }

    return false;
  }

  String _mensajeAmigable(String errorTexto) {
    final limpio = errorTexto.replaceFirst('Exception: ', '');
    if (limpio.contains('Correo o contrasena incorrectos')) {
      return 'Correo o contraseña incorrectos';
    }
    if (limpio.contains('SocketException') || limpio.contains('Connection')) {
      return 'Error de conexión a Internet';
    }
    return limpio;
  }
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}