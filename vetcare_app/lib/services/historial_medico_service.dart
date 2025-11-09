import 'package:flutter/material.dart';
import 'package:vetcare_app/models/historial_medico.dart';
import 'package:vetcare_app/services/api_service.dart';

class HistorialMedicoService {
  final ApiService _api;

  HistorialMedicoService(this._api);

  Future<List<HistorialMedico>> getHistorial({
    int? mascotaId,
    String? tipo,
    bool? facturado, // ⭐ NUEVO
    int? clienteId, // ⭐ NUEVO
  }) async {
    final params = <String, String>{};
    if (mascotaId != null) params['mascota_id'] = mascotaId.toString();
    if (tipo != null) params['tipo'] = tipo;
    if (facturado != null) params['facturado'] = facturado.toString();
    if (clienteId != null) params['cliente_id'] = clienteId.toString();

    debugPrint('🌐 GET historial-medico con params: $params');

    final resp = await _api.get<dynamic>(
      'historial-medico',
      (json) => json,
      queryParameters: params.isNotEmpty ? params : null,
    );

    debugPrint('📨 Respuesta historial raw: ${resp.runtimeType}');

    // Manejar respuesta paginada de Laravel
    List<dynamic> dataList;
    if (resp is Map && resp.containsKey('data')) {
      // Respuesta paginada: {"current_page": 1, "data": [...]}
      dataList = (resp['data'] is List) ? resp['data'] : [];
      debugPrint('📨 Respuesta paginada detectada: ${dataList.length} registros');
    } else if (resp is List) {
      // Respuesta directa: [...]
      dataList = resp;
      debugPrint('📨 Respuesta directa detectada: ${dataList.length} registros');
    } else {
      dataList = [];
      debugPrint('⚠️ Respuesta no reconocida');
    }

    if (dataList.isNotEmpty) {
      debugPrint('📨 Primer registro: ${dataList.first}');
    }

    return dataList.map((e) => HistorialMedico.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Obtener historiales sin facturar de un cliente ⭐ NUEVO
  Future<List<HistorialMedico>> getHistorialesSinFacturar(int clienteId) async {
    return getHistorial(clienteId: clienteId, facturado: false);
  }

  /// Obtener historial con filtros de fecha
  Future<List<HistorialMedico>> getHistorialConFiltros({
    int? mascotaId,
    String? tipo,
    DateTime? fechaDesde,
    DateTime? fechaHasta,
    bool? facturado, // ⭐ NUEVO
  }) async {
    final params = <String, String>{};
    if (mascotaId != null) params['mascota_id'] = mascotaId.toString();
    if (tipo != null) params['tipo'] = tipo;
    if (fechaDesde != null) params['fecha_desde'] = fechaDesde.toIso8601String().split('T')[0];
    if (fechaHasta != null) params['fecha_hasta'] = fechaHasta.toIso8601String().split('T')[0];
    if (facturado != null) params['facturado'] = facturado.toString();

    final resp = await _api.get<List<dynamic>>(
      'historial-medico',
      (json) => (json is List) ? json : [],
      queryParameters: params.isNotEmpty ? params : null,
    );
    return resp.map((e) => HistorialMedico.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Obtener historial del último mes
  Future<List<HistorialMedico>> getHistorialUltimoMes({int? mascotaId}) async {
    final fechaHasta = DateTime.now();
    final fechaDesde = DateTime.now().subtract(const Duration(days: 30));
    return getHistorialConFiltros(
      mascotaId: mascotaId,
      fechaDesde: fechaDesde,
      fechaHasta: fechaHasta,
    );
  }

  /// Obtener historial de los últimos 3 meses
  Future<List<HistorialMedico>> getHistorialUltimosTresMeses({int? mascotaId}) async {
    final fechaHasta = DateTime.now();
    final fechaDesde = DateTime.now().subtract(const Duration(days: 90));
    return getHistorialConFiltros(
      mascotaId: mascotaId,
      fechaDesde: fechaDesde,
      fechaHasta: fechaHasta,
    );
  }

  /// Obtener historial del año actual
  Future<List<HistorialMedico>> getHistorialAnioActual({int? mascotaId}) async {
    final now = DateTime.now();
    final fechaDesde = DateTime(now.year, 1, 1);
    final fechaHasta = DateTime(now.year, 12, 31);
    return getHistorialConFiltros(
      mascotaId: mascotaId,
      fechaDesde: fechaDesde,
      fechaHasta: fechaHasta,
    );
  }

  Future<HistorialMedico> getRegistro(String id) async {
    final resp = await _api.get<Map<String, dynamic>>(
      'historial-medico/$id',
      (json) => (json is Map<String, dynamic>) ? json : {},
    );
    return HistorialMedico.fromJson(resp);
  }

  /// Crear registro con servicios ⭐ ACTUALIZADO
  Future<HistorialMedico> crearRegistro(Map<String, dynamic> data) async {
    final resp = await _api.post<Map<String, dynamic>>(
      'historial-medico',
      data,
      (json) => (json is Map<String, dynamic>) ? json : {},
    );
    return HistorialMedico.fromJson(resp);
  }

  /// Crear historial con servicios (método helper) ⭐ NUEVO
  Future<HistorialMedico> crearHistorialConServicios({
    required int mascotaId,
    int? citaId,
    required String tipo,
    String? diagnostico,
    String? tratamiento,
    String? observaciones,
    List<Map<String, dynamic>>? servicios,
  }) async {
    final data = {
      'mascota_id': mascotaId,
      if (citaId != null) 'cita_id': citaId,
      'fecha': DateTime.now().toIso8601String(),
      'tipo': tipo,
      if (diagnostico != null && diagnostico.isNotEmpty) 'diagnostico': diagnostico,
      if (tratamiento != null && tratamiento.isNotEmpty) 'tratamiento': tratamiento,
      if (observaciones != null && observaciones.isNotEmpty) 'observaciones': observaciones,
      if (servicios != null && servicios.isNotEmpty) 'servicios': servicios,
    };
    return crearRegistro(data);
  }

  Future<HistorialMedico> actualizarRegistro(String id, Map<String, dynamic> data) async {
    final resp = await _api.put<Map<String, dynamic>>(
      'historial-medico/$id',
      data,
      (json) => (json is Map<String, dynamic>) ? json : {},
    );
    return HistorialMedico.fromJson(resp);
  }

  Future<void> eliminarRegistro(String id) async {
    await _api.delete<Map<String, dynamic>>(
      'historial-medico/$id',
      (json) => (json is Map<String, dynamic>) ? json : {},
    );
  }

  Future<HistorialMedico> attachFiles(String id, List<String> archivos) async {
    final resp = await _api.post<Map<String, dynamic>>(
      'historial-medico/$id/archivos',
      {'archivos': archivos},
      (json) => (json is Map<String, dynamic>) ? json : {},
    );
    return HistorialMedico.fromJson(resp);
  }
}
