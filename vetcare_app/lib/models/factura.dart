import 'package:flutter/material.dart';

class Factura {
  final int? id;
  final int clienteId;
  final int? citaId;
  final double total;
  final String estado;
  final String? metodoPago;
  final Map<String, dynamic>? detalles;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Factura({
    this.id,
    required this.clienteId,
    this.citaId,
    required this.total,
    required this.estado,
    this.metodoPago,
    this.detalles,
    this.createdAt,
    this.updatedAt,
  });

  factory Factura.fromJson(Map<String, dynamic> json) {
    return Factura(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
      clienteId: int.tryParse((json['cliente_id'] ?? 0).toString()) ?? 0,
      citaId: json['cita_id'] != null ? int.tryParse(json['cita_id'].toString()) : null,
      total: json['total'] != null ? double.tryParse(json['total'].toString()) ?? 0.0 : 0.0,
      estado: (json['estado'] ?? 'pendiente').toString(),
      metodoPago: json['metodo_pago']?.toString(),
      detalles: json['detalles'] != null ? Map<String, dynamic>.from(json['detalles']) : null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'cliente_id': clienteId,
      'total': total,
      'estado': estado,
      if (citaId != null) 'cita_id': citaId,
      if (metodoPago != null) 'metodo_pago': metodoPago,
      if (detalles != null) 'detalles': detalles,
    };
  }

  String get totalFormateado {
    return 'S/. ${total.toStringAsFixed(2)}';
  }

  Color get estadoColor {
    switch (estado) {
      case 'pagado':
        return Colors.green;
      case 'pendiente':
        return Colors.orange;
      case 'anulado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

