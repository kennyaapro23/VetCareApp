import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vetcare_app/providers/auth_provider.dart';
import 'package:vetcare_app/models/appointment_model.dart';
import 'package:vetcare_app/services/appointment_service.dart';
import 'package:vetcare_app/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'calendar_appointment_screen.dart';
import 'package:go_router/go_router.dart';

class CitasScreen extends StatefulWidget {
  const CitasScreen({super.key});

  @override
  State<CitasScreen> createState() => _CitasScreenState();
}

class _CitasScreenState extends State<CitasScreen> {
  String _filterStatus = 'todas';
  List<AppointmentModel> _appointments = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    setState(() => _loading = true);
    try {
      final auth = context.read<AuthProvider>();
      final service = AppointmentService(auth.api);
      final status = _filterStatus == 'todas' ? null : _filterStatus;
      final data = await service.getAppointments(status: status);
      if (mounted) {
        setState(() {
          _appointments = data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorColor),
        );
      }
    }
  }

  Future<void> _cancelAppointment(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar cita'),
        content: const Text('¿Estás seguro de cancelar esta cita?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final auth = context.read<AuthProvider>();
        final service = AppointmentService(auth.api);
        await service.cancelAppointment(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cita cancelada'),
              backgroundColor: AppTheme.warningColor,
            ),
          );
          _loadAppointments();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorColor),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Column(
        children: [
          _buildFilters(isDark),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
                : _appointments.isEmpty
                    ? _buildEmptyState(isDark)
                    : RefreshIndicator(
                        onRefresh: _loadAppointments,
                        color: AppTheme.primaryColor,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _appointments.length,
                          itemBuilder: (context, i) => _AppointmentCard(
                            appointment: _appointments[i],
                            isDark: isDark,
                            onCancel: () => _cancelAppointment(_appointments[i].id),
                          ),
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CalendarAppointmentScreen(),
            ),
          );
          _loadAppointments();
        },
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add),
        label: const Text('Agendar Cita'),
      ),
    );
  }

  Widget _buildFilters(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('Todas', 'todas', isDark),
            _buildFilterChip('Pendiente', 'pendiente', isDark),
            _buildFilterChip('Confirmada', 'confirmada', isDark),
            _buildFilterChip('Atendida', 'atendida', isDark),
            _buildFilterChip('Cancelada', 'cancelada', isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, bool isDark) {
    final selected = _filterStatus == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (val) {
          setState(() => _filterStatus = value);
          _loadAppointments();
        },
        selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
        checkmarkColor: AppTheme.primaryColor,
        labelStyle: TextStyle(
          color: selected ? AppTheme.primaryColor : null,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today_outlined, size: 80, color: AppTheme.textSecondary),
          const SizedBox(height: 16),
          Text(
            _filterStatus == 'todas'
                ? 'No tienes citas programadas'
                : 'No hay citas con estado "$_filterStatus"',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Presiona el botón "+" para agendar una cita',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
  final VoidCallback onCancel;

  const _AppointmentCard({
    required this.appointment,
    required this.isDark,
    required this.onCancel,
  });

  void _navigateToPetProfile(BuildContext context) {
    if (appointment.petId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se puede abrir el perfil: ID de mascota no disponible'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }
    
    // Navegar al perfil de la mascota usando GoRouter
    context.go('/pet-detail/${appointment.petId}');
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = appointment.date != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(appointment.date!)
        : 'Sin fecha';

    Color statusColor = AppTheme.textSecondary;
    if (appointment.status == 'pendiente') statusColor = AppTheme.warningColor;
    if (appointment.status == 'confirmada') statusColor = AppTheme.primaryColor;
    if (appointment.status == 'atendida') statusColor = AppTheme.successColor;
    if (appointment.status == 'cancelada') statusColor = AppTheme.errorColor;

    return InkWell(
      onTap: () => _navigateToPetProfile(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    appointment.status ?? 'Sin estado',
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                if (appointment.status == 'pendiente')
                  IconButton(
                    icon: const Icon(Icons.cancel_outlined),
                    color: AppTheme.errorColor,
                    onPressed: onCancel,
                    tooltip: 'Cancelar cita',
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  dateStr,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            if (appointment.reason != null) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.notes, size: 16, color: AppTheme.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      appointment.reason!,
                      style: TextStyle(
                        color: isDark ? AppTheme.textSecondary : AppTheme.textLight,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.touch_app, size: 14, color: AppTheme.primaryColor),
                const SizedBox(width: 4),
                Text(
                  'Toca para ver perfil de la mascota',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.primaryColor,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
    );
  }
}
