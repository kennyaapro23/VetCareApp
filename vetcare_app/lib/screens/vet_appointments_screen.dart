import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vetcare_app/providers/auth_provider.dart';
import 'package:vetcare_app/services/appointment_service.dart';
import 'package:vetcare_app/services/pet_service.dart';
import 'package:vetcare_app/models/appointment_model.dart';
import 'package:vetcare_app/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'vet_appointment_detail_screen.dart';

class VetAppointmentsScreen extends StatefulWidget {
  const VetAppointmentsScreen({super.key});

  @override
  State<VetAppointmentsScreen> createState() => _VetAppointmentsScreenState();
}

class _VetAppointmentsScreenState extends State<VetAppointmentsScreen> {
  List<AppointmentModel> _appointments = [];
  bool _isLoading = true;
  String _filterStatus = 'todas';

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    setState(() => _isLoading = true);
    try {
      final auth = context.read<AuthProvider>();
      final service = AppointmentService(auth.api);
      final appointments = await service.getAppointments(
        status: _filterStatus == 'todas' ? null : _filterStatus,
      );

      if (mounted) {
        setState(() {
          _appointments = appointments;
          _isLoading = false;
        });
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Column(
        children: [
          // Filtros
          Container(
            padding: const EdgeInsets.all(16),
            color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Todas', 'todas', isDark),
                  _buildFilterChip('Pendiente', 'pendiente', isDark),
                  _buildFilterChip('Confirmada', 'confirmada', isDark),
                  _buildFilterChip('Completada', 'completada', isDark),
                  _buildFilterChip('Cancelada', 'cancelada', isDark),
                ],
              ),
            ),
          ),

          // Lista de citas
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
                : _appointments.isEmpty
                    ? _buildEmptyState(isDark)
                    : RefreshIndicator(
                        onRefresh: _loadAppointments,
                        color: AppTheme.primaryColor,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _appointments.length,
                          itemBuilder: (context, index) {
                            final appointment = _appointments[index];
                            return _AppointmentCard(
                              appointment: appointment,
                              isDark: isDark,
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => VetAppointmentDetailScreen(
                                      appointment: appointment,
                                    ),
                                  ),
                                );
                                _loadAppointments();
                              },
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, bool isDark) {
    final isSelected = _filterStatus == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _filterStatus = value;
          });
          _loadAppointments();
        },
        selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
        checkmarkColor: AppTheme.primaryColor,
        labelStyle: TextStyle(
          color: isSelected ? AppTheme.primaryColor : null,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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
          Text('No hay citas', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            _filterStatus == 'todas'
                ? 'No tienes citas programadas'
                : 'No hay citas con estado: $_filterStatus',
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
  final VoidCallback onTap;

  const _AppointmentCard({
    required this.appointment,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final status = appointment.status ?? 'pendiente';
    final statusColor = _getColorForStatus(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icono de estado
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getIconForStatus(status),
                    color: statusColor,
                    size: 30,
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
                              'Paciente: ${appointment.petId}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: isDark ? AppTheme.textSecondary : AppTheme.textLight,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            appointment.date != null
                                ? DateFormat('dd MMM yyyy', 'es').format(appointment.date!)
                                : 'Fecha pendiente',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? AppTheme.textSecondary : AppTheme.textLight,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: isDark ? AppTheme.textSecondary : AppTheme.textLight,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            appointment.date != null
                                ? DateFormat('HH:mm').format(appointment.date!)
                                : '--:--',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? AppTheme.textSecondary : AppTheme.textLight,
                            ),
                          ),
                        ],
                      ),
                      if (appointment.reason != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          appointment.reason!,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppTheme.textSecondary : AppTheme.textLight,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: isDark ? AppTheme.textSecondary : AppTheme.textLight,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getColorForStatus(String status) {
    switch (status.toLowerCase()) {
      case 'confirmada':
        return AppTheme.successColor;
      case 'pendiente':
        return AppTheme.warningColor;
      case 'completada':
        return AppTheme.primaryColor;
      case 'cancelada':
        return AppTheme.errorColor;
      default:
        return AppTheme.textSecondary;
    }
  }

  IconData _getIconForStatus(String status) {
    switch (status.toLowerCase()) {
      case 'confirmada':
        return Icons.check_circle;
      case 'pendiente':
        return Icons.schedule;
      case 'completada':
        return Icons.task_alt;
      case 'cancelada':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }
}
