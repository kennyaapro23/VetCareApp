import 'package:vetcare_app/models/appointment_model.dart';
import 'package:vetcare_app/services/api_service.dart';

class AppointmentService {
  final ApiService _api;

  AppointmentService(this._api);

  Future<List<AppointmentModel>> getAppointments({String? status}) async {
    final params = status != null ? {'estado': status} : null;
    final resp = await _api.get<dynamic>(
      'citas',
      (json) => json,
      queryParameters: params,
    );
    
    // Manejar respuesta paginada: {"current_page":1,"data":[...]}
    List<dynamic> items;
    if (resp is Map && resp.containsKey('data')) {
      items = resp['data'] as List<dynamic>;
    } else if (resp is List) {
      items = resp;
    } else {
      items = [];
    }
    
    return items.map((e) => AppointmentModel.fromJson(e)).toList();
  }

  Future<AppointmentModel> createAppointment(Map<String, dynamic> data) async {
    final resp = await _api.post<Map<String, dynamic>>(
      'citas',
      data,
      (json) => (json is Map<String, dynamic>) ? json : {},
    );
    return AppointmentModel.fromJson(resp);
  }

  Future<void> cancelAppointment(String id) async {
    await _api.put<Map<String, dynamic>>(
      'citas/$id',
      {'estado': 'cancelada'},
      (json) => (json is Map<String, dynamic>) ? json : {},
    );
  }
}

