class AgendaDisponibilidad {
  final int? id;
  final int veterinarioId;
  final int diaSemana;
  final String horaInicio;
  final String horaFin;
  final int intervaloMinutos;
  final bool activo;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AgendaDisponibilidad({
    this.id,
    required this.veterinarioId,
    required this.diaSemana,
    required this.horaInicio,
    required this.horaFin,
    this.intervaloMinutos = 30,
    this.activo = true,
    this.createdAt,
    this.updatedAt,
  });

  factory AgendaDisponibilidad.fromJson(Map<String, dynamic> json) {
    return AgendaDisponibilidad(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
      veterinarioId: int.tryParse((json['veterinario_id'] ?? 0).toString()) ?? 0,
      diaSemana: int.tryParse((json['dia_semana'] ?? 0).toString()) ?? 0,
      horaInicio: (json['hora_inicio'] ?? '09:00:00').toString(),
      horaFin: (json['hora_fin'] ?? '18:00:00').toString(),
      intervaloMinutos: int.tryParse((json['intervalo_minutos'] ?? 30).toString()) ?? 30,
      activo: json['activo'] == 1 || json['activo'] == true,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'veterinario_id': veterinarioId,
      'dia_semana': diaSemana,
      'hora_inicio': horaInicio,
      'hora_fin': horaFin,
      'intervalo_minutos': intervaloMinutos,
      'activo': activo,
    };
  }

  String get nombreDia {
    const dias = ['Domingo', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado'];
    return dias[diaSemana % 7];
  }

  String get horarioFormateado {
    final inicio = horaInicio.length >= 5 ? horaInicio.substring(0, 5) : horaInicio;
    final fin = horaFin.length >= 5 ? horaFin.substring(0, 5) : horaFin;
    return '$inicio - $fin';
  }

  List<String> get slotsDisponibles {
    List<String> slots = [];

    final inicioPartes = horaInicio.split(':');
    int horaActual = int.tryParse(inicioPartes[0]) ?? 9;
    int minutoActual = int.tryParse(inicioPartes[1]) ?? 0;

    final finPartes = horaFin.split(':');
    final horaFinInt = int.tryParse(finPartes[0]) ?? 18;
    final minutoFin = int.tryParse(finPartes[1]) ?? 0;

    while (horaActual < horaFinInt || (horaActual == horaFinInt && minutoActual < minutoFin)) {
      slots.add('${horaActual.toString().padLeft(2, '0')}:${minutoActual.toString().padLeft(2, '0')}');

      minutoActual += intervaloMinutos;
      if (minutoActual >= 60) {
        horaActual++;
        minutoActual -= 60;
      }
    }

    return slots;
  }
}

