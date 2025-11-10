import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vetcare_app/providers/auth_provider.dart';
import 'package:vetcare_app/services/veterinarian_service.dart';
import 'package:vetcare_app/services/disponibilidad_service.dart';
import 'package:vetcare_app/services/appointment_service.dart';
import 'package:vetcare_app/services/servicio_service.dart';
import 'package:vetcare_app/models/veterinarian_model.dart';
import 'package:vetcare_app/models/agenda_disponibilidad.dart';
import 'package:vetcare_app/models/pet_model.dart';
import 'package:vetcare_app/models/servicio.dart';
import 'package:vetcare_app/services/pet_service.dart';
import 'package:vetcare_app/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarAppointmentScreen extends StatefulWidget {
  const CalendarAppointmentScreen({super.key});

  @override
  State<CalendarAppointmentScreen> createState() => _CalendarAppointmentScreenState();
}

class _CalendarAppointmentScreenState extends State<CalendarAppointmentScreen> {
  // Estado
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  VeterinarianModel? _selectedVet;
  String? _selectedTimeSlot;
  PetModel? _selectedPet;
  List<String> _bookedSlots = []; // Horarios ya reservados (formato HH:mm)
  // Días sin disponibilidad (formato 'yyyy-MM-dd')
  Set<String> _unavailableDays = {};

  List<VeterinarianModel> _veterinarians = [];
  List<PetModel> _pets = [];
  List<Servicio> _servicios = []; // Lista de servicios disponibles
  List<AgendaDisponibilidad> _disponibilidad = [];
  List<String> _availableSlots = [];

  bool _isLoading = false;
  bool _isLoadingSlots = false;
  final _motivoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadVeterinarians();
    _loadPets();
    _loadServicios();
  }

  @override
  void dispose() {
    _motivoController.dispose();
    super.dispose();
  }

  Future<void> _loadVeterinarians() async {
    try {
      final auth = context.read<AuthProvider>();
      final service = VeterinarianService(auth.api);
      final vets = await service.getVeterinarians();
      if (mounted) {
        setState(() {
          _veterinarians = vets;
        });
      }
    } catch (e) {
      debugPrint('Error cargando veterinarios: $e');
    }
  }

  Future<void> _loadPets() async {
    try {
      final auth = context.read<AuthProvider>();
      final service = PetService(auth.api);
      final pets = await service.getPets();
      if (mounted) {
        setState(() {
          _pets = pets;
        });
      }
    } catch (e) {
      debugPrint('Error cargando mascotas: $e');
    }
  }

  Future<void> _loadServicios() async {
    try {
      final auth = context.read<AuthProvider>();
      final service = ServicioService(auth.api);
      debugPrint('🔍 Cargando servicios disponibles...');
      final servicios = await service.getServicios();
      debugPrint('✅ Servicios cargados: ${servicios.length}');
      if (mounted) {
        setState(() {
          _servicios = servicios;
        });
      }
    } catch (e) {
      debugPrint('❌ Error cargando servicios: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cargando servicios: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _loadDisponibilidad(String vetId) async {
    setState(() => _isLoading = true);
    try {
      final auth = context.read<AuthProvider>();
      final service = DisponibilidadService(auth.api);
      final disp = await service.getDisponibilidad(vetId);
      if (mounted) {
        setState(() {
          _disponibilidad = disp;
          _isLoading = false;
        });
          // Si ya hay un día seleccionado, cargar también los horarios reservados para ese día
          if (_selectedDay != null) {
            _loadBookedSlots(vetId, _selectedDay!);
          }
          // Calcular días sin disponibilidad para el calendario
          _computeUnavailableDays(vetId);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorColor),
        );
      }
    }
  }

  void _generateTimeSlots(DateTime day) {
    if (_disponibilidad.isEmpty) return;

    setState(() => _isLoadingSlots = true);

    // Obtener día de la semana en español
    final weekdayMap = {
      1: 'lunes',
      2: 'martes',
      3: 'miércoles',
      4: 'jueves',
      5: 'viernes',
      6: 'sábado',
      7: 'domingo',
    };

    final dayName = weekdayMap[day.weekday];

    // Buscar disponibilidad para ese día
    final dayDisp = _disponibilidad.where((d) =>
      d.diaSemana?.toLowerCase() == dayName
    ).toList();

    List<String> slots = [];

    for (var disp in dayDisp) {
      if (disp.horaInicio != null && disp.horaFin != null) {
        try {
          // Parse horarios
          final startParts = disp.horaInicio!.split(':');
          final endParts = disp.horaFin!.split(':');

          final startHour = int.parse(startParts[0]);
          final startMin = int.parse(startParts[1]);
          final endHour = int.parse(endParts[0]);
          final endMin = int.parse(endParts[1]);

          // Generar slots cada 30 minutos
          var currentTime = DateTime(day.year, day.month, day.day, startHour, startMin);
          final endTime = DateTime(day.year, day.month, day.day, endHour, endMin);

          while (currentTime.isBefore(endTime)) {
            // Solo agregar si es futuro
            if (currentTime.isAfter(DateTime.now())) {
              slots.add(DateFormat('HH:mm').format(currentTime));
            }
            currentTime = currentTime.add(const Duration(minutes: 30));
          }
        } catch (e) {
          debugPrint('Error generando slots: $e');
        }
      }
    }

    setState(() {
      _availableSlots = slots;
      _isLoadingSlots = false;
    });
    // Also load booked slots for this vet/day so occupied slots are marked red
    if (_selectedVet != null) {
      _loadBookedSlots(_selectedVet!.id, day);
    }
  }

  Future<void> _loadBookedSlots(String vetId, DateTime day) async {
    try {
      final auth = context.read<AuthProvider>();
      final service = AppointmentService(auth.api);
      final all = await service.getAppointments();
      final format = DateFormat('HH:mm');
      final booked = <String>[];

      for (final a in all) {
        if (a.veterinarianId == vetId && a.date != null) {
          // Solo considerar citas del mismo día y que no estén canceladas
          if (isSameDay(a.date, day) && (a.status == null || a.status != 'cancelada')) {
            booked.add(format.format(a.date!));
          }
        }
      }

      if (mounted) {
        setState(() => _bookedSlots = booked);
      }
    } catch (e) {
      debugPrint('Error cargando citas reservadas: $e');
    }
  }

  // Compute days without availability (used to mark calendar dates as unavailable/red).
  void _computeUnavailableDays(String vetId) {
    final out = <String>{};
    final now = DateTime.now();
    final daysToCheck = 60; // same range as calendar
    final weekdayMap = {
      1: 'lunes',
      2: 'martes',
      3: 'miércoles',
      4: 'jueves',
      5: 'viernes',
      6: 'sábado',
      7: 'domingo',
    };

    for (var i = 0; i <= daysToCheck; i++) {
      final day = DateTime(now.year, now.month, now.day).add(Duration(days: i));
      final dayName = weekdayMap[day.weekday];
      final dayDisp = _disponibilidad.where((d) => d.diaSemana?.toLowerCase() == dayName).toList();

      bool hasAvailable = false;
      if (dayDisp.isNotEmpty) {
        for (var disp in dayDisp) {
          if (disp.horaInicio != null && disp.horaFin != null) {
            try {
              final startParts = disp.horaInicio!.split(':');
              final endParts = disp.horaFin!.split(':');
              final startHour = int.parse(startParts[0]);
              final startMin = int.parse(startParts[1]);
              final endHour = int.parse(endParts[0]);
              final endMin = int.parse(endParts[1]);

              var currentTime = DateTime(day.year, day.month, day.day, startHour, startMin);
              final endTime = DateTime(day.year, day.month, day.day, endHour, endMin);

              while (currentTime.isBefore(endTime)) {
                if (currentTime.isAfter(now)) {
                  hasAvailable = true;
                  break;
                }
                currentTime = currentTime.add(const Duration(minutes: 30));
              }
            } catch (_) {
              // ignore parse errors
            }
            if (hasAvailable) break;
          }
        }
      }

      if (!hasAvailable) {
        out.add('${day.year.toString().padLeft(4,'0')}-${day.month.toString().padLeft(2,'0')}-${day.day.toString().padLeft(2,'0')}');
      }
    }

    setState(() => _unavailableDays = out);
  }

  Future<void> _confirmAppointment() async {
    if (_selectedVet == null || _selectedDay == null || _selectedTimeSlot == null || _selectedPet == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor completa todos los campos'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    if (_motivoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor indica el motivo de la consulta'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    try {
      final auth = context.read<AuthProvider>();
      final service = AppointmentService(auth.api);

      // Combinar fecha y hora seleccionadas en un único DateTime y convertir a UTC.
      DateTime appointmentDateTime;
      try {
        final parts = _selectedTimeSlot!.split(':');
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        appointmentDateTime = DateTime(
          _selectedDay!.year,
          _selectedDay!.month,
          _selectedDay!.day,
          hour,
          minute,
        );
      } catch (_) {
        appointmentDateTime = DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
      }

      final data = <String, dynamic>{
        'mascota_id': int.parse(_selectedPet!.id),
        'veterinario_id': int.parse(_selectedVet!.id),
        'fecha': appointmentDateTime.toUtc().toIso8601String(), // ISO8601 UTC
        if (_motivoController.text.trim().isNotEmpty) 'motivo': _motivoController.text.trim(),
      };

      // Nota: no enviamos servicios desde este flujo (el backend no los requiere aquí).

      await service.createAppointment(data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Cita agendada exitosamente'),
            backgroundColor: AppTheme.successColor,
          ),
        );

        // Limpiar formulario
        setState(() {
          _selectedDay = null;
          _selectedTimeSlot = null;
          _selectedVet = null;
          _selectedPet = null;
          _availableSlots = [];
          _motivoController.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agendar Cita'),
      ),
      body: _pets.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.pets, size: 80, color: AppTheme.textSecondary),
                  const SizedBox(height: 16),
                  const Text('No tienes mascotas registradas'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Agregar Mascota'),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Paso 1: Seleccionar Mascota
                  _buildSectionTitle('1. Selecciona tu mascota', Icons.pets),
                  const SizedBox(height: 8),
                  _buildPetSelector(isDark),

                  const SizedBox(height: 24),

                  // Paso 2: Seleccionar Veterinario
                  _buildSectionTitle('2. Selecciona un veterinario', Icons.medical_services),
                  const SizedBox(height: 8),
                  _buildVetSelector(isDark),

                  if (_selectedVet != null) ...[
                    const SizedBox(height: 24),

                    // Paso 3: Calendario
                    _buildSectionTitle('3. Selecciona una fecha', Icons.calendar_today),
                    const SizedBox(height: 8),
                    _buildCalendar(isDark),

                    if (_selectedDay != null) ...[
                      const SizedBox(height: 24),

                      // Paso 4: Horarios disponibles
                      _buildSectionTitle('4. Selecciona un horario', Icons.access_time),
                      const SizedBox(height: 8),
                      _buildTimeSlots(isDark),

                      if (_selectedTimeSlot != null) ...[
                        const SizedBox(height: 24),

                        // Paso 5: Motivo
                        _buildSectionTitle('5. Motivo de la consulta', Icons.edit_note),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _motivoController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            hintText: 'Describe el motivo de la consulta...',
                            border: OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 24),
                        // Nota: se removió el selector de servicios del flujo de agendamiento
                        // porque el backend no almacena servicios opcionales en este endpoint.
                        const SizedBox(height: 0),

                        // Botón confirmar
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _confirmAppointment,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text(
                              'CONFIRMAR CITA',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildPetSelector(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
        ),
      ),
      child: Column(
        children: _pets.map((pet) {
          final isSelected = _selectedPet?.id == pet.id;
          return InkWell(
            onTap: () {
              setState(() {
                _selectedPet = pet;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryColor.withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.pets,
                    color: isSelected ? AppTheme.primaryColor : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pet.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isSelected ? AppTheme.primaryColor : null,
                          ),
                        ),
                        Text(
                          '${pet.species} • ${pet.breed}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    const Icon(Icons.check_circle, color: AppTheme.primaryColor),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildVetSelector(bool isDark) {
    if (_veterinarians.isEmpty) {
      return const Center(child: Text('No hay veterinarios disponibles'));
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
        ),
      ),
      child: Column(
        children: _veterinarians.map((vet) {
          final isSelected = _selectedVet?.id == vet.id;
          return InkWell(
            onTap: () {
              setState(() {
                _selectedVet = vet;
                _selectedDay = null;
                _selectedTimeSlot = null;
                _availableSlots = [];
              });
              _loadDisponibilidad(vet.id);
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryColor.withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                    child: const Icon(Icons.medical_services, color: AppTheme.primaryColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vet.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isSelected ? AppTheme.primaryColor : null,
                          ),
                        ),
                        if (vet.especialidad != null)
                          Text(
                            vet.especialidad!,
                            style: const TextStyle(fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    const Icon(Icons.check_circle, color: AppTheme.primaryColor),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCalendar(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
        ),
      ),
      child: TableCalendar(
        locale: 'es_ES',
        firstDay: DateTime.now(),
        lastDay: DateTime.now().add(const Duration(days: 60)),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        calendarFormat: CalendarFormat.month,
        startingDayOfWeek: StartingDayOfWeek.monday,
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          leftChevronIcon: const Icon(Icons.chevron_left, color: AppTheme.primaryColor),
          rightChevronIcon: const Icon(Icons.chevron_right, color: AppTheme.primaryColor),
        ),
        calendarStyle: CalendarStyle(
          selectedDecoration: const BoxDecoration(
            color: AppTheme.primaryColor,
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          // Disabled days (unavailable) will be rendered with an error tint
          disabledDecoration: BoxDecoration(
            color: AppTheme.errorColor.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          disabledTextStyle: TextStyle(
            color: AppTheme.errorColor,
            fontWeight: FontWeight.w700,
          ),
          weekendTextStyle: TextStyle(
            color: isDark ? AppTheme.textSecondary : AppTheme.textLight,
          ),
        ),
        // Disable days that are unavailable according to computed set, or are in the past
        enabledDayPredicate: (day) {
          final key = '${day.year.toString().padLeft(4,'0')}-${day.month.toString().padLeft(2,'0')}-${day.day.toString().padLeft(2,'0')}';
          final today = DateTime.now();
          final dayOnly = DateTime(day.year, day.month, day.day);
          final todayOnly = DateTime(today.year, today.month, today.day);
          // disable past days
          if (dayOnly.isBefore(todayOnly)) return false;
          // disable days marked as unavailable
          if (_unavailableDays.contains(key)) return false;
          return true;
        },
        onDaySelected: (selectedDay, focusedDay) {
          if (selectedDay.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
            return;
          }
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
            _selectedTimeSlot = null;
          });
          _generateTimeSlots(selectedDay);
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
        },
      ),
    );
  }

  Widget _buildTimeSlots(bool isDark) {
    if (_isLoadingSlots) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
    }

    if (_availableSlots.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
          ),
        ),
        child: const Center(
          child: Text('No hay horarios disponibles para este día'),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
        ),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _availableSlots.map((slot) {
          final isSelected = _selectedTimeSlot == slot;
          final isBooked = _bookedSlots.contains(slot);
          return InkWell(
            onTap: isBooked
                ? null
                : () {
                    setState(() {
                      _selectedTimeSlot = slot;
                    });
                  },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryColor
                    : isBooked
                        ? AppTheme.errorColor.withValues(alpha: 0.12)
                        : (isDark ? AppTheme.darkSurface : AppTheme.lightSurface),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : isBooked
                          ? AppTheme.errorColor
                          : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    slot,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : (isBooked ? AppTheme.errorColor : null),
                    ),
                  ),
                  if (isBooked) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.lock, size: 14, color: AppTheme.errorColor),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Servicios selector removed from this flow (not used).
}

