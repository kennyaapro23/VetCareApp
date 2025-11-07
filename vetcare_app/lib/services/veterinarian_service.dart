import 'package:vetcare_app/models/veterinarian_model.dart';
import 'package:vetcare_app/services/api_service.dart';

class VeterinarianService {
  final ApiService _api;

  VeterinarianService(this._api);

  Future<List<VeterinarianModel>> getVeterinarians() async {
    final resp = await _api.get<List<dynamic>>(
      'veterinarios',
      (json) => (json is List) ? json : [],
    );
    return resp.map((e) => VeterinarianModel.fromJson(e)).toList();
  }

  Future<VeterinarianModel> getVeterinarian(String id) async {
    final resp = await _api.get<Map<String, dynamic>>(
      'veterinarios/$id',
      (json) => (json is Map<String, dynamic>) ? json : {},
    );
    return VeterinarianModel.fromJson(resp);
  }

  Future<Map<String, dynamic>> getAvailability(String id) async {
    final resp = await _api.get<Map<String, dynamic>>(
      'veterinarios/$id/disponibilidad',
      (json) => (json is Map<String, dynamic>) ? json : {},
    );
    return resp;
  }

  Future<void> setAvailability(String id, Map<String, dynamic> data) async {
    await _api.post<Map<String, dynamic>>(
      'veterinarios/$id/disponibilidad',
      data,
      (json) => (json is Map<String, dynamic>) ? json : {},
    );
  }
}

