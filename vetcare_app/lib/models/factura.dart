import 'package:flutter/material.dart';
import 'package:vetcare_app/models/historial_medico.dart';

class Factura {
  final int? id;
  final int clienteId;
  final int? citaId;
  final String? numeroFactura; // ⭐ NUEVO
  final DateTime? fechaEmision; // ⭐ NUEVO
  final double subtotal; // ⭐ NUEVO
  final double impuestos; // ⭐ NUEVO
  final double total;
  final String estado;
  final String? metodoPago;
  final String? notas; // ⭐ NUEVO
  final Map<String, dynamic>? detalles;
  final List<HistorialMedico>? historiales; // ⭐ NUEVO
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Factura({
    this.id,
    required this.clienteId,
    this.citaId,
    this.numeroFactura,
    this.fechaEmision,
    this.subtotal = 0.0,
    this.impuestos = 0.0,
    required this.total,
    required this.estado,
    this.metodoPago,
    this.notas,
    this.detalles,
    this.historiales,
    this.createdAt,
    this.updatedAt,
  });

  factory Factura.fromJson(Map<String, dynamic> json) {
    // Parse historiales si vienen
    List<HistorialMedico>? historiales;
    if (json['historiales'] != null && json['historiales'] is List) {
      try {
        historiales = (json['historiales'] as List)
            .map((e) => HistorialMedico.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        historiales = null;
      }
    }

    return Factura(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
      clienteId: int.tryParse((json['cliente_id'] ?? 0).toString()) ?? 0,
      citaId: json['cita_id'] != null ? int.tryParse(json['cita_id'].toString()) : null,
      numeroFactura: json['numero_factura']?.toString(),
      fechaEmision: json['fecha_emision'] != null
          ? DateTime.tryParse(json['fecha_emision'].toString())
          : null,
      subtotal: json['subtotal'] != null
          ? double.tryParse(json['subtotal'].toString()) ?? 0.0
          : 0.0,
      impuestos: json['impuestos'] != null
          ? double.tryParse(json['impuestos'].toString()) ?? 0.0
          : 0.0,
      total: json['total'] != null
          ? double.tryParse(json['total'].toString()) ?? 0.0
          : 0.0,
      estado: (json['estado'] ?? 'pendiente').toString(),
      metodoPago: json['metodo_pago']?.toString(),
      notas: json['notas']?.toString(),
      detalles: json['detalles'] != null
          ? Map<String, dynamic>.from(json['detalles'])
          : null,
      historiales: historiales,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'cliente_id': clienteId,
      'total': total,
      'estado': estado,
      if (citaId != null) 'cita_id': citaId,
      if (numeroFactura != null) 'numero_factura': numeroFactura,
      if (fechaEmision != null) 'fecha_emision': fechaEmision!.toIso8601String(),
      'subtotal': subtotal,
      'impuestos': impuestos,
      if (metodoPago != null) 'metodo_pago': metodoPago,
      if (notas != null) 'notas': notas,
      if (detalles != null) 'detalles': detalles,
    };
  }

  String get totalFormateado {
    return 'S/. ${total.toStringAsFixed(2)}';
  }

  String get subtotalFormateado {
    return 'S/. ${subtotal.toStringAsFixed(2)}';
  }

  String get impuestosFormateado {
    return 'S/. ${impuestos.toStringAsFixed(2)}';
  }

  Color get estadoColor {
    switch (estado.toLowerCase()) {
      case 'pagada':
      case 'pagado':
        return Colors.green;
      case 'pendiente':
        return Colors.orange;
      case 'cancelada':
      case 'anulado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
