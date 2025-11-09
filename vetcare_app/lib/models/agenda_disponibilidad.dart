class AgendaDisponibilidad {
  final String? id;
  final String? veterinarioId;
  final String? diaSemana;
  final String? horaInicio;
  final String? horaFin;
  final bool? disponible;

  AgendaDisponibilidad({
    this.id,
    this.veterinarioId,
    this.diaSemana,
    this.horaInicio,
    this.horaFin,
    this.disponible,
  });

  factory AgendaDisponibilidad.fromJson(dynamic json) {
    if (json == null) throw ArgumentError('json is null');
    final map = json as Map<String, dynamic>;

    return AgendaDisponibilidad(
      id: map['id']?.toString(),
      veterinarioId: (map['veterinario_id'] ?? map['veterinarian_id'])?.toString(),
      diaSemana: (map['dia_semana'] ?? map['day'])?.toString(),
      horaInicio: (map['hora_inicio'] ?? map['start_time'])?.toString(),
      horaFin: (map['hora_fin'] ?? map['end_time'])?.toString(),
      disponible: map['disponible'] ?? map['available'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        if (veterinarioId != null) 'veterinario_id': veterinarioId,
        if (diaSemana != null) 'dia_semana': diaSemana,
        if (horaInicio != null) 'hora_inicio': horaInicio,
        if (horaFin != null) 'hora_fin': horaFin,
        if (disponible != null) 'disponible': disponible,
      };
}

