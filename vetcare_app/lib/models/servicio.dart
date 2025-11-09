class Servicio {
  final int id;
  final String codigo;
  final String nombre;
  final String? descripcion;
  final String tipo; // vacuna, tratamiento, baño, consulta, cirugía, otro
  final int duracionMinutos;
  final double precio;
  final bool requiereVacunaInfo;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Servicio({
    required this.id,
    required this.codigo,
    required this.nombre,
    this.descripcion,
    required this.tipo,
    required this.duracionMinutos,
    required this.precio,
    required this.requiereVacunaInfo,
    this.createdAt,
    this.updatedAt,
  });

  factory Servicio.fromJson(Map<String, dynamic> json) {
    return Servicio(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) ?? 0 : 0,
      codigo: (json['codigo'] ?? '').toString(),
      nombre: (json['nombre'] ?? '').toString(),
      descripcion: json['descripcion']?.toString(),
      tipo: (json['tipo'] ?? 'otro').toString(),
      duracionMinutos: json['duracion_minutos'] != null
          ? int.tryParse(json['duracion_minutos'].toString()) ?? 30
          : 30,
      precio: json['precio'] != null
          ? double.tryParse(json['precio'].toString()) ?? 0.0
          : 0.0,
      requiereVacunaInfo: json['requiere_vacuna_info'] == true || json['requiere_vacuna_info'] == 1,
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
      'id': id,
      'codigo': codigo,
      'nombre': nombre,
      'descripcion': descripcion,
      'tipo': tipo,
      'duracion_minutos': duracionMinutos,
      'precio': precio,
      'requiere_vacuna_info': requiereVacunaInfo,
    };
  }

  String get precioFormateado => 'S/. ${precio.toStringAsFixed(2)}';
}

