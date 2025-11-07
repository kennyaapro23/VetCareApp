import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vetcare_app/services/api_service.dart';
import 'dart:convert';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static const _notificationsKey = 'local_notifications';
  static ApiService? _api;

  static void setApiService(ApiService api) {
    _api = api;
  }

  static Future<void> initialize() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final token = await _messaging.getToken();
    debugPrint('FCM Token: $token');

    // Guardar token en el backend
    if (token != null && _api != null) {
      try {
        await _api?.post<Map<String, dynamic>>(
          'fcm-token',
          {'token': token},
          (json) => (json is Map<String, dynamic>) ? json : {},
        );
      } catch (e) {
        debugPrint('Error guardando FCM token: $e');
      }
    }

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Mensaje recibido: ${message.notification?.title}');
    _saveLocalNotification(message);
  }

  static void _handleBackgroundMessage(RemoteMessage message) {
    debugPrint('Mensaje abierto desde background: ${message.notification?.title}');
  }

  static Future<void> _saveLocalNotification(RemoteMessage message) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_notificationsKey) ?? [];

    final notification = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': message.notification?.title ?? '',
      'body': message.notification?.body ?? '',
      'date': DateTime.now().toIso8601String(),
      'data': message.data,
    };

    existing.insert(0, jsonEncode(notification));
    if (existing.length > 50) existing.removeLast();

    await prefs.setStringList(_notificationsKey, existing);
  }

  static Future<List<Map<String, dynamic>>> getLocalNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_notificationsKey) ?? [];
    return list.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
  }

  static Future<void> clearNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_notificationsKey);
  }

  /// Obtiene notificaciones del backend
  static Future<List<Map<String, dynamic>>> getNotifications() async {
    if (_api == null) return [];
    try {
      final resp = await _api!.get<List<dynamic>>(
        'notificaciones',
        (json) => (json is List) ? json : [],
      );
      return resp.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      debugPrint('Error obteniendo notificaciones: $e');
      return [];
    }
  }

  /// Marca todas las notificaciones como leídas
  static Future<void> markAllAsRead() async {
    if (_api == null) return;
    try {
      await _api!.post<Map<String, dynamic>>(
        'notificaciones/mark-all-read',
        {},
        (json) => (json is Map<String, dynamic>) ? json : {},
      );
    } catch (e) {
      debugPrint('Error marcando notificaciones como leídas: $e');
    }
  }

  /// Obtiene el conteo de notificaciones no leídas
  static Future<int> getUnreadCount() async {
    if (_api == null) return 0;
    try {
      final resp = await _api!.get<Map<String, dynamic>>(
        'notificaciones/unread-count',
        (json) => (json is Map<String, dynamic>) ? json : {},
      );
      return resp['count'] as int? ?? 0;
    } catch (e) {
      debugPrint('Error obteniendo conteo de no leídas: $e');
      return 0;
    }
  }

  /// Elimina el token FCM del backend al hacer logout
  static Future<void> deleteFcmToken() async {
    if (_api == null) return;
    try {
      await _api!.delete<Map<String, dynamic>>(
        'fcm-token',
        (json) => (json is Map<String, dynamic>) ? json : {},
      );
    } catch (e) {
      debugPrint('Error eliminando FCM token: $e');
    }
  }
}
