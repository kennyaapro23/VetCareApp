import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:vetcare_app/models/user.dart';
import 'package:vetcare_app/services/api_service.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final ApiService _api = ApiService();
  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user';

  /// Intenta autenticar contra [login].
  /// Espera respuestas tipo Laravel: { token: "...", user: { ... } } o { access_token: "...", user: { ... } }
  Future<UserModel?> login({required String email, required String password}) async {
    final body = {'email': email, 'password': password};

    final Map<String, dynamic> resp = await _api.post<Map<String, dynamic>>(
      'auth/login', // Ruta correcta según API_ENDPOINTS.md
      body,
      (json) => (json is Map<String, dynamic>) ? json : <String, dynamic>{},
    );

    String? token;
    if (resp.containsKey('token')) token = resp['token']?.toString();
    if (token == null && resp.containsKey('access_token')) token = resp['access_token']?.toString();
    if (token == null && resp.containsKey('data') && resp['data'] is Map && resp['data'].containsKey('token')) {
      token = resp['data']['token']?.toString();
    }

    dynamic userJson;
    if (resp.containsKey('user')) userJson = resp['user'];
    else if (resp.containsKey('data') && resp['data'] is Map && resp['data'].containsKey('user')) userJson = resp['data']['user'];
    else if (resp.containsKey('data') && resp['data'] is Map && (resp['data'].containsKey('id') || resp['data'].containsKey('email'))) userJson = resp['data'];
    else if (resp.containsKey('id') || resp.containsKey('email')) userJson = resp;

    if (token != null) {
      _api.setToken(token);
      // persistir token y user
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      if (userJson != null) {
        final userStr = jsonEncode(userJson);
        await prefs.setString(_userKey, userStr);
      }
    }

    if (userJson != null) {
      return UserModel.fromJson(userJson);
    }

    return null;
  }

  /// Registro de usuario: POST a register
  Future<UserModel?> register(Map<String, dynamic> data) async {
    final Map<String, dynamic> resp = await _api.post<Map<String, dynamic>>(
      'auth/register',  // Ruta correcta según API_ENDPOINTS.md
      data,
      (json) => (json is Map<String, dynamic>) ? json : <String, dynamic>{},
    );

    String? token;
    if (resp.containsKey('token')) token = resp['token']?.toString();
    if (token == null && resp.containsKey('access_token')) token = resp['access_token']?.toString();

    dynamic userJson;
    if (resp.containsKey('user')) userJson = resp['user'];
    else if (resp.containsKey('data') && resp['data'] is Map && resp['data'].containsKey('user')) userJson = resp['data']['user'];
    else if (resp.containsKey('data') && resp['data'] is Map && (resp['data'].containsKey('id') || resp['data'].containsKey('email'))) userJson = resp['data'];
    else if (resp.containsKey('id') || resp.containsKey('email')) userJson = resp;

    if (token != null) {
      _api.setToken(token);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      if (userJson != null) await prefs.setString(_userKey, jsonEncode(userJson));
    }

    if (userJson != null) {
      return UserModel.fromJson(userJson);
    }
    return null;
  }

  /// Intenta cargar sesión desde SharedPreferences
  Future<UserModel?> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    final userStr = prefs.getString(_userKey);
    if (token == null) return null;
    _api.setToken(token);

    if (userStr != null) {
      try {
        final json = jsonDecode(userStr);
        return UserModel.fromJson(json);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  /// Cierra sesión localmente y en el backend
  Future<void> logout() async {
    // Llamar al endpoint de logout del backend
    try {
      await _api.post<Map<String, dynamic>>(
        'auth/logout',  // Ruta correcta según backend Laravel
        {},
        (json) => (json is Map<String, dynamic>) ? json : {},
      );
    } catch (e) {
      // Ignorar errores del backend, limpiar localmente de todos modos
    }

    _api.clearToken();
    SharedPreferences.getInstance().then((prefs) {
      prefs.remove(_tokenKey);
      prefs.remove(_userKey);
    });
  }

  /// Login con Google Sign-In
  Future<UserModel?> loginWithGoogle() async {
    try {
      // 1. Iniciar Google Sign-In
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );

      // 2. Seleccionar cuenta
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception('Inicio de sesión cancelado');
      }

      // 3. Obtener auth de Google
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 4. Crear credencial Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 5. Sign-in con Firebase
      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      // 6. Obtener token Firebase
      final firebaseToken = await userCredential.user?.getIdToken();

      if (firebaseToken == null) {
        throw Exception('Error al obtener token de Firebase');
      }

      // 7. Verificar con backend Laravel
      final Map<String, dynamic> resp = await _api.post<Map<String, dynamic>>(
        'firebase/verify',
        {'firebase_token': firebaseToken},
        (json) => (json is Map<String, dynamic>) ? json : <String, dynamic>{},
      );

      // 8. Extraer token Sanctum
      String? token;
      if (resp.containsKey('sanctum_token')) token = resp['sanctum_token']?.toString();
      else if (resp.containsKey('token')) token = resp['token']?.toString();
      else if (resp.containsKey('access_token')) token = resp['access_token']?.toString();

      // 9. Extraer usuario
      dynamic userJson;
      if (resp.containsKey('user')) userJson = resp['user'];
      else if (resp.containsKey('data') && resp['data'] is Map) {
        final data = resp['data'] as Map;
        if (data.containsKey('user')) userJson = data['user'];
        else userJson = data;
      }

      if (token != null) {
        _api.setToken(token);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, token);
        if (userJson != null) await prefs.setString(_userKey, jsonEncode(userJson));
      }

      if (userJson != null) {
        return UserModel.fromJson(userJson);
      }

      throw Exception('No se recibieron datos del usuario');
    } catch (e) {
      throw Exception('Error en Google Sign-In: ${e.toString()}');
    }
  }

  ApiService get api => _api;
}
