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

    // Extraer pet id soportando distintos formatos
    String petId = '';
    if (map.containsKey('mascota_id')) {
      petId = (map['mascota_id'] ?? '').toString();
    } else if (map.containsKey('pet_id')) {
      petId = (map['pet_id'] ?? '').toString();
    } else if (map.containsKey('mascota') && map['mascota'] is Map) {
      petId = ((map['mascota'] as Map)['id'] ?? '').toString();
    } else if (map.containsKey('pet') && map['pet'] is Map) {
      petId = ((map['pet'] as Map)['id'] ?? '').toString();
    }

    // Extraer veterinarian id soportando distintos formatos
    String vetId = '';
    if (map.containsKey('veterinario_id')) {
      vetId = (map['veterinario_id'] ?? '').toString();
    } else if (map.containsKey('veterinarian_id')) {
      vetId = (map['veterinarian_id'] ?? '').toString();
    } else if (map.containsKey('veterinario') && map['veterinario'] is Map) {
      vetId = ((map['veterinario'] as Map)['id'] ?? '').toString();
    } else if (map.containsKey('veterinarian') && map['veterinarian'] is Map) {
      vetId = ((map['veterinarian'] as Map)['id'] ?? '').toString();
    }

    // Parsear fecha: aceptar string ISO, entero (epoch seconds/ms) o string numérico
    DateTime? parsed;
    final rawDate = map['fecha'] ?? map['date'] ?? map['datetime'] ?? map['fecha_hora'] ?? map['fechaHora'];
    if (rawDate != null) {
      try {
        if (rawDate is int) {
          // Determinar si es segundos o milisegundos
          if (rawDate.abs() > 1000000000000) {
            parsed = DateTime.fromMillisecondsSinceEpoch(rawDate);
          } else {
            parsed = DateTime.fromMillisecondsSinceEpoch(rawDate * 1000);
          }
        } else if (rawDate is double) {
          final asInt = rawDate.toInt();
          if (asInt.abs() > 1000000000000) {
            parsed = DateTime.fromMillisecondsSinceEpoch(asInt);
          } else {
            parsed = DateTime.fromMillisecondsSinceEpoch(asInt * 1000);
          }
        } else {
          final s = rawDate.toString();
          // si es un número en string
          final digitsOnly = RegExp(r'^\d{9,}$');
          if (digitsOnly.hasMatch(s)) {
            final asInt = int.tryParse(s);
            if (asInt != null) {
              if (asInt.abs() > 1000000000000) {
                parsed = DateTime.fromMillisecondsSinceEpoch(asInt);
              } else {
                parsed = DateTime.fromMillisecondsSinceEpoch(asInt * 1000);
              }
            }
          } else {
            parsed = DateTime.tryParse(s);
          }
        }
      } catch (_) {
        parsed = null;
      }
    }

    return AppointmentModel(
      id: (map['id'] ?? '').toString(),
      petId: petId,
      veterinarianId: vetId,
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
// ...existing code...
