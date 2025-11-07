import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:vetcare_app/models/user.dart';
import 'package:vetcare_app/services/api_service.dart';

class AuthService {
  final ApiService _api = ApiService();
  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user';

  /// Intenta autenticar contra [auth/login].
  /// Espera respuestas tipo Laravel: { token: "...", user: { ... } } o { access_token: "...", user: { ... } }
  Future<UserModel?> login({required String email, required String password}) async {
    final body = {'email': email, 'password': password};

    final Map<String, dynamic> resp = await _api.post<Map<String, dynamic>>(
      'auth/login',
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

  /// Registro de usuario: POST a auth/register
  Future<UserModel?> register(Map<String, dynamic> data) async {
    final Map<String, dynamic> resp = await _api.post<Map<String, dynamic>>(
      'auth/register',
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
        'auth/logout',
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

  ApiService get api => _api;
}
