import 'package:vetcare_app/models/pet_model.dart';
import 'package:vetcare_app/services/api_service.dart';

class PetService {
  final ApiService _api;

  PetService(this._api);

  Future<List<PetModel>> getPets() async {
    final resp = await _api.get<dynamic>(
      'mascotas',
      (json) => json,
    );

    // Manejar respuesta paginada de Laravel
    List<dynamic> dataList;
    if (resp is Map && resp.containsKey('data')) {
      // Respuesta paginada: {"current_page": 1, "data": [...]}
      dataList = (resp['data'] is List) ? resp['data'] : [];
    } else if (resp is List) {
      // Respuesta directa: [...]
      dataList = resp;
    } else {
      dataList = [];
    }

    return dataList.map((e) => PetModel.fromJson(e)).toList();
  }

  Future<PetModel> getPet(String id) async {
    final resp = await _api.get<Map<String, dynamic>>(
      'mascotas/$id',
      (json) => (json is Map<String, dynamic>) ? json : {},
    );
    return PetModel.fromJson(resp);
  }

  Future<PetModel> createPet(Map<String, dynamic> data) async {
    final resp = await _api.post<Map<String, dynamic>>(
      'mascotas',
      data,
      (json) => (json is Map<String, dynamic>) ? json : {},
    );
    return PetModel.fromJson(resp);
  }

  Future<PetModel> updatePet(String id, Map<String, dynamic> data) async {
    final resp = await _api.put<Map<String, dynamic>>(
      'mascotas/$id',
      data,
      (json) => (json is Map<String, dynamic>) ? json : {},
    );
    return PetModel.fromJson(resp);
  }

  Future<void> deletePet(String id) async {
    await _api.delete<Map<String, dynamic>>(
      'mascotas/$id',
      (json) => (json is Map<String, dynamic>) ? json : {},
    );
  }
}
