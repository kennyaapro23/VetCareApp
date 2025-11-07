import 'package:flutter/material.dart';
import 'package:vetcare_app/models/user.dart';
import 'package:vetcare_app/services/auth_service.dart';
import 'package:vetcare_app/services/api_service.dart';
import 'package:vetcare_app/services/notification_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _service = AuthService();
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
    try {
      final u = await _service.tryAutoLogin();
      user = u;
    } catch (_) {
      user = null;
    } finally {
      isLoading = false;
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
    try {
      final result = await _service.register(data);
      isLoading = false;
      if (result != null) {
        user = result;
        notifyListeners();
        return true;
      } else {
        error = 'Registro fallido';
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

  Future<void> logout() async {
    isLoading = true;
    notifyListeners();

    // Eliminar token FCM del backend
    try {
      await NotificationService.deleteFcmToken();
    } catch (e) {
      // Ignorar errores
    }

    _service.logout();
    user = null;
    isLoading = false;
    notifyListeners();
  }

  ApiService get api => _service.api;
}
