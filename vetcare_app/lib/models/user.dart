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
  final String? veterinarioId; // ID en tabla veterinarios (si es veterinario)

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
    this.veterinarioId,
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
  // El backend puede devolver el rol con varias claves: 'role', 'rol', 'tipo_usuario', 'perfil'
  role: (json['role'] ?? json['rol'] ?? json['tipo_usuario'] ?? json['perfil'] ?? 'cliente').toString(),
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
        roles: _parseRoles(json['roles']),
        veterinarioId: json['veterinario_id']?.toString(),
      );
    }
    throw ArgumentError('Invalid json for UserModel');
  }

  // Helper para parsear roles que pueden venir como lista de strings o lista de objetos
  static List<String>? _parseRoles(dynamic raw) {
    if (raw == null) return null;
    try {
      if (raw is List) {
        final out = <String>[];
        for (final item in raw) {
          if (item is String) {
            out.add(item);
          } else if (item is Map) {
            // intentar varias claves comunes
            if (item.containsKey('name')) out.add(item['name'].toString());
            else if (item.containsKey('rol')) out.add(item['rol'].toString());
            else if (item.containsKey('role')) out.add(item['role'].toString());
            else if (item.containsKey('tipo')) out.add(item['tipo'].toString());
            else if (item.containsKey('tipo_usuario')) out.add(item['tipo_usuario'].toString());
            else {
              // Si es un mapa sin claves conocidas, convertir a string por seguridad
              out.add(item.toString());
            }
          } else {
            out.add(item.toString());
          }
        }
        return out.isNotEmpty ? out : null;
      }
      // Si viene como string separado por comas
      if (raw is String) {
        final parts = raw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
        return parts.isNotEmpty ? parts : null;
      }
    } catch (e) {
      // ignorar y devolver null
    }
    return null;
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
