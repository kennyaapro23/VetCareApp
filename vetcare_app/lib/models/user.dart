class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? avatarUrl;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.avatarUrl,
  });

  factory UserModel.fromJson(dynamic json) {
    if (json == null) {
      throw ArgumentError('json is null');
    }
    if (json is Map<String, dynamic>) {
      return UserModel(
        id: (json['id'] ?? json['user_id'] ?? '').toString(),
        name: (json['name'] ?? json['full_name'] ?? '').toString(),
        email: (json['email'] ?? '').toString(),
        role: (json['role'] ?? json['rol'] ?? 'cliente').toString(),
        avatarUrl: json['avatar']?.toString() ?? json['avatar_url']?.toString(),
      );
    }
    throw ArgumentError('Invalid json for UserModel');
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        'avatar_url': avatarUrl,
      };
}
