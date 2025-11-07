import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vetcare_app/providers/auth_provider.dart';
import 'package:vetcare_app/providers/theme_provider.dart';
import 'package:vetcare_app/router/app_router.dart';
import 'package:vetcare_app/theme/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// Handler para mensajes en background
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('📩 Mensaje en background: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 Desactivar descarga de fuentes (evita error de red)
  GoogleFonts.config.allowRuntimeFetching = false;

  // 🔥 Inicializar Firebase
  try {
    await Firebase.initializeApp();
    debugPrint('✅ Firebase inicializado correctamente');

    // Registrar handler de mensajes en background
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('⚠️ Error al inicializar Firebase: $e');
    debugPrint('! Firebase deshabilitado temporalmente');
    debugPrint('Configura google-services.json para habilitar Firebase');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const VetCareApp(),
    ),
  );
}

class VetCareApp extends StatefulWidget {
  const VetCareApp({super.key});

  @override
  State<VetCareApp> createState() => _VetCareAppState();
}

class _VetCareAppState extends State<VetCareApp> {
  late AppRouter _appRouter;

  @override
  void initState() {
    super.initState();
    // Inicializar NotificationService después del primer frame
    // Comentado temporalmente hasta configurar Firebase
    /*
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      NotificationService.setApiService(auth.api);
      NotificationService.initialize().catchError((e) {
        debugPrint('⚠️ Error inicializando notificaciones: $e');
      });
    });
    */
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();

    _appRouter = AppRouter(authProvider);

    return MaterialApp.router(
      title: 'VetCareApp',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme().copyWith(
        textTheme: GoogleFonts.poppinsTextTheme(
          AppTheme.lightTheme().textTheme,
        ),
      ),
      darkTheme: AppTheme.darkTheme().copyWith(
        textTheme: GoogleFonts.poppinsTextTheme(
          AppTheme.darkTheme().textTheme,
        ),
      ),
      themeMode: themeProvider.themeMode,
      routerConfig: _appRouter.router,
    );
  }
}
