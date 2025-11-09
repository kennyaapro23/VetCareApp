import 'package:flutter/material.dart';

class HistorialServicioPivot {
  final int cantidad;
  final double precioUnitario;
  final String? notas;

  HistorialServicioPivot({
    required this.cantidad,
    required this.precioUnitario,
    this.notas,
  });

  factory HistorialServicioPivot.fromJson(Map<String, dynamic> json) {
    return HistorialServicioPivot(
      cantidad: json['cantidad'] != null ? int.tryParse(json['cantidad'].toString()) ?? 1 : 1,
      precioUnitario: json['precio_unitario'] != null ? double.tryParse(json['precio_unitario'].toString()) ?? 0.0 : 0.0,
      notas: json['notas']?.toString(),
    );
  }
}

class HistorialServicio {
  final int id;
  final String nombre;
  final HistorialServicioPivot pivot;

  HistorialServicio({
    required this.id,
    required this.nombre,
    required this.pivot,
  });

  factory HistorialServicio.fromJson(Map<String, dynamic> json) {
    final pivotJson = (json['pivot'] ?? {}) as Map<String, dynamic>;
    return HistorialServicio(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) ?? 0 : 0,
      nombre: (json['nombre'] ?? json['name'] ?? '').toString(),
      pivot: HistorialServicioPivot.fromJson(pivotJson),
    );
  }
}

class HistorialMedico {
  final int? id;
  final int mascotaId;
  final int? citaId;
  final DateTime fecha;
  final String tipo;
  final String? diagnostico;
  final String? tratamiento;
  final String? observaciones;
  final int? realizadoPor;
  final Map<String, dynamic>? archivosMeta;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Nuevos campos - Servicios
  final List<HistorialServicio> servicios;
  final double totalServicios;

  // Nuevos campos - Facturación ⭐
  final bool facturado;
  final int? facturaId;

  HistorialMedico({
    this.id,
    required this.mascotaId,
    this.citaId,
    required this.fecha,
    required this.tipo,
    this.diagnostico,
    this.tratamiento,
    this.observaciones,
    this.realizadoPor,
    this.archivosMeta,
    this.createdAt,
    this.updatedAt,
    this.servicios = const [],
    this.totalServicios = 0.0,
    this.facturado = false,
    this.facturaId,
  });

  factory HistorialMedico.fromJson(Map<String, dynamic> json) {
    DateTime parseFecha(dynamic raw) {
      if (raw == null) return DateTime.now();
      if (raw is int) {
        if (raw.abs() > 1000000000000) return DateTime.fromMillisecondsSinceEpoch(raw);
        return DateTime.fromMillisecondsSinceEpoch(raw * 1000);
      }
      return DateTime.tryParse(raw.toString()) ?? DateTime.now();
    }

    // Parse servicios si vienen
    List<HistorialServicio> servicios = [];
    if (json['servicios'] != null && json['servicios'] is List) {
      try {
        servicios = (json['servicios'] as List)
            .map((e) => HistorialServicio.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        servicios = [];
      }
    }

    return HistorialMedico(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
      mascotaId: int.tryParse((json['mascota_id'] ?? 0).toString()) ?? 0,
      citaId: json['cita_id'] != null ? int.tryParse(json['cita_id'].toString()) : null,
      fecha: parseFecha(json['fecha']),
      tipo: (json['tipo'] ?? 'consulta').toString(),
      diagnostico: json['diagnostico']?.toString(),
      tratamiento: json['tratamiento']?.toString(),
      observaciones: json['observaciones']?.toString(),
      realizadoPor: json['realizado_por'] != null ? int.tryParse(json['realizado_por'].toString()) : null,
      archivosMeta: json['archivos_meta'] != null ? Map<String, dynamic>.from(json['archivos_meta']) : null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
      servicios: servicios,
      totalServicios: json['total_servicios'] != null ? double.tryParse(json['total_servicios'].toString()) ?? 0.0 : 0.0,
      facturado: json['facturado'] == true || json['facturado'] == 1,
      facturaId: json['factura_id'] != null ? int.tryParse(json['factura_id'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'mascota_id': mascotaId,
      'fecha': fecha.toIso8601String(),
      'tipo': tipo,
      if (citaId != null) 'cita_id': citaId,
      if (diagnostico != null) 'diagnostico': diagnostico,
      if (tratamiento != null) 'tratamiento': tratamiento,
      if (observaciones != null) 'observaciones': observaciones,
      if (realizadoPor != null) 'realizado_por': realizadoPor,
      if (archivosMeta != null) 'archivos_meta': archivosMeta,
      'facturado': facturado,
      if (facturaId != null) 'factura_id': facturaId,
      if (servicios.isNotEmpty)
        'servicios': servicios
            .map((s) => {
                  'id': s.id,
                  'nombre': s.nombre,
                  'pivot': {
                    'cantidad': s.pivot.cantidad,
                    'precio_unitario': s.pivot.precioUnitario,
                    'notas': s.pivot.notas,
                  }
                })
            .toList(),
    };
  }

  IconData get tipoIcon {
    switch (tipo) {
      case 'consulta':
        return Icons.medical_services;
      case 'vacuna':
        return Icons.vaccines;
      case 'procedimiento':
        return Icons.healing;
      case 'control':
        return Icons.health_and_safety;
      default:
        return Icons.folder;
    }
  }
}
