import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vetcare_app/providers/auth_provider.dart';
import 'login_screen.dart';
import 'client_home_screen.dart';
import 'vet_home_screen.dart';
import 'receptionist_home_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final user = auth.user;
    if (user == null) return const LoginScreen();

    final role = user.role.toLowerCase();
    if (role.contains('cliente') || role.contains('client')) {
      return const ClientHomeScreen();
    }
    if (role.contains('vet') || role.contains('veterinario') || role.contains('veterinarian')) {
      return const VetHomeScreen();
    }
    if (role.contains('recep') || role.contains('recepcionista') || role.contains('receptionist')) {
      return const ReceptionistHomeScreen();
    }

    // Fallback
    return const ClientHomeScreen();
  }
}
