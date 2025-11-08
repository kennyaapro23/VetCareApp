import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vetcare_app/models/user.dart';
import 'package:vetcare_app/services/api_service.dart';
import 'package:vetcare_app/services/auth_service.dart';
import 'dart:convert';

/// Servicio de autenticación HÍBRIDO
/// Soporta AMBOS sistemas: Firebase + Laravel tradicional
/// Intenta Firebase primero, si falla usa Laravel tradicional
class HybridAuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final AuthService _traditionalAuth = AuthService();
  final ApiService _api = ApiService();

  static const _tokenKey = 'sanctum_token';
  static const _userKey = 'auth_user';
  static const _authTypeKey = 'auth_type'; // 'firebase' o 'traditional'

  ApiService get api => _api;

  /// Login híbrido: intenta Firebase, si falla usa tradicional
  Future<UserModel?> login({
    required String email,
    required String password,
  }) async {
    // Primero intentar con Firebase
    try {
      debugPrint('🔥 Intentando login con Firebase...');
      final firebaseResult = await _loginWithFirebase(email, password);
      if (firebaseResult != null) {
        await _saveAuthType('firebase');
        debugPrint('✅ Login exitoso con Firebase');
        return firebaseResult;
      }
    } catch (e) {
      debugPrint('⚠️ Firebase login falló: $e');
      debugPrint('📝 Intentando con sistema tradicional como respaldo...');
    }

    // Si Firebase falla, intentar con sistema tradicional
    try {
      debugPrint('📝 Intentando login con sistema tradicional...');
      final traditionalResult = await _traditionalAuth.login(
        email: email,
        password: password,
      );
      if (traditionalResult != null) {
        // ⚡ IMPORTANTE: Configurar el token en NUESTRO ApiService también
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token'); // Token guardado por AuthService
        if (token != null) {
          _api.setToken(token);
          await prefs.setString(_tokenKey, token); // Guardar con nuestra key también
          debugPrint('✅ Token configurado en HybridAuthService ApiService: ${token.substring(0, 20)}...');
        }

        await _saveAuthType('traditional');
        debugPrint('✅ Login exitoso con sistema tradicional');
        return traditionalResult;
      }
      // Si llegamos aquí, las credenciales son inválidas
      throw Exception('Credenciales inválidas');
    } catch (e) {
      debugPrint('❌ Sistema tradicional también falló: $e');
      // Re-lanzar el error original
      rethrow;
    }
  }

  /// Login con Firebase
  Future<UserModel?> _loginWithFirebase(String email, String password) async {
    // 1. Autenticar con Firebase
    final UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final firebaseUser = userCredential.user;
    if (firebaseUser == null) {
      throw Exception('No se pudo obtener el usuario de Firebase');
    }

    // 2. Obtener ID Token de Firebase
    final String? firebaseToken = await firebaseUser.getIdToken();

    if (firebaseToken == null) {
      throw Exception('No se pudo obtener el token de Firebase');
    }

    // 3. Intentar sincronizar con backend Laravel (opcional)
    try {
      final body = {'firebase_token': firebaseToken};

      final Map<String, dynamic> response = await _api.post<Map<String, dynamic>>(
        'firebase/verify',
        body,
        (json) => (json is Map<String, dynamic>) ? json : <String, dynamic>{},
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('⏱️ Timeout en backend, usando solo Firebase');
          throw Exception('Backend timeout');
        },
      );

      return _processBackendResponse(response);
    } catch (e) {
      debugPrint('⚠️ Backend no disponible, creando usuario local: $e');

      // Si el backend no está disponible, crear usuario básico con datos de Firebase
      final user = UserModel(
        id: firebaseUser.uid,
        name: firebaseUser.displayName ?? email.split('@')[0],
        email: email,
        role: 'cliente', // rol por defecto
      );

      // Guardar token y usuario localmente
      _api.setToken(firebaseToken);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, firebaseToken);
      await prefs.setString(_userKey, jsonEncode(user.toJson()));

      return user;
    }
  }

  /// Registro (intenta Firebase primero, luego tradicional como fallback)
  Future<UserModel?> register(Map<String, dynamic> data) async {
    // Intentar con Firebase primero
    try {
      debugPrint('🔥 Registrando usuario con Firebase...');

      // 1. Crear usuario en Firebase
      final UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: data['email'],
        password: data['password'],
      );

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw Exception('No se pudo crear el usuario en Firebase');
      }

      // 2. Actualizar nombre en Firebase
      await firebaseUser.updateDisplayName(data['nombre'] ?? data['name']);

      // 3. Obtener ID Token
      final String? firebaseToken = await firebaseUser.getIdToken();

      if (firebaseToken == null) {
        throw Exception('No se pudo obtener el token de Firebase');
      }

      // 4. Intentar sincronizar con backend Laravel (opcional)
      try {
        final body = <String, dynamic>{
          'firebase_token': firebaseToken,
          'nombre': data['nombre'] ?? data['name'],
          'email': data['email'],
          if (data['telefono'] != null) 'telefono': data['telefono'],
          'rol': data['rol'] ?? data['role'] ?? 'cliente',
        };

        final Map<String, dynamic> response = await _api.post<Map<String, dynamic>>(
          'firebase/verify',
          body,
          (json) => (json is Map<String, dynamic>) ? json : <String, dynamic>{},
        ).timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            debugPrint('⏱️ Timeout en backend, usando solo Firebase');
            throw Exception('Backend timeout');
          },
        );

        await _saveAuthType('firebase');
        debugPrint('✅ Registro exitoso con Firebase + backend');

        return _processBackendResponse(response);
      } catch (e) {
        debugPrint('⚠️ Backend no disponible en registro, creando usuario local: $e');

        // Si el backend no está disponible, crear usuario básico con datos de Firebase
        final user = UserModel(
          id: firebaseUser.uid,
          name: data['nombre'] ?? data['name'],
          email: data['email'],
          role: data['rol'] ?? data['role'] ?? 'cliente',
        );

        // Guardar token y usuario localmente
        _api.setToken(firebaseToken);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, firebaseToken);
        await prefs.setString(_userKey, jsonEncode(user.toJson()));
        await _saveAuthType('firebase');

        debugPrint('✅ Registro exitoso solo con Firebase');
        return user;
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('⚠️ Firebase registro falló: ${_handleFirebaseError(e)}');
      debugPrint('📝 Intentando registro con sistema tradicional como respaldo...');
    } catch (e) {
      debugPrint('⚠️ Error en registro con Firebase: $e');
      debugPrint('📝 Intentando registro con sistema tradicional como respaldo...');
    }

    // Si Firebase falla, intentar con sistema tradicional
    try {
      debugPrint('📝 Registrando con sistema tradicional...');
      final traditionalResult = await _traditionalAuth.register(data);
      if (traditionalResult != null) {
        await _saveAuthType('traditional');
        debugPrint('✅ Registro exitoso con sistema tradicional');
        return traditionalResult;
      }
      throw Exception('Registro fallido');
    } catch (e) {
      debugPrint('❌ Sistema tradicional también falló: $e');
      rethrow;
    }
  }

  /// Procesar respuesta del backend y extraer usuario/token
  Future<UserModel> _processBackendResponse(Map<String, dynamic> response) async {
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

  /// Intentar auto-login
  Future<UserModel?> tryAutoLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sanctumToken = prefs.getString(_tokenKey);
      final userStr = prefs.getString(_userKey);
      final authType = prefs.getString(_authTypeKey) ?? 'traditional';

      debugPrint('🔍 tryAutoLogin - sanctumToken: ${sanctumToken != null ? "SÍ (${sanctumToken.length} chars)" : "NO"}');
      debugPrint('🔍 tryAutoLogin - userStr: ${userStr != null ? "SÍ" : "NO"}');
      debugPrint('🔍 tryAutoLogin - authType: $authType');

      if (sanctumToken == null || userStr == null) {
        debugPrint('❌ tryAutoLogin - No hay sesión guardada');
        return null;
      }

      // Si era Firebase, verificar que siga autenticado
      if (authType == 'firebase') {
        final firebaseUser = _firebaseAuth.currentUser;
        if (firebaseUser == null) {
          debugPrint('⚠️ Usuario de Firebase no encontrado, limpiando sesión');
          await _clearLocalSession();
          return null;
        }
      }

      // Configurar token en API
      _api.setToken(sanctumToken);
      debugPrint('✅ Token configurado en ApiService: ${sanctumToken.substring(0, 20)}...');

      // Retornar usuario guardado
      final userJson = jsonDecode(userStr);
      debugPrint('✅ Auto-login exitoso con sistema: $authType, usuario: ${userJson['email']}');
      return UserModel.fromJson(userJson);
    } catch (e) {
      debugPrint('⚠️ Error en auto-login: $e');
      return null;
    }
  }

  /// Cerrar sesión
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final authType = prefs.getString(_authTypeKey) ?? 'traditional';

    try {
      if (authType == 'firebase') {
        // Logout con Firebase
        await _api.post<Map<String, dynamic>>(
          'firebase/logout',
          {},
          (json) => (json is Map<String, dynamic>) ? json : {},
        );
        await _firebaseAuth.signOut();
      } else {
        // Logout tradicional
        await _traditionalAuth.logout();
      }
    } catch (e) {
      debugPrint('⚠️ Error en logout: $e');
    }

    await _clearLocalSession();
  }

  /// Guardar tipo de autenticación usada
  Future<void> _saveAuthType(String type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_authTypeKey, type);
  }

  /// Limpiar sesión local
  Future<void> _clearLocalSession() async {
    _api.clearToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    await prefs.remove(_authTypeKey);
  }

  /// Manejar errores de Firebase
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
      default:
        return 'Error: ${e.message ?? e.code}';
    }
  }

  /// Enviar email de recuperación (solo para usuarios Firebase)
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseError(e);
    }
  }
}
