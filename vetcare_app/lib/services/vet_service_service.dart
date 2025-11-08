import 'package:vetcare_app/models/service_model.dart';
import 'package:vetcare_app/services/api_service.dart';

class VetServiceService {
  final ApiService _api;

  VetServiceService(this._api);

  Future<List<ServiceModel>> getServices() async {
    final resp = await _api.get<List<dynamic>>(
      'servicios',
      (json) => (json is List) ? json : [],
    );
    return resp.map((e) => ServiceModel.fromJson(e)).toList();
  }

  // TODO: Esta ruta no existe en el backend Laravel
  // Opción 1: Filtrar localmente después de obtener todos los servicios
  // Opción 2: Agregar endpoint en backend: GET /api/mascotas/{id}/servicios
  Future<List<ServiceModel>> getServicesByPet(String petId) async {
    // Por ahora, obtenemos todos los servicios y filtramos localmente
    final allServices = await getServices();
    // Si el modelo tiene un campo 'mascotaId', filtrar aquí
    // return allServices.where((s) => s.mascotaId == petId).toList();
    return allServices; // Retorna todos por ahora
  }

  Future<ServiceModel> createService(Map<String, dynamic> data) async {
    final resp = await _api.post<Map<String, dynamic>>(
      'servicios',
      data,
      (json) => (json is Map<String, dynamic>) ? json : {},
    );
    return ServiceModel.fromJson(resp);
  }

  Future<List<String>> getServiceTypes() async {
    final resp = await _api.get<List<dynamic>>(
      'servicios-tipos',
      (json) => (json is List) ? json : [],
    );
    return resp.map((e) => e.toString()).toList();
  }
}
