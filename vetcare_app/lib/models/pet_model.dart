// ...existing code...
class PetModel {
  final String id;
  final String clientId;
  final String name;
  final String species;
  final String breed;
  final String? sexo; // Sexo de la mascota
  final int? age;
  final double? weight;
  final List<dynamic> medicalHistory;
  final String? qrCode; // ✅ Código QR único por mascota

  PetModel({
    required this.id,
    required this.clientId,
    required this.name,
    required this.species,
    required this.breed,
    this.sexo,
    this.age,
    this.weight,
    this.medicalHistory = const [],
    this.qrCode, // ✅ Opcional, se genera si no existe
  });

  factory PetModel.fromJson(dynamic json) {
    if (json == null) throw ArgumentError('json is null');
    final map = json as Map<String, dynamic>;
    final history = (map['historial_medico'] ?? map['medical_history'] ?? []) as List<dynamic>;
    return PetModel(
      id: (map['id'] ?? '').toString(),
      clientId: (map['cliente_id'] ?? map['client_id'] ?? '').toString(),
      name: (map['nombre'] ?? map['name'] ?? '').toString(),
      species: (map['especie'] ?? map['species'] ?? '').toString(),
      breed: (map['raza'] ?? map['breed'] ?? '').toString(),
      sexo: map['sexo']?.toString(),
      age: map['edad'] != null ? int.tryParse(map['edad'].toString()) : null,
      weight: map['peso'] != null ? double.tryParse(map['peso'].toString()) : null,
      medicalHistory: history,
      qrCode: map['qr_code']?.toString() ?? map['codigo_qr']?.toString(), // ✅ QR desde backend
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'cliente_id': clientId,
        'nombre': name,
        'especie': species,
        'raza': breed,
        if (sexo != null) 'sexo': sexo,
        'edad': age,
        'peso': weight,
        'historial_medico': medicalHistory,
        'qr_code': qrCode, // ✅ Enviar QR al backend
      };

  // ✅ Generar código QR único basado en el ID de la mascota
  String get uniqueQRCode => qrCode ?? 'VETCARE_PET_$id';
}
