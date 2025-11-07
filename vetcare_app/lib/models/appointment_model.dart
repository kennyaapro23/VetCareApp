// ...existing code...
class AppointmentModel {
  final String id;
  final String petId;
  final String veterinarianId;
  final DateTime? date;
  final String? reason;
  final String? status;

  AppointmentModel({
    required this.id,
    required this.petId,
    required this.veterinarianId,
    this.date,
    this.reason,
    this.status,
  });

  factory AppointmentModel.fromJson(dynamic json) {
    if (json == null) throw ArgumentError('json is null');
    final map = json as Map<String, dynamic>;
    DateTime? parsed;
    final rawDate = map['fecha'] ?? map['date'] ?? map['datetime'];
    if (rawDate != null) {
      parsed = DateTime.tryParse(rawDate.toString());
    }
    return AppointmentModel(
      id: (map['id'] ?? '').toString(),
      petId: (map['mascota_id'] ?? map['pet_id'] ?? '').toString(),
      veterinarianId: (map['veterinario_id'] ?? map['veterinarian_id'] ?? '').toString(),
      date: parsed,
      reason: (map['motivo'] ?? map['reason'])?.toString(),
      status: (map['estado'] ?? map['status'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'mascota_id': petId,
        'veterinario_id': veterinarianId,
        'fecha': date?.toIso8601String(),
        'motivo': reason,
        'estado': status,
      };
}

