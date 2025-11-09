  import 'package:vetcare_app/models/catalog_service_model.dart';
import 'package:vetcare_app/services/api_service.dart';

class ServiceService {
  final ApiService _api;

  ServiceService(this._api);

  Future<List<CatalogServiceModel>> getServices() async {
    final resp = await _api.get<List<dynamic>>(
      'services',
      (json) => (json is List) ? json : [],
    );
    return resp.map((e) => CatalogServiceModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<CatalogServiceModel> getService(String id) async {
    final resp = await _api.get<Map<String, dynamic>>(
      'services/$id',
      (json) => (json is Map<String, dynamic>) ? json : {},
    );
    return CatalogServiceModel.fromJson(resp);
  }

  Future<CatalogServiceModel> createService(Map<String, dynamic> data) async {
    final resp = await _api.post<Map<String, dynamic>>(
      'services',
      data,
      (json) => (json is Map<String, dynamic>) ? json : {},
    );
    return CatalogServiceModel.fromJson(resp);
  }

  Future<CatalogServiceModel> updateService(String id, Map<String, dynamic> data) async {
    final resp = await _api.put<Map<String, dynamic>>(
      'services/$id',
      data,
      (json) => (json is Map<String, dynamic>) ? json : {},
    );
    return CatalogServiceModel.fromJson(resp);
  }

  Future<void> deleteService(String id) async {
    await _api.delete<Map<String, dynamic>>(
      'services/$id',
      (json) => (json is Map<String, dynamic>) ? json : {},
    );
  }
}

