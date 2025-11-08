import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vetcare_app/providers/auth_provider.dart';
import 'package:vetcare_app/providers/theme_provider.dart';
import 'package:vetcare_app/router/app_router.dart';
import 'package:vetcare_app/theme/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:intl/date_symbol_data_local.dart';

// Handler para mensajes en background
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('📩 Mensaje en background: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🌐 Inicializar localización de fechas (español)
  await initializeDateFormatting('es', null);

  // 🔥 Desactivar descarga de fuentes (evita error de red)
  // GoogleFonts.config.allowRuntimeFetching = false;

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
  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final router = AppRouter(authProvider).router;

    return MaterialApp.router(
      title: 'VetCare',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      routerConfig: router,
    );
  }
}
