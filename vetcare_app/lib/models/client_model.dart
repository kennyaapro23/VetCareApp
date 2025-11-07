// ...existing code...
import 'package:vetcare_app/models/pet_model.dart';

class ClientModel {
  final String id;
  final String name;
  final String? phone;
  final String? address;
  final String? email;
  final List<PetModel> pets;

  ClientModel({
    required this.id,
    required this.name,
    this.phone,
    this.address,
    this.email,
    this.pets = const [],
  });

  factory ClientModel.fromJson(dynamic json) {
    if (json == null) throw ArgumentError('json is null');
    final map = json as Map<String, dynamic>;
    final petsJson = map['mascotas'] ?? map['pets'] ?? [];
    final pets = (petsJson as List).map((e) => PetModel.fromJson(e)).toList();
    return ClientModel(
      id: (map['id'] ?? '').toString(),
      name: (map['nombre'] ?? map['name'] ?? '').toString(),
      phone: (map['telefono'] ?? map['phone'])?.toString(),
      address: (map['direccion'] ?? map['address'])?.toString(),
      email: (map['email'] ?? '').toString(),
      pets: pets,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': name,
        'telefono': phone,
        'direccion': address,
        'email': email,
        'mascotas': pets.map((e) => e.toJson()).toList(),
      };
}

