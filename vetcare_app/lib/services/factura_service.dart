import 'package:flutter/foundation.dart';
import 'package:vetcare_app/models/factura.dart';
import 'package:vetcare_app/services/api_service.dart';

class FacturaService {
  final ApiService _api;

  FacturaService(this._api);

  Future<List<Factura>> getFacturas({
    int? clienteId,
    String? estado,
    String? fechaDesde,
    String? fechaHasta,
    String? numeroFactura,
    String? clienteNombre,
    String? mascotaNombre,
  }) async {
    final params = <String, String>{};
    if (clienteId != null) params['cliente_id'] = clienteId.toString();
    if (estado != null) params['estado'] = estado;
    if (fechaDesde != null) params['fecha_desde'] = fechaDesde;
    if (fechaHasta != null) params['fecha_hasta'] = fechaHasta;
    if (numeroFactura != null) params['numero_factura'] = numeroFactura;
    if (clienteNombre != null) params['cliente_nombre'] = clienteNombre;
    if (mascotaNombre != null) params['mascota_nombre'] = mascotaNombre;

    final resp = await _api.get<Map<String, dynamic>>(
      'facturas',
      (json) => (json is Map<String, dynamic>) ? json : {},
      queryParameters: params.isNotEmpty ? params : null,
    );
    
    // Respuesta paginada de Laravel: {data: [...], meta: {...}, links: {...}}
    final facturas = (resp['data'] as List<dynamic>?)
        ?.map((e) => Factura.fromJson(e as Map<String, dynamic>))
        .toList() ?? [];
    
    return facturas;
  }

  Future<Factura> getFactura(String id) async {
    final resp = await _api.get<Map<String, dynamic>>(
      'facturas/$id',
      (json) => (json is Map<String, dynamic>) ? json : {},
    );
    return Factura.fromJson(resp);
  }

  /// Crear factura desde una cita
  Future<Factura> crearFacturaDesdeCita({
    required int citaId,
    required String numeroFactura,
    String? metodoPago,
    String? notas,
  }) async {
    final data = {
      'cita_id': citaId,
      'numero_factura': numeroFactura,
      if (metodoPago != null) 'metodo_pago': metodoPago,
      if (notas != null) 'notas': notas,
    };

    final resp = await _api.post<Map<String, dynamic>>(
      'facturas',
      data,
      (json) => (json is Map<String, dynamic>) ? json : {},
    );
    
    // Backend devuelve {message: ..., factura: {...}}
    final facturaData = resp['factura'] ?? resp;
    return Factura.fromJson(facturaData as Map<String, dynamic>);
  }

  /// Crear factura desde historiales médicos
  Future<Factura> createFacturaDesdeHistoriales({
    required int clienteId,
    required List<int> historialIds,
    String? metodoPago,
    String? notas,
    double? tasaImpuesto,
  }) async {
    debugPrint('📝 Creando factura desde historiales...');
    debugPrint('   Cliente ID: $clienteId');
    debugPrint('   Historiales: $historialIds');
    debugPrint('   Método de pago: $metodoPago');
    debugPrint('   Tasa impuesto: ${tasaImpuesto ?? 16}%');

    final data = {
      'cliente_id': clienteId,
      'historial_ids': historialIds,
      if (metodoPago != null) 'metodo_pago': metodoPago,
      if (notas != null) 'notas': notas,
      'tasa_impuesto': tasaImpuesto ?? 16,
    };

    final resp = await _api.post<Map<String, dynamic>>(
      'facturas/desde-historiales',
      data,
      (json) => (json is Map<String, dynamic>) ? json : {},
    );
    
    debugPrint('✅ Factura creada exitosamente');
    debugPrint('   Respuesta: ${resp.keys}');
    
    // Backend devuelve {message: ..., factura: {...}, total_historiales: X}
    final facturaData = resp['factura'] ?? resp;
    return Factura.fromJson(facturaData as Map<String, dynamic>);
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

  /// Obtener estadísticas de facturación
  Future<Map<String, dynamic>> getEstadisticas({
    String? fechaDesde,
    String? fechaHasta,
  }) async {
    final params = <String, String>{};
    if (fechaDesde != null) params['fecha_desde'] = fechaDesde;
    if (fechaHasta != null) params['fecha_hasta'] = fechaHasta;

    final resp = await _api.get<Map<String, dynamic>>(
      'facturas-estadisticas',
      (json) => (json is Map<String, dynamic>) ? json : {},
      queryParameters: params.isNotEmpty ? params : null,
    );
    return resp;
  }

  /// Generar número de factura automático
  Future<String> generarNumeroFactura() async {
    final resp = await _api.get<Map<String, dynamic>>(
      'facturas/generateNumeroFactura',
      (json) => (json is Map<String, dynamic>) ? json : {},
    );
    return resp['numero_factura']?.toString() ?? '';
  }
}
