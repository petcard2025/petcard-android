import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

/// Servicio centralizado de autenticación.
///
/// Ahora todo pasa por el backend propio (JWT + MySQL),
/// sin depender de Firebase Authentication.
class AuthService {
  final ApiService _apiService = ApiService();

  Map<String, dynamic>? _usuarioActual;
  Map<String, dynamic>? get usuarioActual => _usuarioActual;

  /// Inicia sesión contra el backend y guarda el JWT localmente.
  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final respuesta = await _apiService.login(
        correo: email.trim(),
        contrasena: password.trim(),
      );
      _usuarioActual = respuesta['usuario'] as Map<String, dynamic>?;
      return respuesta;
    } catch (e) {
      throw AuthException(_mensajeAmigable(e.toString()));
    }
  }

  /// Registra un nuevo usuario directamente en MySQL.
  Future<Map<String, dynamic>> signUp({
    required String name,
    required String email,
    required String password,
    String? telefono,
    String? rol,
  }) async {
    try {
      final respuesta = await _apiService.registrarUsuario(
        nombre: name.trim(),
        correo: email.trim(),
        contrasena: password.trim(),
        telefono: telefono,
        rol: rol ?? 'cliente',
      );
      return respuesta;
    } catch (e) {
      throw AuthException(_mensajeAmigable(e.toString()));
    }
  }

  /// Solicita recuperación de contraseña.
  /// ⚠️ Ver nota en ApiService: aún no envía correo real.
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _apiService.solicitarRecuperacion(email.trim());
    } catch (e) {
      throw AuthException(_mensajeAmigable(e.toString()));
    }
  }

  Future<void> signOut() async {
    await _apiService.logout();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('petcard_usuario_actual');
    _usuarioActual = null;
  }

  Future<bool> haySesionActiva() async {
    final token = await _apiService.obtenerToken();
    return token != null;
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