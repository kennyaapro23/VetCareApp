// ...existing code...
import 'package:vetcare_app/models/appointment_model.dart';

class VeterinarianModel {
  final String id;
  final String name;
  final String? specialty;
  final List<AppointmentModel> appointments;

  VeterinarianModel({
    required this.id,
    required this.name,
    this.specialty,
    this.appointments = const [],
  });

  factory VeterinarianModel.fromJson(dynamic json) {
    if (json == null) throw ArgumentError('json is null');
    final map = json as Map<String, dynamic>;
    final appsJson = map['citas'] ?? map['appointments'] ?? [];
    final apps = (appsJson as List).map((e) => AppointmentModel.fromJson(e)).toList();
    return VeterinarianModel(
      id: (map['id'] ?? '').toString(),
      name: (map['nombre'] ?? map['name'] ?? '').toString(),
      specialty: (map['especialidad'] ?? map['specialty'])?.toString(),
      appointments: apps,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': name,
        'especialidad': specialty,
        'citas': appointments.map((e) => e.toJson()).toList(),
      };
}

