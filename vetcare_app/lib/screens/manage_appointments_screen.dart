import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:vetcare_app/models/appointment_model.dart';
import 'package:vetcare_app/models/client_model.dart';
import 'package:vetcare_app/models/veterinarian_model.dart';
import 'package:vetcare_app/services/api_service.dart';
import 'package:vetcare_app/services/appointment_service.dart';
import 'package:vetcare_app/services/client_service.dart';
import 'package:vetcare_app/services/veterinarian_service.dart';
import 'package:vetcare_app/theme/app_theme.dart';
import 'package:intl/intl.dart';

class ManageAppointmentsScreen extends StatefulWidget {
  const ManageAppointmentsScreen({super.key});

  @override
  State<ManageAppointmentsScreen> createState() => _ManageAppointmentsScreenState();
}

class _ManageAppointmentsScreenState extends State<ManageAppointmentsScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  List<AppointmentModel> _appointments = [];
  List<AppointmentModel> _selectedDayAppointments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    setState(() => _isLoading = true);
    try {
      final apiService = context.read<ApiService>();
      final appointmentService = AppointmentService(apiService);
      final appointments = await appointmentService.getAppointments();
      setState(() {
        _appointments = appointments;
        _updateSelectedDayAppointments();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar citas: $e')),
        );
      }
    }
  }

  void _updateSelectedDayAppointments() {
    if (_selectedDay == null) {
      _selectedDayAppointments = [];
      return;
    }
    _selectedDayAppointments = _appointments.where((appointment) {
      if (appointment.date == null) return false;
      return isSameDay(appointment.date, _selectedDay);
    }).toList();
    _selectedDayAppointments.sort((a, b) => a.date!.compareTo(b.date!));
  }

  List<AppointmentModel> _getAppointmentsForDay(DateTime day) {
    return _appointments.where((appointment) {
      if (appointment.date == null) return false;
      return isSameDay(appointment.date, day);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Calendario
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkCard : Colors.white,
                    border: Border(
                      bottom: BorderSide(
                        color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                      ),
                    ),
                  ),
                  child: TableCalendar(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    calendarFormat: _calendarFormat,
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                        _updateSelectedDayAppointments();
                      });
                    },
                    onFormatChanged: (format) {
                      setState(() => _calendarFormat = format);
                    },
                    onPageChanged: (focusedDay) {
                      _focusedDay = focusedDay;
                    },
                    eventLoader: _getAppointmentsForDay,
                    calendarStyle: CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: const BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      markerDecoration: const BoxDecoration(
                        color: AppTheme.secondaryColor,
                        shape: BoxShape.circle,
                      ),
                      markersMaxCount: 1,
                      outsideDaysVisible: false,
                    ),
                    headerStyle: HeaderStyle(
                      formatButtonVisible: true,
                      titleCentered: true,
                      formatButtonShowsNext: false,
                      formatButtonDecoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      formatButtonTextStyle: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                // Estadísticas del día
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkCard : Colors.white,
                    border: Border(
                      bottom: BorderSide(
                        color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _DayStatCard(
                          icon: Icons.event,
                          label: 'Citas',
                          value: _selectedDayAppointments.length.toString(),
                          color: AppTheme.primaryColor,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DayStatCard(
                          icon: Icons.pending,
                          label: 'Pendientes',
                          value: _selectedDayAppointments
                              .where((a) => a.status == 'pendiente')
                              .length
                              .toString(),
                          color: AppTheme.warningColor,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DayStatCard(
                          icon: Icons.check_circle,
                          label: 'Completadas',
                          value: _selectedDayAppointments
                              .where((a) => a.status == 'completada')
                              .length
                              .toString(),
                          color: AppTheme.successColor,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                ),

                // Lista de citas del día
                Expanded(
                  child: _selectedDayAppointments.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.event_busy,
                                size: 64,
                                color: isDark
                                    ? AppTheme.textSecondary
                                    : AppTheme.textLight,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No hay citas para este día',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: isDark
                                      ? AppTheme.textSecondary
                                      : AppTheme.textLight,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadAppointments,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _selectedDayAppointments.length,
                            itemBuilder: (context, index) {
                              final appointment = _selectedDayAppointments[index];
                              return _AppointmentCard(
                                appointment: appointment,
                                isDark: isDark,
                                onTap: () => _showAppointmentDetails(appointment),
                                onCancel: () => _cancelAppointment(appointment),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAppointmentForm(),
        icon: const Icon(Icons.add),
        label: const Text('Nueva Cita'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void _showAppointmentDetails(AppointmentModel appointment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AppointmentDetailsSheet(appointment: appointment),
    );
  }

  Future<void> _cancelAppointment(AppointmentModel appointment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Cita'),
        content: const Text('¿Estás seguro de cancelar esta cita?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Sí, Cancelar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final apiService = context.read<ApiService>();
        final appointmentService = AppointmentService(apiService);
        await appointmentService.cancelAppointment(appointment.id);
        _loadAppointments();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cita cancelada exitosamente')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al cancelar cita: $e')),
          );
        }
      }
    }
  }

  void _showAppointmentForm() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const _AppointmentFormScreen(),
      ),
    );
    if (result == true) {
      _loadAppointments();
    }
  }
}

class _DayStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _DayStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppTheme.textSecondary : AppTheme.textLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onCancel;

  const _AppointmentCard({
    required this.appointment,
    required this.isDark,
    required this.onTap,
    required this.onCancel,
  });

  Color _getStatusColor() {
    switch (appointment.status) {
      case 'completada':
        return AppTheme.successColor;
      case 'cancelada':
        return AppTheme.errorColor;
      case 'en_proceso':
        return AppTheme.warningColor;
      default:
        return AppTheme.primaryColor;
    }
  }

  String _getStatusText() {
    switch (appointment.status) {
      case 'completada':
        return 'Completada';
      case 'cancelada':
        return 'Cancelada';
      case 'en_proceso':
        return 'En Proceso';
      default:
        return 'Pendiente';
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('HH:mm');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Hora
                Container(
                  width: 60,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: _getStatusColor().withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        appointment.date != null
                            ? timeFormat.format(appointment.date!)
                            : '--:--',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              appointment.reason ?? 'Sin motivo',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor().withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _getStatusText(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _getStatusColor(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.pets,
                            size: 14,
                            color: isDark
                                ? AppTheme.textSecondary
                                : AppTheme.textLight,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'ID Mascota: ${appointment.petId}',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? AppTheme.textSecondary
                                  : AppTheme.textLight,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.medical_services,
                            size: 14,
                            color: isDark
                                ? AppTheme.textSecondary
                                : AppTheme.textLight,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'ID Veterinario: ${appointment.veterinarianId}',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? AppTheme.textSecondary
                                  : AppTheme.textLight,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Acciones
                if (appointment.status != 'cancelada' &&
                    appointment.status != 'completada')
                  IconButton(
                    icon: const Icon(Icons.cancel_outlined, color: AppTheme.errorColor),
                    onPressed: onCancel,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AppointmentDetailsSheet extends StatelessWidget {
  final AppointmentModel appointment;

  const _AppointmentDetailsSheet({required this.appointment});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateFormat = DateFormat('EEEE, d MMMM yyyy', 'es');
    final timeFormat = DateFormat('HH:mm');

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Detalles de la Cita',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 24),
          _DetailRow(
            icon: Icons.event,
            label: 'Fecha',
            value: appointment.date != null
                ? dateFormat.format(appointment.date!)
                : 'No especificada',
            isDark: isDark,
          ),
          _DetailRow(
            icon: Icons.access_time,
            label: 'Hora',
            value: appointment.date != null
                ? timeFormat.format(appointment.date!)
                : 'No especificada',
            isDark: isDark,
          ),
          _DetailRow(
            icon: Icons.pets,
            label: 'Mascota',
            value: 'ID: ${appointment.petId}',
            isDark: isDark,
          ),
          _DetailRow(
            icon: Icons.medical_services,
            label: 'Veterinario',
            value: 'ID: ${appointment.veterinarianId}',
            isDark: isDark,
          ),
          _DetailRow(
            icon: Icons.description,
            label: 'Motivo',
            value: appointment.reason ?? 'Sin especificar',
            isDark: isDark,
          ),
          _DetailRow(
            icon: Icons.info,
            label: 'Estado',
            value: appointment.status ?? 'pendiente',
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppTheme.textSecondary : AppTheme.textLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Formulario de Nueva Cita
class _AppointmentFormScreen extends StatefulWidget {
  const _AppointmentFormScreen();

  @override
  State<_AppointmentFormScreen> createState() => _AppointmentFormScreenState();
}

class _AppointmentFormScreenState extends State<_AppointmentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String? _selectedClientId;
  String? _selectedPetId;
  String? _selectedVetId;
  final TextEditingController _reasonController = TextEditingController();

  List<ClientModel> _clients = [];
  List<VeterinarianModel> _vets = [];
  bool _isLoading = false;
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final apiService = context.read<ApiService>();
      final clientService = ClientService(apiService);
      final vetService = VeterinarianService(apiService);

      final clients = await clientService.getClients();
      final vets = await vetService.getVeterinarians();

      setState(() {
        _clients = clients;
        _vets = vets;
        _isLoadingData = false;
      });
    } catch (e) {
      setState(() => _isLoadingData = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar datos: $e')),
        );
      }
    }
  }

  Future<void> _saveAppointment() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPetId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una mascota')),
      );
      return;
    }
    if (_selectedVetId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un veterinario')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final dateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final apiService = context.read<ApiService>();
      final appointmentService = AppointmentService(apiService);

      await appointmentService.createAppointment({
        'mascota_id': _selectedPetId,
        'veterinario_id': _selectedVetId,
        'fecha': dateTime.toIso8601String(),
        'motivo': _reasonController.text.trim(),
        'estado': 'pendiente',
      });

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cita creada exitosamente')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Nueva Cita'),
      ),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Cliente
                  DropdownButtonFormField<String>(
                    initialValue: _selectedClientId,
                    decoration: InputDecoration(
                      labelText: 'Cliente *',
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: _clients.map((client) {
                      return DropdownMenuItem(
                        value: client.id,
                        child: Text(client.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedClientId = value;
                        _selectedPetId = null;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  // Mascota
                  DropdownButtonFormField<String>(
                    key: ValueKey(_selectedClientId),
                    initialValue: _selectedPetId,
                    decoration: InputDecoration(
                      labelText: 'Mascota *',
                      prefixIcon: const Icon(Icons.pets),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: _selectedClientId != null
                        ? _clients
                            .firstWhere((c) => c.id == _selectedClientId)
                            .pets
                            .map((pet) {
                            return DropdownMenuItem(
                              value: pet.id,
                              child: Text(pet.name),
                            );
                          }).toList()
                        : [],
                    onChanged: (value) {
                      setState(() => _selectedPetId = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  // Veterinario
                  DropdownButtonFormField<String>(
                    initialValue: _selectedVetId,
                    decoration: InputDecoration(
                      labelText: 'Veterinario *',
                      prefixIcon: const Icon(Icons.medical_services),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: _vets.map((vet) {
                      return DropdownMenuItem(
                        value: vet.id,
                        child: Text(vet.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedVetId = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  // Fecha
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('Fecha'),
                    subtitle: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() => _selectedDate = date);
                      }
                    },
                  ),
                  const Divider(),
                  // Hora
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.access_time),
                    title: const Text('Hora'),
                    subtitle: Text(_selectedTime.format(context)),
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: _selectedTime,
                      );
                      if (time != null) {
                        setState(() => _selectedTime = time);
                      }
                    },
                  ),
                  const Divider(),
                  const SizedBox(height: 16),
                  // Motivo
                  TextFormField(
                    controller: _reasonController,
                    decoration: InputDecoration(
                      labelText: 'Motivo de la cita',
                      prefixIcon: const Icon(Icons.description),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveAppointment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Crear Cita',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }
}

