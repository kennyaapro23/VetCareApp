import 'package:vetcare_app/services/api_service.dart';

class QRService {
  final ApiService _api;

  QRService(this._api);

  /// Busca información usando el token QR
  Future<Map<String, dynamic>> searchByQR(String token) async {
    final resp = await _api.get<Map<String, dynamic>>(
      'qr/lookup/$token',
      (json) => (json is Map<String, dynamic>) ? json : {},
    );
    return resp;
  }

  /// Genera QR para una mascota
  Future<Map<String, dynamic>> generatePetQR(String petId) async {
    final resp = await _api.get<Map<String, dynamic>>(
      'mascotas/$petId/qr',
      (json) => (json is Map<String, dynamic>) ? json : {},
    );
    return resp;
  }

  /// Genera QR para un cliente
  Future<Map<String, dynamic>> generateClientQR(String clientId) async {
    final resp = await _api.get<Map<String, dynamic>>(
      'clientes/$clientId/qr',
      (json) => (json is Map<String, dynamic>) ? json : {},
    );
    return resp;
  }
}
