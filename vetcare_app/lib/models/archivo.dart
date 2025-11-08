import 'package:flutter/material.dart';

class Archivo {
  final int? id;
  final String relacionadoTipo;
  final int relacionadoId;
  final String nombre;
  final String url;
  final String? tipoMime;
  final int? size;
  final int? uploadedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Archivo({
    this.id,
    required this.relacionadoTipo,
    required this.relacionadoId,
    required this.nombre,
    required this.url,
    this.tipoMime,
    this.size,
    this.uploadedBy,
    this.createdAt,
    this.updatedAt,
  });

  factory Archivo.fromJson(Map<String, dynamic> json) {
    return Archivo(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
      relacionadoTipo: (json['relacionado_tipo'] ?? '').toString(),
      relacionadoId: int.tryParse((json['relacionado_id'] ?? 0).toString()) ?? 0,
      nombre: (json['nombre'] ?? '').toString(),
      url: (json['url'] ?? '').toString(),
      tipoMime: json['tipo_mime']?.toString(),
      size: json['size'] != null ? int.tryParse(json['size'].toString()) : null,
      uploadedBy: json['uploaded_by'] != null ? int.tryParse(json['uploaded_by'].toString()) : null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'relacionado_tipo': relacionadoTipo,
      'relacionado_id': relacionadoId,
      'nombre': nombre,
      'url': url,
      if (tipoMime != null) 'tipo_mime': tipoMime,
      if (size != null) 'size': size,
      if (uploadedBy != null) 'uploaded_by': uploadedBy,
    };
  }

  bool get esImagen {
    if (tipoMime == null) return false;
    return tipoMime!.startsWith('image/');
  }

  bool get esPDF {
    return tipoMime == 'application/pdf';
  }

  String get sizeFormateado {
    if (size == null) return 'Desconocido';

    if (size! < 1024) return '$size B';
    if (size! < 1024 * 1024) return '${(size! / 1024).toStringAsFixed(1)} KB';
    return '${(size! / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  IconData get tipoIcon {
    if (esImagen) return Icons.image;
    if (esPDF) return Icons.picture_as_pdf;
    return Icons.insert_drive_file;
  }
}

