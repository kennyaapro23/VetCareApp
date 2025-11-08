import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:vetcare_app/models/appointment_model.dart';
import 'package:vetcare_app/providers/auth_provider.dart';
import 'package:vetcare_app/services/appointment_service.dart';
import 'citas_screen.dart';
import 'servicios_screen.dart';
import 'qr_screen.dart';
import 'perfil_screen.dart';

class VetHomeScreen extends StatefulWidget {
  const VetHomeScreen({super.key});

  @override
  State<VetHomeScreen> createState() => _VetHomeScreenState();
}

class _VetHomeScreenState extends State<VetHomeScreen> {
  int _currentIndex = 0;

  final _screens = const [
    _VetDashboard(),
    CitasScreen(),
    ServiciosScreen(),
    QRScreen(),
    PerfilScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Panel'),
          NavigationDestination(icon: Icon(Icons.calendar_today), label: 'Citas'),
          NavigationDestination(icon: Icon(Icons.medical_services), label: 'Servicios'),
          NavigationDestination(icon: Icon(Icons.qr_code), label: 'QR'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}

class _VetDashboard extends StatefulWidget {
  const _VetDashboard();

  @override
  State<_VetDashboard> createState() => _VetDashboardState();
}

class _VetDashboardState extends State<_VetDashboard> {
  List<AppointmentModel> _appointments = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = context.read<AuthProvider>();
      final service = AppointmentService(auth.api);
      final all = await service.getAppointments();

      // Filtrar citas del día actual
      final today = DateTime.now();
      final filtered = all.where((a) {
        if (a.date == null) return false;
        final d = a.date!;
        return d.year == today.year && d.month == today.month && d.day == today.day;
      }).toList();

      setState(() {
        _appointments = filtered;
        _loading = false;
      });
    } catch (e) {
      debugPrint('❌ Error cargando dashboard citas: $e');
      setState(() {
        _appointments = [];
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Inicio - Veterinario')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : _appointments.isEmpty
                  ? Center(child: Text('No hay citas para hoy', style: theme.textTheme.titleMedium))
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _appointments.length,
                      itemBuilder: (context, i) {
                        final a = _appointments[i];
                        final dateStr = a.date != null ? DateFormat('HH:mm').format(a.date!.toLocal()) : 'Sin hora';
                        Color statusColor = Colors.grey;
                        if (a.status == 'pendiente') statusColor = Colors.orange;
                        if (a.status == 'confirmada') statusColor = Colors.blue;
                        if (a.status == 'atendida') statusColor = Colors.green;
                        if (a.status == 'cancelada') statusColor = Colors.red;

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: statusColor.withOpacity(0.15),
                              child: Icon(Icons.pets, color: statusColor),
                            ),
                            title: Text(a.reason ?? 'Cita'),
                            subtitle: Text('$dateStr - Estado: ${a.status ?? ''}'),
                            trailing: Icon(Icons.chevron_right, color: theme.colorScheme.onSurface),
                            onTap: () {},
                          ),
                        );
                      },
                    ),
    );
  }
}
