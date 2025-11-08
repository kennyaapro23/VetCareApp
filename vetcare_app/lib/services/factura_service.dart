import 'package:vetcare_app/models/factura.dart';
import 'package:vetcare_app/services/api_service.dart';

class FacturaService {
  final ApiService _api;

  FacturaService(this._api);

  Future<List<Factura>> getFacturas({int? clienteId, String? estado}) async {
    final params = <String, String>{};
    if (clienteId != null) params['cliente_id'] = clienteId.toString();
    if (estado != null) params['estado'] = estado;

    final resp = await _api.get<List<dynamic>>(
      'facturas',
      (json) => (json is List) ? json : [],
      queryParameters: params.isNotEmpty ? params : null,
    );
    return resp.map((e) => Factura.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Factura> getFactura(String id) async {
    final resp = await _api.get<Map<String, dynamic>>(
      'facturas/$id',
      (json) => (json is Map<String, dynamic>) ? json : {},
    );
    return Factura.fromJson(resp);
  }

  Future<Factura> crearFactura(Map<String, dynamic> data) async {
    final resp = await _api.post<Map<String, dynamic>>(
      'facturas',
      data,
      (json) => (json is Map<String, dynamic>) ? json : {},
    );
    return Factura.fromJson(resp);
  }

  Future<Factura> actualizarFactura(String id, Map<String, dynamic> data) async {
    final resp = await _api.put<Map<String, dynamic>>(
      'facturas/$id',
      data,
      (json) => (json is Map<String, dynamic>) ? json : {},
    );
    return Factura.fromJson(resp);
  }

  Future<void> eliminarFactura(String id) async {
    await _api.delete<Map<String, dynamic>>(
      'facturas/$id',
      (json) => (json is Map<String, dynamic>) ? json : {},
    );
  }

  Future<Map<String, dynamic>> getEstadisticas() async {
    final resp = await _api.get<Map<String, dynamic>>(
      'facturas-estadisticas',
      (json) => (json is Map<String, dynamic>) ? json : {},
    );
    return resp;
  }

  Future<String> generarNumeroFactura() async {
    final resp = await _api.get<Map<String, dynamic>>(
      'generar-numero-factura',
      (json) => (json is Map<String, dynamic>) ? json : {},
    );
    return resp['numero_factura']?.toString() ?? '';
  }
}

