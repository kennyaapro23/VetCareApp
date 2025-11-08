import 'package:vetcare_app/models/agenda_disponibilidad.dart';
import 'package:vetcare_app/services/api_service.dart';

class DisponibilidadService {
  final ApiService _api;

  DisponibilidadService(this._api);

  Future<List<AgendaDisponibilidad>> getDisponibilidad(String veterinarioId) async {
    final resp = await _api.get<List<dynamic>>(
      'veterinarios/$veterinarioId/disponibilidad',
      (json) => (json is List) ? json : [],
    );
    return resp.map((e) => AgendaDisponibilidad.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<AgendaDisponibilidad> crearDisponibilidad(String veterinarioId, Map<String, dynamic> data) async {
    final resp = await _api.post<Map<String, dynamic>>(
      'veterinarios/$veterinarioId/disponibilidad',
      data,
      (json) => (json is Map<String, dynamic>) ? json : {},
    );
    return AgendaDisponibilidad.fromJson(resp);
  }

  Future<AgendaDisponibilidad> actualizarDisponibilidad(String veterinarioId, String id, Map<String, dynamic> data) async {
    final resp = await _api.put<Map<String, dynamic>>(
      'veterinarios/$veterinarioId/disponibilidad/$id',
      data,
      (json) => (json is Map<String, dynamic>) ? json : {},
    );
    return AgendaDisponibilidad.fromJson(resp);
  }

  Future<void> eliminarDisponibilidad(String veterinarioId, String id) async {
    await _api.delete<Map<String, dynamic>>(
      'veterinarios/$veterinarioId/disponibilidad/$id',
      (json) => (json is Map<String, dynamic>) ? json : {},
    );
  }
}

