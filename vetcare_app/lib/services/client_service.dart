import 'package:flutter/foundation.dart';
import 'package:vetcare_app/models/client_model.dart';
import 'package:vetcare_app/services/api_service.dart';

class ClientService {
  final ApiService _api;

  ClientService(this._api);

  Future<List<ClientModel>> getClients() async {
    debugPrint('📋 Obteniendo lista de clientes...');
    final resp = await _api.get<dynamic>(
      'clientes',
      (json) => json,
    );
    
    // Detectar si es respuesta paginada o array directo
    List<dynamic> dataList;
    if (resp is Map && resp.containsKey('data')) {
      dataList = (resp['data'] is List) ? resp['data'] : [];
      debugPrint('📨 Respuesta paginada detectada: ${dataList.length} clientes');
    } else if (resp is List) {
      dataList = resp;
      debugPrint('📨 Respuesta directa detectada: ${dataList.length} clientes');
    } else {
      debugPrint('⚠️ Respuesta inesperada: ${resp.runtimeType}');
      dataList = [];
    }
    
    final clients = dataList.map((e) => ClientModel.fromJson(e)).toList();
    debugPrint('✅ Clientes parseados: ${clients.length}');
    return clients;
  }

  /// Obtener solo clientes walk-in (sin cuenta)
  Future<List<ClientModel>> getClientesWalkIn() async {
    debugPrint('📋 Obteniendo clientes walk-in...');
    final resp = await _api.get<dynamic>(
      'clientes?es_walk_in=true',
      (json) => json,
    );
    
    // Detectar si es respuesta paginada o array directo
    List<dynamic> dataList;
    if (resp is Map && resp.containsKey('data')) {
      dataList = (resp['data'] is List) ? resp['data'] : [];
      debugPrint('📨 Respuesta paginada: ${dataList.length} clientes walk-in');
    } else if (resp is List) {
      dataList = resp;
      debugPrint('📨 Respuesta directa: ${dataList.length} clientes walk-in');
    } else {
      dataList = [];
    }
    
    return dataList.map((e) => ClientModel.fromJson(e)).toList();
  }

  /// Obtener solo clientes con cuenta registrada
  Future<List<ClientModel>> getClientesConCuenta() async {
    debugPrint('📋 Obteniendo clientes con cuenta...');
    final resp = await _api.get<dynamic>(
      'clientes?es_walk_in=false',
      (json) => json,
    );
    
    // Detectar si es respuesta paginada o array directo
    List<dynamic> dataList;
    if (resp is Map && resp.containsKey('data')) {
      dataList = (resp['data'] is List) ? resp['data'] : [];
      debugPrint('📨 Respuesta paginada: ${dataList.length} clientes con cuenta');
    } else if (resp is List) {
      dataList = resp;
      debugPrint('📨 Respuesta directa: ${dataList.length} clientes con cuenta');
    } else {
      dataList = [];
    }
    
    return dataList.map((e) => ClientModel.fromJson(e)).toList();
  }

  Future<ClientModel> getClient(String id) async {
    final resp = await _api.get<Map<String, dynamic>>(
      'clientes/$id',
      (json) => (json is Map<String, dynamic>) ? json : {},
    );
    return ClientModel.fromJson(resp);
  }

  /// Registro rápido: Crea cliente walk-in + mascota en una sola llamada
  /// Retorna: Map con {cliente, mascota, qr_code, qr_url}
  Future<Map<String, dynamic>> registroRapido({
    // Datos del cliente (requeridos)
    required String nombreCliente,
    required String telefonoCliente,
    // Datos del cliente (opcionales)
    String? emailCliente,
    String? direccionCliente,
    String? notasCliente,
    // Datos de la mascota (requeridos)
    required String nombreMascota,
    required String especieMascota,
    required String sexoMascota, // 'macho' o 'hembra'
    // Datos de la mascota (opcionales)
    String? razaMascota,
    String? colorMascota,
    double? pesoMascota,
    int? edadMascota,
    String? observacionesMascota,
  }) async {
    final data = {
      'cliente': {
        'nombre': nombreCliente,
        'telefono': telefonoCliente,
        if (emailCliente != null) 'email': emailCliente,
        if (direccionCliente != null) 'direccion': direccionCliente,
        if (notasCliente != null) 'notas': notasCliente,
      },
      'mascota': {
        'nombre': nombreMascota,
        'especie': especieMascota,
        'sexo': sexoMascota,
        if (razaMascota != null) 'raza': razaMascota,
        if (colorMascota != null) 'color': colorMascota,
        if (pesoMascota != null) 'peso': pesoMascota,
        if (edadMascota != null) 'edad': edadMascota,
        if (observacionesMascota != null) 'observaciones': observacionesMascota,
      },
    };

    final resp = await _api.post<Map<String, dynamic>>(
      'clientes/registro-rapido',
      data,
      (json) => (json is Map<String, dynamic>) ? json : {},
    );

    return resp;
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
