import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vetcare_app/providers/auth_provider.dart';
import 'package:vetcare_app/services/disponibilidad_service.dart';
import 'package:vetcare_app/models/agenda_disponibilidad.dart';
import 'package:vetcare_app/theme/app_theme.dart';

class VetScheduleScreen extends StatefulWidget {
  const VetScheduleScreen({super.key});

  @override
  State<VetScheduleScreen> createState() => _VetScheduleScreenState();
}

class _VetScheduleScreenState extends State<VetScheduleScreen> {
  List<AgendaDisponibilidad> _horarios = [];
  bool _isLoading = true;
  String? _error;

  final Map<String, String> _diasSemana = {
    'lunes': 'Lunes',
    'martes': 'Martes',
    'miércoles': 'Miércoles',
    'jueves': 'Jueves',
    'viernes': 'Viernes',
    'sábado': 'Sábado',
    'domingo': 'Domingo',
  };

  @override
  void initState() {
    super.initState();
    _loadHorarios();
  }

  Future<void> _loadHorarios() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final auth = context.read<AuthProvider>();
      // Usar veterinarioId si existe, sino usar el user id
      final vetId = auth.user?.veterinarioId ?? auth.user?.id;

      if (vetId == null) {
        throw Exception('No se encontró el ID del veterinario');
      }

      final service = DisponibilidadService(auth.api);
      final horarios = await service.getDisponibilidad(vetId);

      if (mounted) {
        setState(() {
          _horarios = horarios;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  /// Convertir día de español a número (0=Domingo, 1=Lunes, etc)
  int _convertirDiaANumero(String dia) {
    const mapa = {
      'domingo': 0,
      'lunes': 1,
      'martes': 2,
      'miércoles': 3,
      'jueves': 4,
      'viernes': 5,
      'sábado': 6,
    };
    return mapa[dia.toLowerCase()] ?? 1; // Default: Lunes
  }

  /// Convertir número a día en español
  String _convertirNumeroADia(int numero) {
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Agenda'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadHorarios,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : _error != null
              ? _buildErrorState(isDark)
              : _horarios.isEmpty
                  ? _buildEmptyState(isDark)
                  : _buildScheduleList(isDark),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddHorarioDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Agregar Horario'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: AppTheme.errorColor,
            ),
            const SizedBox(height: 16),
            const Text(
              'Error al cargar horarios',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Error desconocido',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? AppTheme.textSecondary : AppTheme.textLight,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadHorarios,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 80,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(height: 16),
            const Text(
              'Sin horarios configurados',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Agrega tu disponibilidad para que los clientes puedan agendar citas contigo',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? AppTheme.textSecondary : AppTheme.textLight,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showAddHorarioDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Agregar Primer Horario'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleList(bool isDark) {
    // Agrupar horarios por día
    final horariosAgrupados = <String, List<AgendaDisponibilidad>>{};
    for (final horario in _horarios) {
      final dia = horario.diaSemana?.toLowerCase() ?? 'sin_dia';
      if (!horariosAgrupados.containsKey(dia)) {
        horariosAgrupados[dia] = [];
      }
      horariosAgrupados[dia]!.add(horario);
    }

    // Ordenar días
    final diasOrdenados = _diasSemana.keys
        .where((dia) => horariosAgrupados.containsKey(dia))
        .toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: diasOrdenados.length,
      itemBuilder: (context, index) {
        final dia = diasOrdenados[index];
        final horarios = horariosAgrupados[dia]!;
        
        return _buildDayCard(dia, horarios, isDark);
      },
    );
  }

  Widget _buildDayCard(String dia, List<AgendaDisponibilidad> horarios, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withValues(alpha: 0.2),
                  AppTheme.accentColor.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _diasSemana[dia] ?? dia.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${horarios.length} horario${horarios.length != 1 ? 's' : ''}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...horarios.map((horario) => _buildHorarioTile(horario, isDark)),
        ],
      ),
    );
  }

  Widget _buildHorarioTile(AgendaDisponibilidad horario, bool isDark) {
    final disponible = horario.disponible ?? true;
    
    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: disponible
              ? AppTheme.successColor.withValues(alpha: 0.1)
              : AppTheme.errorColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          disponible ? Icons.check_circle : Icons.cancel,
          color: disponible ? AppTheme.successColor : AppTheme.errorColor,
        ),
      ),
      title: Text(
        '${horario.horaInicio ?? 'N/A'} - ${horario.horaFin ?? 'N/A'}',
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        disponible ? 'Disponible' : 'No disponible',
        style: TextStyle(
          color: disponible ? AppTheme.successColor : AppTheme.errorColor,
          fontSize: 13,
        ),
      ),
      trailing: PopupMenuButton(
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit, size: 20),
                SizedBox(width: 8),
                Text('Editar'),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'toggle',
            child: Row(
              children: [
                Icon(
                  disponible ? Icons.visibility_off : Icons.visibility,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(disponible ? 'Desactivar' : 'Activar'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete, size: 20, color: AppTheme.errorColor),
                SizedBox(width: 8),
                Text('Eliminar', style: TextStyle(color: AppTheme.errorColor)),
              ],
            ),
          ),
        ],
        onSelected: (value) {
          if (value == 'edit') {
            _showEditHorarioDialog(horario);
          } else if (value == 'toggle') {
            _toggleDisponibilidad(horario);
          } else if (value == 'delete') {
            _confirmDelete(horario);
          }
        },
      ),
    );
  }

  void _showAddHorarioDialog() {
    showDialog(
      context: context,
      builder: (context) => _HorarioDialog(
        onSave: (dia, inicio, fin) {
          _createHorario(dia, inicio, fin);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _showEditHorarioDialog(AgendaDisponibilidad horario) {
    showDialog(
      context: context,
      builder: (context) => _HorarioDialog(
        horario: horario,
        onSave: (dia, inicio, fin) {
          _updateHorario(horario.id!, dia, inicio, fin);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  Future<void> _createHorario(String dia, String inicio, String fin) async {
    try {
      final auth = context.read<AuthProvider>();
      final vetId = auth.user?.veterinarioId ?? auth.user?.id;

      if (vetId == null) {
        throw Exception('No se encontró el ID del veterinario');
      }

      final service = DisponibilidadService(auth.api);
      
      // Convertir día de español a número (backend espera int)
      final diaNumero = _convertirDiaANumero(dia);
      
      await service.createDisponibilidad(vetId, {
        'dia_semana': diaNumero, // int (0-6)
        'hora_inicio': inicio, // string "HH:mm"
        'hora_fin': fin, // string "HH:mm"
        'intervalo_minutos': 30, // int
        'activo': true, // bool
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Horario creado exitosamente'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        _loadHorarios();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear horario: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _updateHorario(String id, String dia, String inicio, String fin) async {
    try {
      final auth = context.read<AuthProvider>();
      final vetId = auth.user?.veterinarioId ?? auth.user?.id;

      if (vetId == null) {
        throw Exception('No se encontró el ID del veterinario');
      }

      final service = DisponibilidadService(auth.api);
      
      // Convertir día de español a número
      final diaNumero = _convertirDiaANumero(dia);
      
      await service.updateDisponibilidad(vetId, id, {
        'dia_semana': diaNumero, // int (0-6)
        'hora_inicio': inicio, // string "HH:mm"
        'hora_fin': fin, // string "HH:mm"
        'intervalo_minutos': 30, // int
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Horario actualizado exitosamente'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        _loadHorarios();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar horario: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _toggleDisponibilidad(AgendaDisponibilidad horario) async {
    try {
      final auth = context.read<AuthProvider>();
      final vetId = auth.user?.veterinarioId ?? auth.user?.id;

      if (vetId == null || horario.id == null) {
        throw Exception('Datos incompletos');
      }

      final newDisponible = !(horario.disponible ?? true);
      final service = DisponibilidadService(auth.api);
      await service.toggleDisponibilidad(vetId, horario.id!, newDisponible);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newDisponible
                  ? '✅ Horario activado'
                  : '⚠️ Horario desactivado',
            ),
            backgroundColor: newDisponible
                ? AppTheme.successColor
                : AppTheme.warningColor,
          ),
        );
        _loadHorarios();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cambiar disponibilidad: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _confirmDelete(AgendaDisponibilidad horario) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Horario'),
        content: Text(
          '¿Estás seguro de eliminar el horario ${horario.horaInicio} - ${horario.horaFin}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true && horario.id != null) {
      _deleteHorario(horario.id!);
    }
  }

  Future<void> _deleteHorario(String id) async {
    try {
      final auth = context.read<AuthProvider>();
      final vetId = auth.user?.veterinarioId ?? auth.user?.id;

      if (vetId == null) {
        throw Exception('No se encontró el ID del veterinario');
      }

      final service = DisponibilidadService(auth.api);
      await service.deleteDisponibilidad(vetId, id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Horario eliminado exitosamente'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        _loadHorarios();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar horario: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
}

// Dialog para crear/editar horario
class _HorarioDialog extends StatefulWidget {
  final AgendaDisponibilidad? horario;
  final Function(String dia, String inicio, String fin) onSave;

  const _HorarioDialog({
    this.horario,
    required this.onSave,
  });

  @override
  State<_HorarioDialog> createState() => _HorarioDialogState();
}

class _HorarioDialogState extends State<_HorarioDialog> {
  late String _selectedDia;
  late TimeOfDay _horaInicio;
  late TimeOfDay _horaFin;

  final List<String> _dias = [
    'lunes',
    'martes',
    'miércoles',
    'jueves',
    'viernes',
    'sábado',
    'domingo',
  ];

  @override
  void initState() {
    super.initState();
    _selectedDia = widget.horario?.diaSemana?.toLowerCase() ?? 'lunes';
    _horaInicio = _parseTime(widget.horario?.horaInicio ?? '09:00');
    _horaFin = _parseTime(widget.horario?.horaFin ?? '17:00');
  }

  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 9,
      minute: int.tryParse(parts[1]) ?? 0,
    );
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.horario == null ? 'Agregar Horario' : 'Editar Horario'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Día de la semana', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedDia,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: _dias.map((dia) {
                return DropdownMenuItem(
                  value: dia,
                  child: Text(dia[0].toUpperCase() + dia.substring(1)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedDia = value);
                }
              },
            ),
            const SizedBox(height: 16),
            const Text('Hora de inicio', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              leading: const Icon(Icons.access_time),
              title: Text(_formatTime(_horaInicio)),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: _horaInicio,
                );
                if (time != null) {
                  setState(() => _horaInicio = time);
                }
              },
            ),
            const SizedBox(height: 16),
            const Text('Hora de fin', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              leading: const Icon(Icons.access_time),
              title: Text(_formatTime(_horaFin)),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: _horaFin,
                );
                if (time != null) {
                  setState(() => _horaFin = time);
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onSave(
              _selectedDia,
              _formatTime(_horaInicio),
              _formatTime(_horaFin),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
          ),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
