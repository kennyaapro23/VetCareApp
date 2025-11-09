import 'package:vetcare_app/services/api_service.dart';
import 'package:vetcare_app/models/veterinarian_model.dart';

class VeterinarianService {
  final ApiService _api;

  VeterinarianService(this._api);

  Future<List<VeterinarianModel>> getVeterinarians() async {
    final resp = await _api.get<dynamic>(
      'veterinarios',
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

    return dataList.map((e) => VeterinarianModel.fromJson(e)).toList();
  }

  Future<VeterinarianModel> getVeterinarian(String id) async {
    final resp = await _api.get<Map<String, dynamic>>(
      'veterinarios/$id',
      (json) => (json is Map<String, dynamic>) ? json : {},
    );
    return VeterinarianModel.fromJson(resp);
  }

  Future<void> setDisponibilidad(String id, List<Map<String, dynamic>> disponibilidad) async {
    await _api.post<Map<String, dynamic>>(
      'veterinarios/$id/disponibilidad',
      {'disponibilidad': disponibilidad},
      (json) => (json is Map<String, dynamic>) ? json : {},
    );
  }
}
