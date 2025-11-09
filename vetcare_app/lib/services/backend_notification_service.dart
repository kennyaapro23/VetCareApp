import 'package:vetcare_app/services/api_service.dart';

class BackendNotificationService {
  final ApiService _api;

  BackendNotificationService(this._api);

  // GET /notificaciones
  Future<List<dynamic>> getNotificaciones() async {
    final resp = await _api.get<dynamic>(
      'notificaciones',
      (json) => json,
    );

    if (resp is Map && resp.containsKey('data')) {
      return (resp['data'] is List) ? resp['data'] : [];
    } else if (resp is List) {
      return resp;
    }
    return [];
  }

  // GET /notificaciones/tipos
  Future<List<String>> getTipos() async {
    final resp = await _api.get<dynamic>(
      'notificaciones/tipos',
      (json) => json,
    );

    if (resp is List) {
      return resp.map((e) => e.toString()).toList();
    }
    return [];
  }

  // GET /notificaciones/unread-count
  Future<int> getUnreadCount() async {
    final resp = await _api.get<Map<String, dynamic>>(
      'notificaciones/unread-count',
      (json) => (json is Map<String, dynamic>) ? json : {},
    );
    return resp['count'] ?? 0;
  }

  // POST /notificaciones/mark-all-read
  Future<void> markAllAsRead() async {
    await _api.post<Map<String, dynamic>>(
      'notificaciones/mark-all-read',
      {},
      (json) => (json is Map<String, dynamic>) ? json : {},
    );
  }

  // DELETE /notificaciones/delete-read
  Future<void> deleteRead() async {
    await _api.delete<Map<String, dynamic>>(
      'notificaciones/delete-read',
      (json) => (json is Map<String, dynamic>) ? json : {},
    );
  }

  // GET /notificaciones/{id}
  Future<Map<String, dynamic>> getNotificacion(String id) async {
    final resp = await _api.get<Map<String, dynamic>>(
      'notificaciones/$id',
      (json) => (json is Map<String, dynamic>) ? json : {},
    );
    return resp;
  }

  // POST /notificaciones/{id}/mark-read
  Future<void> markAsRead(String id) async {
    await _api.post<Map<String, dynamic>>(
      'notificaciones/$id/mark-read',
      {},
      (json) => (json is Map<String, dynamic>) ? json : {},
    );
  }

  // DELETE /notificaciones/{id}
  Future<void> deleteNotificacion(String id) async {
    await _api.delete<Map<String, dynamic>>(
      'notificaciones/$id',
      (json) => (json is Map<String, dynamic>) ? json : {},
    );
  }
}

