import 'package:vetcare_app/services/api_service.dart';
import 'package:vetcare_app/models/pet_model.dart';
import 'package:vetcare_app/models/historial_medico.dart';

class QRService {
  final ApiService _api;

  QRService(this._api);

  /// 🔍 Busca información usando el token QR escaneado
  Future<Map<String, dynamic>> searchByQR(String token) async {
    final resp = await _api.get<Map<String, dynamic>>(
      'qr/lookup/$token',
      (json) => (json is Map<String, dynamic>) ? json : {},
    );
    return resp;
  }

  /// 📱 Genera QR único para una mascota
  Future<Map<String, dynamic>> generatePetQR(String petId) async {
    final resp = await _api.get<Map<String, dynamic>>(
      'mascotas/$petId/qr',
      (json) => (json is Map<String, dynamic>) ? json : {},
    );
    return resp;
  }

  /// 👤 Genera QR para un cliente
  Future<Map<String, dynamic>> generateClientQR(String clientId) async {
    final resp = await _api.get<Map<String, dynamic>>(
      'clientes/$clientId/qr',
      (json) => (json is Map<String, dynamic>) ? json : {},
    );
    return resp;
  }

  /// 🐾 Obtiene el perfil completo de mascota por QR escaneado
  Future<PetModel?> getPetByQR(String qrCode) async {
    try {
      final response = await searchByQR(qrCode);

      if (response['success'] == true && response['pet'] != null) {
        return PetModel.fromJson(response['pet']);
      }

      return null;
    } catch (e) {
      print('❌ Error obteniendo mascota por QR: $e');
      return null;
    }
  }

  /// 📋 Obtiene el historial médico completo por QR de mascota
  Future<List<HistorialMedico>> getMedicalHistoryByQR(String qrCode) async {
    try {
      final response = await searchByQR(qrCode);

      if (response['success'] == true && response['historial'] != null) {
        final historialList = response['historial'] as List;
        return historialList.map((item) => HistorialMedico.fromJson(item)).toList();
      }

      return [];
    } catch (e) {
      print('❌ Error obteniendo historial por QR: $e');
      return [];
    }
  }

  /// 🆘 Obtiene información de emergencia por QR (nombre dueño, teléfono, alergias)
  Future<Map<String, dynamic>> getEmergencyInfoByQR(String qrCode) async {
    try {
      final response = await searchByQR(qrCode);

      if (response['success'] == true) {
        return {
          'pet_name': response['pet']?['nombre'] ?? 'N/A',
          'owner_name': response['owner']?['nombre'] ?? 'N/A',
          'owner_phone': response['owner']?['telefono'] ?? 'N/A',
          'owner_email': response['owner']?['email'] ?? 'N/A',
          'allergies': response['pet']?['alergias'] ?? 'Ninguna',
          'medical_conditions': response['pet']?['condiciones_medicas'] ?? 'Ninguna',
          'chip_id': response['pet']?['microchip'] ?? 'N/A',
          'blood_type': response['pet']?['tipo_sangre'] ?? 'N/A',
        };
      }

      return {};
    } catch (e) {
      print('❌ Error obteniendo info de emergencia por QR: $e');
      return {};
    }
  }

  /// ✅ Valida si un código QR es válido y pertenece a VetCare
  bool isValidVetCareQR(String qrCode) {
    return qrCode.startsWith('VETCARE_PET_') ||
           qrCode.startsWith('VETCARE_CLIENT_') ||
           qrCode.contains('vetcare.app');
  }

  /// 🔐 Registra el escaneo del QR (para auditoría)
  Future<void> logQRScan(String qrCode, String scannedBy) async {
    try {
      await _api.post<Map<String, dynamic>>(
        'qr/scan-log',
        {
          'qr_code': qrCode,
          'scanned_by': scannedBy,
          'scanned_at': DateTime.now().toIso8601String(),
        },
        (json) => (json is Map<String, dynamic>) ? json : {},
      );
    } catch (e) {
      print('⚠️ Error registrando escaneo de QR: $e');
    }
  }
}
