import 'package:flutter/material.dart';
import 'servicios_screen.dart';
import 'citas_screen.dart';
import 'qr_screen.dart';
import 'perfil_screen.dart';

class ReceptionistHomeScreen extends StatefulWidget {
  const ReceptionistHomeScreen({super.key});

  @override
  State<ReceptionistHomeScreen> createState() => _ReceptionistHomeScreenState();
}

class _ReceptionistHomeScreenState extends State<ReceptionistHomeScreen> {
  int _currentIndex = 0;

  final _screens = const [
    _ReceptionistDashboard(),
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

class _ReceptionistDashboard extends StatelessWidget {
  const _ReceptionistDashboard();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inicio - Recepcionista')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => const CitasScreen()));
              },
              icon: const Icon(Icons.person_add),
              label: const Text('Registrar cliente'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.event),
              label: const Text('Registrar cita'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.medical_services),
              label: const Text('Registrar servicio'),
            ),
            const SizedBox(height: 20),
            const Expanded(
              child: Center(child: Text('Panel de recepcionista — acciones rápidas')),
            )
          ],
        ),
      ),
    );
  }
}
