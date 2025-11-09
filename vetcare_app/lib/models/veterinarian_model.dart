class VeterinarianModel {
  final String id;
  final String name;
  final String? email;
  final String? telefono;
  final String? especialidad;
  final String? licencia;

  VeterinarianModel({
    required this.id,
    required this.name,
    this.email,
    this.telefono,
    this.especialidad,
    this.licencia,
  });

  factory VeterinarianModel.fromJson(dynamic json) {
    if (json == null) throw ArgumentError('json is null');
    final map = json as Map<String, dynamic>;

    return VeterinarianModel(
      id: (map['id'] ?? '').toString(),
      name: (map['name'] ?? map['nombre'] ?? '').toString(),
      email: map['email']?.toString(),
      telefono: map['telefono']?.toString() ?? map['phone']?.toString(),
      especialidad: map['especialidad']?.toString(),
      licencia: map['licencia']?.toString() ?? map['license']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (email != null) 'email': email,
        if (telefono != null) 'telefono': telefono,
        if (especialidad != null) 'especialidad': especialidad,
        if (licencia != null) 'licencia': licencia,
      };
}

