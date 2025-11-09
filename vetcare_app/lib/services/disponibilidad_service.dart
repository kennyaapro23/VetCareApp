import 'package:vetcare_app/services/api_service.dart';
import 'package:vetcare_app/models/agenda_disponibilidad.dart';

class DisponibilidadService {
  final ApiService _api;

  DisponibilidadService(this._api);

  Future<List<AgendaDisponibilidad>> getDisponibilidad(String veterinarioId) async {
    final resp = await _api.get<dynamic>(
      'veterinarios/$veterinarioId/horarios',
      (json) => json,
    );

    List<dynamic> dataList;
    if (resp is Map && resp.containsKey('horarios')) {
      // Backend devuelve: { "horarios": [...] }
      dataList = (resp['horarios'] is List) ? resp['horarios'] : [];
    } else if (resp is Map && resp.containsKey('data')) {
      dataList = (resp['data'] is List) ? resp['data'] : [];
    } else if (resp is List) {
      dataList = resp;
    } else {
      dataList = [];
    }

    return dataList.map((e) => AgendaDisponibilidad.fromJson(e)).toList();
  }

  /// Agregar UN horario individual
  /// Endpoint: POST /api/veterinarios/{id}/horarios
  Future<AgendaDisponibilidad> createDisponibilidad(
    String veterinarioId,
    Map<String, dynamic> data,
  ) async {
    final resp = await _api.post<dynamic>(
      'veterinarios/$veterinarioId/horarios', // ⭐ Cambio de endpoint
      data,
      (json) => json,
    );

    // Extraer el horario de la respuesta
    dynamic horarioData;
    if (resp is Map && resp.containsKey('horario')) {
      horarioData = resp['horario'];
    } else if (resp is Map && resp.containsKey('data')) {
      horarioData = resp['data'];
    } else if (resp is Map) {
      horarioData = resp;
    } else {
      throw Exception('Formato de respuesta inesperado del servidor');
    }

    return AgendaDisponibilidad.fromJson(horarioData);
  }

  /// Actualizar un horario existente
  /// Endpoint: PUT /api/veterinarios/{veterinarioId}/horarios/{horarioId}
  Future<AgendaDisponibilidad> updateDisponibilidad(
    String veterinarioId,
    String horarioId,
    Map<String, dynamic> data,
  ) async {
    final resp = await _api.put<dynamic>(
      'veterinarios/$veterinarioId/horarios/$horarioId', // ⭐ Cambio
      data,
      (json) => json,
    );

    dynamic horarioData;
    if (resp is Map && resp.containsKey('horario')) {
      horarioData = resp['horario'];
    } else if (resp is Map && resp.containsKey('data')) {
      horarioData = resp['data'];
    } else if (resp is Map) {
      horarioData = resp;
    } else {
      throw Exception('Formato de respuesta inesperado');
    }

    return AgendaDisponibilidad.fromJson(horarioData);
  }

  /// Activar/Desactivar horario (usa GET por limitación de ApiService)
  /// Endpoint real: PATCH /api/veterinarios/{veterinarioId}/horarios/{horarioId}/toggle
  Future<void> toggleDisponibilidad(
    String veterinarioId,
    String horarioId,
    bool disponible,
  ) async {
    // Nota: ApiService no tiene método PATCH, el backend debe aceptar GET en /toggle
    await _api.get<dynamic>(
      'veterinarios/$veterinarioId/horarios/$horarioId/toggle', // ⭐ Cambio
      (json) => json,
    );
  }

  /// Eliminar un horario
  /// Endpoint: DELETE /api/veterinarios/{veterinarioId}/horarios/{horarioId}
  Future<void> deleteDisponibilidad(
    String veterinarioId,
    String horarioId,
  ) async {
    await _api.delete<dynamic>(
      'veterinarios/$veterinarioId/horarios/$horarioId', // ⭐ Cambio de endpoint
      (json) => json,
    );
  }
}

