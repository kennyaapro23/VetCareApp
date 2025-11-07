import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vetcare_app/providers/auth_provider.dart';
import 'feed_screen.dart';
import 'citas_screen.dart';
import 'perfil_screen.dart';
import 'qr_screen.dart';
import 'notificaciones_screen.dart';

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  int _currentIndex = 0;

  final _screens = const [
    FeedScreen(),
    CitasScreen(),
    QRScreen(),
    NotificacionesScreen(),
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
          NavigationDestination(icon: Icon(Icons.home), label: 'Inicio'),
          NavigationDestination(icon: Icon(Icons.calendar_today), label: 'Citas'),
          NavigationDestination(icon: Icon(Icons.qr_code), label: 'QR'),
          NavigationDestination(icon: Icon(Icons.notifications), label: 'Notificaciones'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}
