// ...existing code...
class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String message;
  final DateTime? date;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    this.date,
  });

  factory NotificationModel.fromJson(dynamic json) {
    if (json == null) throw ArgumentError('json is null');
    final map = json as Map<String, dynamic>;
    DateTime? parsed;
    final raw = map['fecha'] ?? map['date'] ?? map['created_at'];
    if (raw != null) parsed = DateTime.tryParse(raw.toString());
    return NotificationModel(
      id: (map['id'] ?? '').toString(),
      userId: (map['usuario_id'] ?? map['user_id'] ?? '').toString(),
      title: (map['titulo'] ?? map['title'] ?? '').toString(),
      message: (map['mensaje'] ?? map['message'] ?? '').toString(),
      date: parsed,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'usuario_id': userId,
        'titulo': title,
        'mensaje': message,
        'fecha': date?.toIso8601String(),
      };
}

