import 'package:vetcare_app/models/servicio.dart';
import 'package:vetcare_app/services/api_service.dart';

class ServicioService {
  final ApiService _api;

  ServicioService(this._api);

  /// Obtener lista de servicios con filtro opcional por tipo
  Future<List<Servicio>> getServicios({String? tipo}) async {
    final params = <String, String>{};
    if (tipo != null) params['tipo'] = tipo;

    final resp = await _api.get<List<dynamic>>(
      'servicios',
      (json) => (json is List) ? json : [],
      queryParameters: params.isNotEmpty ? params : null,
    );
    return resp.map((e) => Servicio.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Obtener un servicio específico por ID
  Future<Servicio> getServicio(int id) async {
    final resp = await _api.get<Map<String, dynamic>>(
      'servicios/$id',
      (json) => (json is Map<String, dynamic>) ? json : {},
    );
    return Servicio.fromJson(resp);
  }

  /// Crear un nuevo servicio (solo admin)
  Future<Servicio> createServicio(Map<String, dynamic> data) async {
    final resp = await _api.post<Map<String, dynamic>>(
      'servicios',
      data,
      (json) => (json is Map<String, dynamic>) ? json : {},
    );
    return Servicio.fromJson(resp);
  }

  /// Actualizar servicio existente (solo admin)
  Future<Servicio> updateServicio(int id, Map<String, dynamic> data) async {
    final resp = await _api.put<Map<String, dynamic>>(
      'servicios/$id',
      data,
      (json) => (json is Map<String, dynamic>) ? json : {},
    );
    return Servicio.fromJson(resp);
  }

  /// Eliminar servicio (solo admin)
  Future<void> deleteServicio(int id) async {
    await _api.delete<Map<String, dynamic>>(
      'servicios/$id',
      (json) => (json is Map<String, dynamic>) ? json : {},
    );
  }

  /// Obtener tipos de servicios disponibles
  Future<List<String>> getTiposServicios() async {
    // Los tipos según el backend son: vacuna, tratamiento, baño, consulta, cirugía, otro
    return ['vacuna', 'tratamiento', 'baño', 'consulta', 'cirugía', 'otro'];
  }
}

