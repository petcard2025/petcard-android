// ============================================================
// SERVICIO DE AUTENTICACIÓN - Supabase Auth + tabla usuario
// ============================================================

import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_client.dart';
import 'models.dart';

class AuthService {
  /// Obtiene el usuario autenticado actual (de Supabase Auth)
  User? get currentUser => supabase.auth.currentUser;

  /// Verifica si hay sesión activa
  bool get isLoggedIn => currentUser != null;

  /// ─── REGISTRO ───
  Future<String?> register({
    required String nombre,
    required String correo,
    required String contrasena,
    required String rol,
    String? telefono,
  }) async {
    try {
      final authResponse = await supabase.auth.signUp(
        email: correo,
        password: contrasena,
      );

      if (authResponse.user == null) {
        return 'Error al crear la cuenta';
      }

      await supabase.from('usuario').insert({
        'Nombre': nombre,
        'Correo': correo,
        'Telefono': telefono,
        'Contrasena': contrasena,
        'Rol': rol,
      });

      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Error inesperado: $e';
    }
  }

  /// ─── LOGIN ───
  Future<String?> login({
    required String correo,
    required String contrasena,
  }) async {
    try {
      await supabase.auth.signInWithPassword(
        email: correo,
        password: contrasena,
      );
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Error inesperado: $e';
    }
  }

  /// ─── LOGOUT ───
  Future<void> logout() async {
    await supabase.auth.signOut();
  }

  /// ─── OBTENER DATOS DEL USUARIO DESDE LA TABLA ───
  Future<Usuario?> getUsuarioActual() async {
    final user = currentUser;
    if (user == null || user.email == null) return null;

    final response = await supabase
        .from('usuario')
        .select()
        .eq('Correo', user.email!)
        .maybeSingle();

    return response != null ? Usuario.fromJson(response) : null;
  }

  /// ─── ESCUCHAR CAMBIOS DE SESIÓN ───
  Stream<AuthState> get onAuthStateChange => supabase.auth.onAuthStateChange;
}