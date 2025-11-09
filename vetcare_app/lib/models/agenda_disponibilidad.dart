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

    // Convertir dia_semana: si es número (0-6), convertir a nombre en español
    String? diaSemanaStr;
    final diaSemanaRaw = map['dia_semana'] ?? map['day'];
    if (diaSemanaRaw != null) {
      if (diaSemanaRaw is int) {
        // Backend devuelve número: 0=Domingo, 1=Lunes, etc
        diaSemanaStr = _convertirNumeroADia(diaSemanaRaw);
      } else {
        // Backend devuelve string
        diaSemanaStr = diaSemanaRaw.toString();
      }
    }

    return AgendaDisponibilidad(
      id: map['id']?.toString(),
      veterinarioId: (map['veterinario_id'] ?? map['veterinarian_id'])?.toString(),
      diaSemana: diaSemanaStr,
      horaInicio: (map['hora_inicio'] ?? map['start_time'])?.toString(),
      horaFin: (map['hora_fin'] ?? map['end_time'])?.toString(),
      disponible: map['disponible'] ?? map['available'] ?? map['activo'] ?? true,
    );
  }

  /// Convertir número de día a nombre en español
  static String _convertirNumeroADia(int numero) {
    const mapa = {
      0: 'domingo',
      1: 'lunes',
      2: 'martes',
      3: 'miércoles',
      4: 'jueves',
      5: 'viernes',
      6: 'sábado',
    };
    return mapa[numero] ?? 'lunes';
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

