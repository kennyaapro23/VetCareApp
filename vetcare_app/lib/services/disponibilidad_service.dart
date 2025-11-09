import 'package:vetcare_app/services/api_service.dart';
import 'package:vetcare_app/models/agenda_disponibilidad.dart';

class DisponibilidadService {
  final ApiService _api;

  DisponibilidadService(this._api);

  Future<List<AgendaDisponibilidad>> getDisponibilidad(String veterinarioId) async {
    final resp = await _api.get<dynamic>(
      'veterinarios/$veterinarioId/disponibilidad',
      (json) => json,
    );

    List<dynamic> dataList;
    if (resp is Map && resp.containsKey('data')) {
      dataList = (resp['data'] is List) ? resp['data'] : [];
    } else if (resp is List) {
      dataList = resp;
    } else {
      dataList = [];
    }

    return dataList.map((e) => AgendaDisponibilidad.fromJson(e)).toList();
  }

  Future<AgendaDisponibilidad> createDisponibilidad(
    String veterinarioId,
    Map<String, dynamic> data,
  ) async {
    final resp = await _api.post<dynamic>(
      'veterinarios/$veterinarioId/disponibilidad',
      data,
      (json) => json,
    );

    // El backend puede devolver un array de horarios o un objeto
    dynamic horarioData;
    if (resp is Map && resp.containsKey('data')) {
      horarioData = resp['data'];
    } else {
      horarioData = resp;
    }

    // Si es un array, tomar el primer elemento
    if (horarioData is List && horarioData.isNotEmpty) {
      return AgendaDisponibilidad.fromJson(horarioData[0]);
    } else if (horarioData is Map) {
      return AgendaDisponibilidad.fromJson(horarioData);
    }

    throw Exception('Formato de respuesta inesperado del servidor');
  }

  Future<AgendaDisponibilidad> updateDisponibilidad(
    String veterinarioId,
    String horarioId,
    Map<String, dynamic> data,
  ) async {
    final resp = await _api.put<Map<String, dynamic>>(
      'veterinarios/$veterinarioId/disponibilidad/$horarioId',
      data,
      (json) => json as Map<String, dynamic>,
    );

    final horarioData = resp['data'] ?? resp;
    return AgendaDisponibilidad.fromJson(horarioData);
  }

  Future<void> toggleDisponibilidad(
    String veterinarioId,
    String horarioId,
    bool disponible,
  ) async {
    await _api.put<Map<String, dynamic>>(
      'veterinarios/$veterinarioId/disponibilidad/$horarioId',
      {'disponible': disponible},
      (json) => json as Map<String, dynamic>,
    );
  }

  Future<void> deleteDisponibilidad(
    String veterinarioId,
    String horarioId,
  ) async {
    await _api.delete<Map<String, dynamic>>(
      'veterinarios/$veterinarioId/disponibilidad/$horarioId',
      (json) => json as Map<String, dynamic>,
    );
  }
}

