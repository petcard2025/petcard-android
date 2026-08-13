import 'package:firebase_auth/firebase_auth.dart';

/// Servicio que centraliza toda la lógica de autenticación con Firebase.
/// Las pantallas (screens) solo llaman a estos métodos y muestran el
/// resultado, sin conocer los detalles internos de Firebase.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Inicia sesión con correo y contraseña.
  /// Lanza [AuthException] con un mensaje ya traducido si algo falla.
  Future<User?> signIn({required String email, required String password}) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mensajeLogin(e.code));
    }
  }

  /// Registra un nuevo usuario con correo, contraseña y nombre.
  Future<User?> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      await credential.user?.updateDisplayName(name.trim());
      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mensajeRegistro(e.code));
    }
  }

  /// Envía un correo de recuperación de contraseña.
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mensajeReset(e.code));
    }
  }

  /// Cierra la sesión del usuario actual.
  Future<void> signOut() => _auth.signOut();

  /// Usuario actualmente autenticado (o null si no hay ninguno).
  User? get currentUser => _auth.currentUser;

  /// Stream que emite cada vez que cambia el estado de autenticación.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  String _mensajeLogin(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No existe una cuenta con ese correo';
      case 'wrong-password':
        return 'Contraseña incorrecta';
      case 'invalid-email':
        return 'Correo inválido';
      case 'invalid-credential':
        return 'Correo o contraseña incorrectos';
      default:
        return 'Error al iniciar sesión: $code';
    }
  }

  String _mensajeRegistro(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Ya existe una cuenta con ese correo';
      case 'invalid-email':
        return 'Correo inválido';
      case 'weak-password':
        return 'La contraseña es muy débil';
      default:
        return 'Error al registrarse: $code';
    }
  }

  String _mensajeReset(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No existe una cuenta con ese correo';
      case 'invalid-email':
        return 'Correo inválido';
      default:
        return 'Error: $code';
    }
  }
}

/// Excepción simple para mostrar mensajes de error ya traducidos al español.
class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}