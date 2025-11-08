import 'package:flutter/material.dart';
import 'package:vetcare_app/models/user.dart';
import 'package:vetcare_app/services/hybrid_auth_service.dart';
import 'package:vetcare_app/services/api_service.dart';
import 'package:vetcare_app/services/notification_service.dart';

class AuthProvider extends ChangeNotifier {
  final HybridAuthService _service = HybridAuthService();
  UserModel? user;
  bool isLoading = false;
  String? error;

  AuthProvider() {
    // iniciar intento de sesión automática
    init();
  }

  Future<void> init() async {
    isLoading = true;
    notifyListeners();
    debugPrint('🔄 AuthProvider.init() - iniciando...');
    try {
      // Agregar timeout de 5 segundos para evitar quedarse atascado
      final u = await _service.tryAutoLogin().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('⏱️ Timeout en auto-login, continuando sin sesión');
          return null;
        },
      );
      user = u;
      debugPrint('✅ Auto-login completado: ${u != null ? "Usuario encontrado: ${u.email}" : "Sin sesión guardada"}');
    } catch (e) {
      debugPrint('⚠️ Error en auto-login: $e');
      user = null;
    } finally {
      isLoading = false;
      debugPrint('✅ Init completado, isLoading = $isLoading, user = ${user?.email}');
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final result = await _service.login(email: email, password: password);
      isLoading = false;
      if (result != null) {
        user = result;
        notifyListeners();
        return true;
      } else {
        error = 'Credenciales inválidas';
        notifyListeners();
        return false;
      }
    } catch (e) {
      isLoading = false;
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(Map<String, dynamic> data) async {
    isLoading = true;
    error = null;
    notifyListeners();
    debugPrint('📝 AuthProvider.register() - iniciando registro para ${data['email']}');
    try {
      final result = await _service.register(data);
      isLoading = false;
      if (result != null) {
        user = result;
        debugPrint('✅ Registro exitoso en AuthProvider, usuario: ${result.email}');
        notifyListeners();
        return true;
      } else {
        error = 'Registro fallido';
        debugPrint('❌ Registro falló: sin resultado');
        notifyListeners();
        return false;
      }
    } catch (e) {
      isLoading = false;
      error = e.toString();
      debugPrint('❌ Error en registro: $e');
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    isLoading = true;
    notifyListeners();

    // Eliminar token FCM del backend
    try {
      await NotificationService.deleteFcmToken();
    } catch (e) {
      // Ignorar errores
    }

    await _service.logout();
    user = null;
    isLoading = false;
    notifyListeners();
  }

  ApiService get api => _service.api;
}
