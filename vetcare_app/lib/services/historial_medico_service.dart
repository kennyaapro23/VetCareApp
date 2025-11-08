import 'package:vetcare_app/models/historial_medico.dart';
import 'package:vetcare_app/services/api_service.dart';

class HistorialMedicoService {
  final ApiService _api;

  HistorialMedicoService(this._api);

  Future<List<HistorialMedico>> getHistorial({int? mascotaId, String? tipo}) async {
    final params = <String, String>{};
    if (mascotaId != null) params['mascota_id'] = mascotaId.toString();
    if (tipo != null) params['tipo'] = tipo;

    final resp = await _api.get<List<dynamic>>(
      'historial-medico',
      (json) => (json is List) ? json : [],
      queryParameters: params.isNotEmpty ? params : null,
    );
    return resp.map((e) => HistorialMedico.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<HistorialMedico> getRegistro(String id) async {
    final resp = await _api.get<Map<String, dynamic>>(
      'historial-medico/$id',
      (json) => (json is Map<String, dynamic>) ? json : {},
    );
    return HistorialMedico.fromJson(resp);
  }

  Future<HistorialMedico> crearRegistro(Map<String, dynamic> data) async {
    final resp = await _api.post<Map<String, dynamic>>(
      'historial-medico',
      data,
      (json) => (json is Map<String, dynamic>) ? json : {},
    );
    return HistorialMedico.fromJson(resp);
  }

  Future<HistorialMedico> actualizarRegistro(String id, Map<String, dynamic> data) async {
    final resp = await _api.put<Map<String, dynamic>>(
      'historial-medico/$id',
      data,
      (json) => (json is Map<String, dynamic>) ? json : {},
    );
    return HistorialMedico.fromJson(resp);
  }

  Future<void> eliminarRegistro(String id) async {
    await _api.delete<Map<String, dynamic>>(
      'historial-medico/$id',
      (json) => (json is Map<String, dynamic>) ? json : {},
    );
  }
}

