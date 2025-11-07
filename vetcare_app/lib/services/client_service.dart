import 'package:vetcare_app/models/client_model.dart';
import 'package:vetcare_app/services/api_service.dart';

class ClientService {
  final ApiService _api;

  ClientService(this._api);

  Future<List<ClientModel>> getClients() async {
    final resp = await _api.get<List<dynamic>>(
      'clientes',
      (json) => (json is List) ? json : [],
    );
    return resp.map((e) => ClientModel.fromJson(e)).toList();
  }

  Future<ClientModel> getClient(String id) async {
    final resp = await _api.get<Map<String, dynamic>>(
      'clientes/$id',
      (json) => (json is Map<String, dynamic>) ? json : {},
    );
    return ClientModel.fromJson(resp);
  }

  Future<ClientModel> createClient(Map<String, dynamic> data) async {
    final resp = await _api.post<Map<String, dynamic>>(
      'clientes',
      data,
      (json) => (json is Map<String, dynamic>) ? json : {},
    );
    return ClientModel.fromJson(resp);
  }

  Future<ClientModel> updateClient(String id, Map<String, dynamic> data) async {
    final resp = await _api.put<Map<String, dynamic>>(
      'clientes/$id',
      data,
      (json) => (json is Map<String, dynamic>) ? json : {},
    );
    return ClientModel.fromJson(resp);
  }

  Future<void> deleteClient(String id) async {
    await _api.delete<Map<String, dynamic>>(
      'clientes/$id',
      (json) => (json is Map<String, dynamic>) ? json : {},
    );
  }
}

