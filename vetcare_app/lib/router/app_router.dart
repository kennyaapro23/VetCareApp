import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vetcare_app/providers/auth_provider.dart';
import 'package:vetcare_app/screens/login_screen.dart';
import 'package:vetcare_app/screens/register_screen.dart';
import 'package:vetcare_app/screens/client_home_screen.dart';
import 'package:vetcare_app/screens/vet_home_screen.dart';
import 'package:vetcare_app/screens/receptionist_home_screen.dart';
import 'package:vetcare_app/screens/citas_screen.dart';
import 'package:vetcare_app/screens/servicios_screen.dart';
import 'package:vetcare_app/screens/qr_screen.dart';
import 'package:vetcare_app/screens/notificaciones_screen.dart';
import 'package:vetcare_app/screens/perfil_screen.dart';
import 'package:vetcare_app/screens/feed_screen.dart';

class AppRouter {
  final AuthProvider authProvider;

  AppRouter(this.authProvider);

  GoRouter get router => GoRouter(
        initialLocation: '/splash',
        redirect: (context, state) {
          final isLoading = authProvider.isLoading;
          final user = authProvider.user;
          final location = state.matchedLocation;

          debugPrint('🔀 Router redirect: location=$location, isLoading=$isLoading, user=${user?.email}, role=${user?.role}');

          // Si está cargando, mostrar splash
          if (isLoading) {
            return location == '/splash' ? null : '/splash';
          }

          // Si terminó de cargar y está en splash, redirigir según estado
          if (location == '/splash') {
            return user != null ? '/home' : '/login';
          }

          // Si no hay usuario y no está en pantallas públicas, ir a login
          final isPublicRoute = location == '/login' || location == '/register';
          if (user == null && !isPublicRoute) {
            return '/login';
          }

          // Si hay usuario y está en pantallas públicas, ir a home
          if (user != null && isPublicRoute) {
            return '/home';
          }

          return null;
        },
        refreshListenable: authProvider,
        routes: [
          GoRoute(
            path: '/splash',
            pageBuilder: (context, state) => _buildPageWithFadeTransition(
              context,
              state,
              const _SplashScreen(),
            ),
          ),
          GoRoute(
            path: '/login',
            pageBuilder: (context, state) => _buildPageWithFadeTransition(
              context,
              state,
              const LoginScreen(),
            ),
          ),
          GoRoute(
            path: '/register',
            pageBuilder: (context, state) => _buildPageWithSlideTransition(
              context,
              state,
              const RegisterScreen(),
            ),
          ),
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) => _buildPageWithFadeTransition(
              context,
              state,
              _getHomeScreenForRole(),
            ),
          ),
          GoRoute(
            path: '/feed',
            pageBuilder: (context, state) => _buildPageWithFadeTransition(
              context,
              state,
              const FeedScreen(),
            ),
          ),
          GoRoute(
            path: '/citas',
            pageBuilder: (context, state) => _buildPageWithSlideTransition(
              context,
              state,
              const CitasScreen(),
            ),
          ),
          GoRoute(
            path: '/servicios',
            pageBuilder: (context, state) => _buildPageWithSlideTransition(
              context,
              state,
              const ServiciosScreen(),
            ),
          ),
          GoRoute(
            path: '/qr',
            pageBuilder: (context, state) => _buildPageWithScaleTransition(
              context,
              state,
              const QRScreen(),
            ),
          ),
          GoRoute(
            path: '/notificaciones',
            pageBuilder: (context, state) => _buildPageWithSlideTransition(
              context,
              state,
              const NotificacionesScreen(),
            ),
          ),
          GoRoute(
            path: '/perfil',
            pageBuilder: (context, state) => _buildPageWithFadeTransition(
              context,
              state,
              const PerfilScreen(),
            ),
          ),
        ],
      );

  Widget _getHomeScreenForRole() {
    final user = authProvider.user;
    debugPrint('🏠 Seleccionando home para usuario: ${user?.email}, role=${user?.role}, roles=${user?.roles}');

    // Si el modelo tiene helpers, úsalos primero
    if (user != null) {
      try {
        if (user.esVeterinario) {
          debugPrint('✅ Usuario marcado como veterinario (helper) - asignando VetHomeScreen');
          return const VetHomeScreen();
        }
      } catch (e) {
        // ignorar si el helper no existe por alguna razón
      }

      final roleStr = user.role.toLowerCase().trim();
      if (roleStr == 'veterinario' || roleStr.contains('vet')) {
        debugPrint('✅ Asignando VetHomeScreen (por role string)');
        return const VetHomeScreen();
      }
      if (roleStr == 'recepcion' || roleStr.contains('recep')) {
        debugPrint('✅ Asignando ReceptionistHomeScreen (por role string)');
        return const ReceptionistHomeScreen();
      }
    }

    // Por defecto: cliente
    debugPrint('✅ Asignando ClientHomeScreen (default)');
    return const ClientHomeScreen();
  }

  // Transición fade
  CustomTransitionPage _buildPageWithFadeTransition(
    BuildContext context,
    GoRouterState state,
    Widget child,
  ) {
    return CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }

  // Transición slide desde la derecha
  CustomTransitionPage _buildPageWithSlideTransition(
    BuildContext context,
    GoRouterState state,
    Widget child,
  ) {
    return CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;
        final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        final offsetAnimation = animation.drive(tween);
        return SlideTransition(position: offsetAnimation, child: child);
      },
    );
  }

  // Transición scale
  CustomTransitionPage _buildPageWithScaleTransition(
    BuildContext context,
    GoRouterState state,
    Widget child,
  ) {
    return CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          ),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
    );
  }
}

// Pantalla de splash simple
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pets,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            const Text(
              'VetCare',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

