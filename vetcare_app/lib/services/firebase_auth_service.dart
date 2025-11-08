import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vetcare_app/models/user.dart';
import 'package:vetcare_app/services/api_service.dart';
import 'dart:convert';

/// Servicio de autenticación con Firebase
/// Usa Firebase Authentication para login y sincroniza con backend Laravel
class FirebaseAuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final ApiService _api = ApiService();

  static const _tokenKey = 'sanctum_token';
  static const _userKey = 'auth_user';

  ApiService get api => _api;

  /// Login con email y password usando Firebase
  Future<UserModel?> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      // 1. Autenticar con Firebase
      final UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Obtener ID Token de Firebase
      final String? firebaseToken = await userCredential.user?.getIdToken();

      if (firebaseToken == null) {
        throw Exception('No se pudo obtener el token de Firebase');
      }

      // 3. Sincronizar con backend Laravel
      final userData = await _verifyAndSyncWithBackend(firebaseToken);

      return userData;
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseError(e);
    } catch (e) {
      throw Exception('Error al iniciar sesión: $e');
    }
  }

  /// Registro con email y password usando Firebase
  Future<UserModel?> registerWithEmail({
    required String email,
    required String password,
    required String nombre,
    String? telefono,
    String rol = 'cliente',
  }) async {
    try {
      // 1. Crear usuario en Firebase
      final UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Actualizar nombre en Firebase
      await userCredential.user?.updateDisplayName(nombre);

      // 3. Obtener ID Token
      final String? firebaseToken = await userCredential.user?.getIdToken();

      if (firebaseToken == null) {
        throw Exception('No se pudo obtener el token de Firebase');
      }

      // 4. Sincronizar con backend Laravel (enviar datos adicionales)
      final userData = await _verifyAndSyncWithBackend(
        firebaseToken,
        nombre: nombre,
        email: email,
        telefono: telefono,
        rol: rol,
      );

      return userData;
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseError(e);
    } catch (e) {
      throw Exception('Error al registrarse: $e');
    }
  }

  /// Verificar token de Firebase y sincronizar con backend Laravel
  Future<UserModel> _verifyAndSyncWithBackend(
    String firebaseToken, {
    String? nombre,
    String? email,
    String? telefono,
    String? rol,
  }) async {
    final body = <String, dynamic>{
      'firebase_token': firebaseToken,
    };

    if (nombre != null) body['nombre'] = nombre;
    if (email != null) body['email'] = email;
    if (telefono != null) body['telefono'] = telefono;
    if (rol != null) body['rol'] = rol;

    // Llamar al endpoint de Firebase en el backend
    final Map<String, dynamic> response = await _api.post<Map<String, dynamic>>(
      'firebase/verify',
      body,
      (json) => (json is Map<String, dynamic>) ? json : <String, dynamic>{},
    );

    // Extraer token Sanctum
    String? sanctumToken;
    if (response.containsKey('sanctum_token')) {
      sanctumToken = response['sanctum_token']?.toString();
    } else if (response.containsKey('token')) {
      sanctumToken = response['token']?.toString();
    } else if (response.containsKey('access_token')) {
      sanctumToken = response['access_token']?.toString();
    }

    if (sanctumToken == null) {
      throw Exception('No se recibió token del backend');
    }

    // Guardar token Sanctum
    _api.setToken(sanctumToken);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, sanctumToken);

    // Extraer datos del usuario
    dynamic userJson;
    if (response.containsKey('user')) {
      userJson = response['user'];
    } else if (response.containsKey('data') && response['data'] is Map) {
      final data = response['data'] as Map;
      if (data.containsKey('user')) {
        userJson = data['user'];
      } else {
        userJson = data;
      }
    }

    if (userJson == null) {
      throw Exception('No se recibieron datos del usuario');
    }

    // Guardar usuario
    await prefs.setString(_userKey, jsonEncode(userJson));

    return UserModel.fromJson(userJson);
  }

  /// Intentar auto-login desde sesión guardada
  Future<UserModel?> tryAutoLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sanctumToken = prefs.getString(_tokenKey);
      final userStr = prefs.getString(_userKey);

      if (sanctumToken == null || userStr == null) {
        return null;
      }

      // Verificar si el usuario de Firebase sigue autenticado
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser == null) {
        // Si no hay usuario en Firebase, limpiar sesión
        await _clearLocalSession();
        return null;
      }

      // Configurar token en API
      _api.setToken(sanctumToken);

      // Retornar usuario guardado
      final userJson = jsonDecode(userStr);
      return UserModel.fromJson(userJson);
    } catch (e) {
      debugPrint('Error en auto-login: $e');
      return null;
    }
  }

  /// Cerrar sesión
  Future<void> logout() async {
    try {
      // 1. Cerrar sesión en backend
      await _api.post<Map<String, dynamic>>(
        'firebase/logout',
        {},
        (json) => (json is Map<String, dynamic>) ? json : {},
      );
    } catch (e) {
      debugPrint('Error al cerrar sesión en backend: $e');
    }

    // 2. Cerrar sesión en Firebase
    await _firebaseAuth.signOut();

    // 3. Limpiar sesión local
    await _clearLocalSession();
  }

  /// Limpiar datos de sesión local
  Future<void> _clearLocalSession() async {
    _api.clearToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  /// Obtener usuario actual de Firebase
  User? get currentFirebaseUser => _firebaseAuth.currentUser;

  /// Stream de cambios de autenticación de Firebase
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Manejar errores de Firebase Auth
  String _handleFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'La contraseña es muy débil. Debe tener al menos 6 caracteres.';
      case 'email-already-in-use':
        return 'Este email ya está registrado. Intenta iniciar sesión.';
      case 'user-not-found':
        return 'No existe una cuenta con este email.';
      case 'wrong-password':
        return 'Contraseña incorrecta.';
      case 'invalid-email':
        return 'El email no es válido.';
      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada.';
      case 'too-many-requests':
        return 'Demasiados intentos. Intenta más tarde.';
      case 'operation-not-allowed':
        return 'Operación no permitida.';
      default:
        return 'Error: ${e.message ?? e.code}';
    }
  }

  /// Enviar email de recuperación de contraseña
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseError(e);
    }
  }

  /// Verificar si el email está verificado
  bool get isEmailVerified => _firebaseAuth.currentUser?.emailVerified ?? false;

  /// Enviar email de verificación
  Future<void> sendEmailVerification() async {
    try {
      await _firebaseAuth.currentUser?.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseError(e);
    }
  }
}

