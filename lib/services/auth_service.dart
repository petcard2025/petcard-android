import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'notification_service.dart';

class AuthService {
  // Patrón Singleton
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final ApiService _apiService = ApiService();
  final NotificationService _notificationService = NotificationService();
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
        // La contraseña NUNCA se recorta: un espacio intencional
        // es parte de la contraseña real del usuario.
        contrasena: password,
      );

      final usuario = respuesta['usuario'] ?? respuesta['user'];
      if (usuario != null) {
        await _persistirUsuario(usuario);
      }

      // Registrar el token de este dispositivo ahora que hay sesión
      await _notificationService.inicializar();

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
    required String telefono,
    String? rol,
  }) async {
    try {
      return await _apiService.registrarUsuario(
        nombre: name.trim(),
        correo: email.trim(),
        contrasena: password,
        telefono: telefono.trim(),
        rol: rol ?? 'cliente',
      );
    } catch (e) {
      throw AuthException(_mensajeAmigable(e.toString()));
    }
  }

  /// ─── RECUPERAR CONTRASEÑA ───
  /// Solicita recuperación de contraseña (envía correo con código).
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _apiService.solicitarRecuperacion(email.trim());
    } catch (e) {
      throw AuthException(_mensajeAmigable(e.toString()));
    }
  }

  /// Restablece la contraseña usando el código de 6 dígitos enviado
  /// por correo. La nueva contraseña NO se recorta, por la misma
  /// razón que en signIn/signUp: un espacio puede ser intencional.
  Future<void> resetPassword({
    required String correo,
    required String codigo,
    required String nuevaContrasena,
  }) async {
    try {
      await _apiService.resetPassword(
        correo: correo.trim(),
        codigo: codigo.trim(),
        nuevaContrasena: nuevaContrasena,
      );
    } catch (e) {
      throw AuthException(_mensajeAmigable(e.toString()));
    }
  }

  /// ─── CERRAR SESIÓN ───
  Future<void> signOut() async {
    await _notificationService.eliminarToken();
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
    return limpio;
  }
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}