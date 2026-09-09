// ============================================================
// SERVICIO DE AUTENTICACIÓN - Supabase Auth + tabla usuario
// ============================================================

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_client.dart';

class AuthService {
  // Patrón Singleton
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  Map<String, dynamic>? _usuarioActual;
  Map<String, dynamic>? get usuarioActual => _usuarioActual;

  /// Obtiene el usuario autenticado actual de Supabase
  User? get currentUser => supabase.auth.currentUser;

  /// Verifica si hay sesión activa
  bool get isLoggedIn => currentUser != null;

  Future<void> _persistirUsuario(Map<String, dynamic> usuario) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('petcard_usuario_actual', jsonEncode(usuario));
    _usuarioActual = usuario;
  }

  /// ─── LOGIN CON SUPABASE ───
  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // 1. Autenticar con Supabase
      final response = await supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password.trim(),
      );

      if (response.user == null) {
        throw Exception('Error al iniciar sesión');
      }

      // 2. Obtener datos del usuario desde la tabla 'usuario'
      final userData = await supabase
          .from('usuario')
          .select()
          .eq('Correo', email.trim())
          .maybeSingle();

      if (userData == null) {
        // Si no existe en la tabla, lo creamos
        await supabase.from('usuario').insert({
          'Nombre': response.user!.userMetadata?['Nombre'] ?? email.trim(),
          'Correo': email.trim(),
          'Telefono': response.user!.userMetadata?['Telefono'] ?? '',
          'Rol': response.user!.userMetadata?['Rol'] ?? 'cliente',
          'firebase_uid': response.user!.id,
        });

        // Volvemos a consultar
        final newUserData = await supabase
            .from('usuario')
            .select()
            .eq('Correo', email.trim())
            .maybeSingle();

        if (newUserData == null) {
          throw Exception('Error al crear el usuario en la base de datos');
        }

        final usuario = Map<String, dynamic>.from(newUserData);
        await _persistirUsuario(usuario);

        return {
          'token': response.session?.accessToken ?? '',
          'usuario': usuario,
        };
      }

      // 3. Guardar usuario en memoria y SharedPreferences
      final usuario = Map<String, dynamic>.from(userData);
      await _persistirUsuario(usuario);

      return {
        'token': response.session?.accessToken ?? '',
        'usuario': usuario,
      };
    } on AuthException catch (e) {
      throw AuthException(_mensajeAmigable(e.message));
    } catch (e) {
      throw AuthException(_mensajeAmigable(e.toString()));
    }
  }

  /// ─── REGISTRO CON SUPABASE ───
  Future<Map<String, dynamic>> signUp({
    required String name,
    required String email,
    required String password,
    String? telefono,
    String? rol,
  }) async {
    try {
      // 1. Registrar en Supabase Auth
      final response = await supabase.auth.signUp(
        email: email.trim(),
        password: password.trim(),
        data: {
          'Nombre': name.trim(),
          'Correo': email.trim(),
          'Telefono': telefono ?? '',
          'Rol': rol ?? 'cliente',
        },
      );

      if (response.user == null) {
        throw Exception('Error al crear la cuenta');
      }

      // 2. Insertar en la tabla 'usuario'
      await supabase.from('usuario').insert({
        'Nombre': name.trim(),
        'Correo': email.trim(),
        'Telefono': telefono ?? '',
        'Rol': rol ?? 'cliente',
        'firebase_uid': response.user!.id,
      });

      return {
        'message': 'Usuario registrado exitosamente',
        'user': response.user,
      };
    } on AuthException catch (e) {
      throw AuthException(_mensajeAmigable(e.message));
    } catch (e) {
      throw AuthException(_mensajeAmigable(e.toString()));
    }
  }

  /// ─── RECUPERAR CONTRASEÑA ───
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await supabase.auth.resetPasswordForEmail(email.trim());
    } on AuthException catch (e) {
      throw AuthException(_mensajeAmigable(e.message));
    } catch (e) {
      throw AuthException(_mensajeAmigable(e.toString()));
    }
  }

  /// ─── CERRAR SESIÓN ───
  Future<void> signOut() async {
    await supabase.auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('petcard_usuario_actual');
    _usuarioActual = null;
  }

  /// ─── VERIFICAR SESIÓN ACTIVA ───
  Future<bool> haySesionActiva() async {
    if (currentUser != null) {
      if (_usuarioActual != null) return true;

      final prefs = await SharedPreferences.getInstance();
      final userStr = prefs.getString('petcard_usuario_actual');
      if (userStr != null) {
        _usuarioActual = jsonDecode(userStr);
        return true;
      }
      return true;
    }

    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString('petcard_usuario_actual');
    if (userStr != null) {
      _usuarioActual = jsonDecode(userStr);
      return true;
    }

    return false;
  }

  /// ─── OBTENER USUARIO ACTUAL DESDE SUPABASE ───
  Future<Map<String, dynamic>?> getUsuarioActual() async {
    if (_usuarioActual != null) return _usuarioActual;

    final user = currentUser;
    if (user == null || user.email == null) return null;

    final response = await supabase
        .from('usuario')
        .select()
        .eq('Correo', user.email!)
        .maybeSingle();

    if (response != null) {
      _usuarioActual = Map<String, dynamic>.from(response);
      await _persistirUsuario(_usuarioActual!);
    }

    return _usuarioActual;
  }

  /// ─── OBTENER ROL DEL USUARIO ───
  Future<String?> getRol() async {
    final usuario = await getUsuarioActual();
    return usuario?['Rol'] ?? 'cliente';
  }

  /// ─── MENSAJES AMIGABLES ───
  String _mensajeAmigable(String errorTexto) {
    final limpio = errorTexto.replaceFirst('Exception: ', '');
    if (limpio.contains('Invalid login credentials') ||
        limpio.contains('Correo o contrasena incorrectos')) {
      return 'Correo o contraseña incorrectos';
    }
    if (limpio.contains('SocketException') ||
        limpio.contains('Connection') ||
        limpio.contains('Failed to connect') ||
        limpio.contains('Network')) {
      return 'Error de conexión a Internet';
    }
    if (limpio.contains('Email not confirmed')) {
      return 'Confirma tu correo antes de iniciar sesión';
    }
    if (limpio.contains('User already registered')) {
      return 'Este correo ya está registrado';
    }
    if (limpio.contains('password')) {
      return 'Contraseña incorrecta';
    }
    if (limpio.contains('email')) {
      return 'Correo electrónico inválido';
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