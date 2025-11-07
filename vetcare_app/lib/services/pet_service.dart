import 'package:vetcare_app/models/pet_model.dart';
import 'package:vetcare_app/services/api_service.dart';

class PetService {
  final ApiService _api;

  PetService(this._api);

  Future<List<PetModel>> getPets() async {
    final resp = await _api.get<List<dynamic>>(
      'mascotas',
      (json) => (json is List) ? json : [],
    );
    return resp.map((e) => PetModel.fromJson(e)).toList();
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

