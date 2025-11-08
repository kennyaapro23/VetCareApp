import 'package:flutter/material.dart';

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

