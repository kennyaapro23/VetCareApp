class UserModel {
  final String id;
  final String? firebaseUid;
  final String name;
  final String email;
  final String? telefono;
  final String role;
  final String? tipoUsuario;
  final String? avatarUrl;
  final DateTime? emailVerifiedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<String>? roles;

  UserModel({
    required this.id,
    this.firebaseUid,
    required this.name,
    required this.email,
    this.telefono,
    required this.role,
    this.tipoUsuario,
    this.avatarUrl,
    this.emailVerifiedAt,
    this.createdAt,
    this.updatedAt,
    this.roles,
  });

  factory UserModel.fromJson(dynamic json) {
    if (json == null) {
      throw ArgumentError('json is null');
    }
    if (json is Map<String, dynamic>) {
      return UserModel(
        id: (json['id'] ?? json['user_id'] ?? '').toString(),
        firebaseUid: json['firebase_uid']?.toString(),
        name: (json['name'] ?? json['full_name'] ?? '').toString(),
        email: (json['email'] ?? '').toString(),
        telefono: json['telefono']?.toString() ?? json['phone']?.toString(),
        role: (json['role'] ?? json['rol'] ?? 'cliente').toString(),
        tipoUsuario: json['tipo_usuario']?.toString(),
        avatarUrl: json['avatar']?.toString() ?? json['avatar_url']?.toString(),
        emailVerifiedAt: json['email_verified_at'] != null
            ? DateTime.tryParse(json['email_verified_at'].toString())
            : null,
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'].toString())
            : null,
        updatedAt: json['updated_at'] != null
            ? DateTime.tryParse(json['updated_at'].toString())
            : null,
        roles: json['roles'] != null
            ? List<String>.from(json['roles'])
            : null,
      );
    }
    throw ArgumentError('Invalid json for UserModel');
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        if (firebaseUid != null) 'firebase_uid': firebaseUid,
        if (telefono != null) 'telefono': telefono,
        if (tipoUsuario != null) 'tipo_usuario': tipoUsuario,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
      };

  // Helper: Verificar si tiene rol
  bool tieneRol(String rol) {
    if (roles == null) return false;
    return roles!.contains(rol);
  }

  // Helper: Verificar si es admin
  bool get esAdmin => tieneRol('admin') || role == 'admin';

  // Helper: Verificar si es cliente
  bool get esCliente => tieneRol('cliente') || role == 'cliente';

  // Helper: Verificar si es veterinario
  bool get esVeterinario => tieneRol('veterinario') || role == 'veterinario';
}
