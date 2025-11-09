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
import 'package:vetcare_app/screens/pet_detail_screen.dart';
import 'package:vetcare_app/services/pet_service.dart';
import 'package:provider/provider.dart';

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
          GoRoute(
            path: '/pet-detail/:petId',
            pageBuilder: (context, state) {
              final petId = state.pathParameters['petId']!;
              return _buildPageWithSlideTransition(
                context,
                state,
                _PetDetailLoader(petId: petId),
              );
            },
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

// Widget para cargar pet detail desde ID
class _PetDetailLoader extends StatelessWidget {
  final String petId;

  const _PetDetailLoader({required this.petId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _loadPet(context),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          final errorMsg = snapshot.error.toString();
          final isSqlError = errorMsg.contains('SQLSTATE') || errorMsg.contains('relacionado_type');
          
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      isSqlError 
                        ? 'Error de base de datos en el servidor' 
                        : 'Error al cargar mascota',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    if (isSqlError) ...[
                      const Text(
                        'La columna "relacionado_type" no existe en la tabla "archivos".',
                        style: TextStyle(fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Por favor, contacta al administrador del sistema.',
                        style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                        textAlign: TextAlign.center,
                      ),
                    ] else ...[
                      Text(
                        errorMsg.length > 200 ? '${errorMsg.substring(0, 200)}...' : errorMsg,
                        style: const TextStyle(fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Volver'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(title: const Text('No encontrado')),
            body: const Center(
              child: Text('Mascota no encontrada'),
            ),
          );
        }

        return PetDetailScreen(pet: snapshot.data!);
      },
    );
  }

  Future<dynamic> _loadPet(BuildContext context) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final petService = PetService(auth.api);
    return await petService.getPet(petId);
  }
}

