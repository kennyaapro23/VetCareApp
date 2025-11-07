import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final int? statusCode;
  final String message;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException(${statusCode ?? '-'}) $message';
}

class ApiService {
  final String baseUrl;
  String? _token;
  final Duration timeout;
  final int maxRetries;

  ApiService({String? baseUrl, this.timeout = const Duration(seconds: 10), this.maxRetries = 3})
      : baseUrl = baseUrl ?? _defaultBaseUrl();

  static String _defaultBaseUrl() {
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:8000/api/';
    } catch (_) {}
    return 'http://localhost:8000/api/';
  }

  void setToken(String token) => _token = token;
  void clearToken() => _token = null;

  Map<String, String> _headers({bool jsonContent = true}) {
    final headers = <String, String>{'Accept': 'application/json'};
    if (jsonContent) headers['Content-Type'] = 'application/json';
    if (_token != null) headers['Authorization'] = 'Bearer $_token';
    return headers;
  }

  Uri _uri(String path, [Map<String, String>? queryParameters]) {
    final uri = Uri.parse(baseUrl + path);
    if (queryParameters != null && queryParameters.isNotEmpty) {
      return uri.replace(queryParameters: queryParameters);
    }
    return uri;
  }

  Future<T> get<T>(String path, T Function(dynamic json) fromJson, {Map<String, String>? queryParameters}) async {
    final uri = _uri(path, queryParameters);
    return _retryRequest<T>(() => http.get(uri, headers: _headers(jsonContent: false)).timeout(timeout), fromJson);
  }

  Future<T> post<T>(String path, dynamic body, T Function(dynamic json) fromJson, {Map<String, String>? queryParameters}) async {
    final uri = _uri(path, queryParameters);
    final payload = jsonEncode(body);
    return _retryRequest<T>(() => http.post(uri, headers: _headers(), body: payload).timeout(timeout), fromJson);
  }

  Future<T> put<T>(String path, dynamic body, T Function(dynamic json) fromJson, {Map<String, String>? queryParameters}) async {
    final uri = _uri(path, queryParameters);
    final payload = jsonEncode(body);
    return _retryRequest<T>(() => http.put(uri, headers: _headers(), body: payload).timeout(timeout), fromJson);
  }

  Future<T> delete<T>(String path, T Function(dynamic json) fromJson, {Map<String, String>? queryParameters}) async {
    final uri = _uri(path, queryParameters);
    return _retryRequest<T>(() => http.delete(uri, headers: _headers(jsonContent: false)).timeout(timeout), fromJson);
  }

  Future<T> _retryRequest<T>(Future<http.Response> Function() requestFn, T Function(dynamic json) fromJson) async {
    var attempt = 0;
    while (true) {
      try {
        final res = await requestFn();

        if (res.statusCode >= 200 && res.statusCode < 300) {
          if (res.body.isEmpty) return fromJson(null);
          final data = jsonDecode(res.body);
          return fromJson(data);
        }

        // manejo de errores específicos
        if (res.statusCode == 401) {
          throw ApiException('No autorizado (401)', statusCode: 401);
        }

        // intenta extraer mensaje de error del body
        String message;
        try {
          final decoded = jsonDecode(res.body);
          if (decoded is Map && decoded.containsKey('message')) {
            message = decoded['message'].toString();
          } else {
            message = res.body;
          }
        } catch (_) {
          message = res.body;
        }

        // Para errores 5xx permitimos reintentos
        if (res.statusCode >= 500 && attempt < maxRetries - 1) {
          attempt++;
          final backoff = Duration(milliseconds: 500 * (1 << attempt));
          await Future.delayed(backoff);
          continue;
        }

        throw ApiException(message.isNotEmpty ? message : 'Error HTTP ${res.statusCode}', statusCode: res.statusCode);
      } on SocketException catch (e) {
        attempt++;
        if (attempt >= maxRetries) {
          throw ApiException('Error de red: ${e.message}');
        }
        await Future.delayed(Duration(milliseconds: 500 * (1 << attempt)));
        continue;
      } on TimeoutException catch (e) {
        attempt++;
        if (attempt >= maxRetries) {
          throw ApiException('Timeout: ${e.message}');
        }
        await Future.delayed(Duration(milliseconds: 500 * (1 << attempt)));
        continue;
      } catch (e) {
        // errores inesperados
        rethrow;
      }
    }
  }

  // ==================== MÉTODOS FIREBASE ====================

  /// Verificar token Firebase y sincronizar con Laravel
  Future<Map<String, dynamic>> verifyAndSync({
    required String firebaseToken,
    String? nombre,
    String? email,
    String? rol,
  }) async {
    try {
      final body = <String, dynamic>{
        'firebase_token': firebaseToken,
      };

      if (nombre != null) body['nombre'] = nombre;
      if (email != null) body['email'] = email;
      if (rol != null) body['rol'] = rol;

      return await post<Map<String, dynamic>>(
        'firebase/verify',
        body,
        (json) => json as Map<String, dynamic>,
      );
    } catch (e) {
      throw ApiException('Error al verificar token: $e');
    }
  }

  /// Registrar token FCM
  Future<void> registerFcmToken({
    required String sanctumToken,
    required String fcmToken,
  }) async {
    try {
      setToken(sanctumToken);
      await post<Map<String, dynamic>>(
        'firebase/fcm-token',
        {'fcm_token': fcmToken},
        (json) => (json as Map<String, dynamic>?) ?? {},
      );
    } catch (e) {
      print('❌ Error al registrar FCM token: $e');
    }
  }

  /// Obtener perfil del usuario
  Future<Map<String, dynamic>> getProfile(String sanctumToken) async {
    setToken(sanctumToken);
    return await get<Map<String, dynamic>>(
      'firebase/profile',
      (json) => json as Map<String, dynamic>,
    );
  }

  /// Actualizar perfil
  Future<Map<String, dynamic>> updateProfile({
    required String sanctumToken,
    String? nombre,
    String? telefono,
    String? direccion,
  }) async {
    setToken(sanctumToken);

    final body = <String, dynamic>{};
    if (nombre != null) body['nombre'] = nombre;
    if (telefono != null) body['telefono'] = telefono;
    if (direccion != null) body['direccion'] = direccion;

    return await put<Map<String, dynamic>>(
      'firebase/profile',
      body,
      (json) => json as Map<String, dynamic>,
    );
  }

  /// Cerrar sesión
  Future<void> logout(String sanctumToken) async {
    setToken(sanctumToken);
    await post<Map<String, dynamic>>(
      'firebase/logout',
      {},
      (json) => (json as Map<String, dynamic>?) ?? {},
    );
    clearToken();
  }
}
