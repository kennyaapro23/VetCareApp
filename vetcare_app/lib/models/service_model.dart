// ...existing code...
class ServiceModel {
  final String id;
  final String petId;
  final String type;
  final String? description;
  final DateTime? date;
  final double? cost;

  ServiceModel({
    required this.id,
    required this.petId,
    required this.type,
    this.description,
    this.date,
    this.cost,
  });

  factory ServiceModel.fromJson(dynamic json) {
    if (json == null) throw ArgumentError('json is null');
    final map = json as Map<String, dynamic>;
    DateTime? parsed;
    final rawDate = map['fecha'] ?? map['date'];
    if (rawDate != null) parsed = DateTime.tryParse(rawDate.toString());
    return ServiceModel(
      id: (map['id'] ?? '').toString(),
      petId: (map['mascota_id'] ?? map['pet_id'] ?? '').toString(),
      type: (map['tipo_servicio'] ?? map['type'] ?? '').toString(),
      description: (map['descripcion'] ?? map['description'])?.toString(),
      date: parsed,
      cost: map['costo'] != null ? double.tryParse(map['costo'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'mascota_id': petId,
        'tipo_servicio': type,
        'descripcion': description,
        'fecha': date?.toIso8601String(),
        'costo': cost,
      };
}

