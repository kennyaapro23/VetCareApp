import 'package:flutter/material.dart';
import 'package:vetcare_app/models/appointment_model.dart';
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

class _VetDashboard extends StatelessWidget {
  const _VetDashboard();

  @override
  Widget build(BuildContext context) {
    // pantalla simple que mostrará lista de citas del día (placeholder)
    final today = DateTime.now();
    final sample = <AppointmentModel>[
      AppointmentModel(id: '1', petId: 'p1', veterinarianId: 'v1', date: today.add(const Duration(hours: 1)), reason: 'Vacunación', status: 'pendiente'),
      AppointmentModel(id: '2', petId: 'p2', veterinarianId: 'v1', date: today.add(const Duration(hours: 3)), reason: 'Consulta general', status: 'confirmada'),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Inicio - Veterinario')),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: sample.length,
        itemBuilder: (context, i) {
          final a = sample[i];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.pets)),
              title: Text(a.reason ?? 'Cita'),
              subtitle: Text('${a.date?.toLocal().toString() ?? ''} - Estado: ${a.status ?? ''}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // abrir detalle
              },
            ),
          );
        },
      ),
    );
  }
}
