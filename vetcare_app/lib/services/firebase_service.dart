import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'api_service.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final ApiService _apiService = ApiService();
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Constructor: Inicializar notificaciones
  FirebaseService() {
    _initializeNotifications();
  }

  // ==================== AUTENTICACIÓN ====================

  /// Registrar usuario con email y password
  Future<Map<String, dynamic>> registerWithEmail({
    required String email,
    required String password,
    required String nombre,
    String rol = 'cliente',
  }) async {
    try {
      // 1. Crear usuario en Firebase
      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Actualizar nombre en Firebase
      await userCredential.user?.updateDisplayName(nombre);

      // 3. Obtener ID Token
      final String? idToken = await userCredential.user?.getIdToken();

      if (idToken == null) {
        throw Exception('No se pudo obtener el token de Firebase');
      }

      // 4. Sincronizar con backend Laravel
      final response = await _apiService.verifyAndSync(
        firebaseToken: idToken,
        nombre: nombre,
        email: email,
        rol: rol,
      );

      // 5. Registrar token FCM
      await _registerFcmToken(response['sanctum_token']);

      return response;
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleFirebaseError(e));
    }
  }

  /// Login con email y password
  Future<Map<String, dynamic>> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      // 1. Autenticar en Firebase
      final UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Obtener ID Token
      final String? idToken = await userCredential.user?.getIdToken();

      if (idToken == null) {
        throw Exception('No se pudo obtener el token de Firebase');
      }

      // 3. Sincronizar con backend Laravel
      final response = await _apiService.verifyAndSync(
        firebaseToken: idToken,
      );

      // 4. Registrar token FCM
      await _registerFcmToken(response['sanctum_token']);

      return response;
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleFirebaseError(e));
    }
  }

  /// Login con Google
  Future<Map<String, dynamic>> loginWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        throw Exception('Login cancelado');
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      final String? idToken = await userCredential.user?.getIdToken();

      if (idToken == null) {
        throw Exception('No se pudo obtener el token');
      }

      final response = await _apiService.verifyAndSync(
        firebaseToken: idToken,
        nombre: userCredential.user?.displayName,
        email: userCredential.user?.email,
      );

      await _registerFcmToken(response['sanctum_token']);

      return response;
    } catch (e) {
      throw Exception('Error en login con Google: $e');
    }
  }

  /// Cerrar sesión
  Future<void> logout(String sanctumToken) async {
    try {
      // 1. Cerrar sesión en Laravel (revocar token Sanctum)
      await _apiService.logout(sanctumToken);

      // 2. Cerrar sesión en Firebase
      await _auth.signOut();

      debugPrint('✅ Sesión cerrada correctamente');
    } catch (e) {
      debugPrint('❌ Error al cerrar sesión: $e');
      rethrow;
    }
  }

  // ==================== NOTIFICACIONES ====================

  /// Inicializar sistema de notificaciones
  Future<void> _initializeNotifications() async {
    // 1. Solicitar permisos
    final NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('✅ Permisos de notificaciones concedidos');

      // 2. Configurar notificaciones locales
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(initSettings);

      // 3. Configurar listeners
      _setupNotificationListeners();
    }
  }

  /// Configurar listeners de notificaciones
  void _setupNotificationListeners() {
    // Foreground (app abierto)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📩 Notificación recibida (foreground): ${message.notification?.title}');
      _showLocalNotification(message);
    });

    // Background (app en segundo plano)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('📱 Notificación tocada (background): ${message.notification?.title}');
      _handleNotificationClick(message);
    });

    // Terminated (app cerrado)
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        debugPrint('🚀 App abierto desde notificación: ${message.notification?.title}');
        _handleNotificationClick(message);
      }
    });
  }

  /// Mostrar notificación local
  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'veterinaria_channel',
      'Notificaciones Veterinaria',
      channelDescription: 'Canal para notificaciones de la app',
      importance: Importance.high,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'Nueva notificación',
      message.notification?.body ?? '',
      details,
    );
  }

  /// Manejar click en notificación
  void _handleNotificationClick(RemoteMessage message) {
    final data = message.data;

    if (data['type'] == 'cita') {
      debugPrint('Navegar a cita ID: ${data['cita_id']}');
    } else if (data['type'] == 'mascota') {
      debugPrint('Navegar a mascota ID: ${data['mascota_id']}');
    }
  }

  /// Registrar token FCM en backend
  Future<void> _registerFcmToken(String sanctumToken) async {
    try {
      final String? fcmToken = await _messaging.getToken();

      if (fcmToken != null) {
        await _apiService.registerFcmToken(
          sanctumToken: sanctumToken,
          fcmToken: fcmToken,
        );
        debugPrint('✅ Token FCM registrado: $fcmToken');
      }
    } catch (e) {
      debugPrint('❌ Error al registrar token FCM: $e');
    }
  }

  // ==================== HELPERS ====================

  /// Manejar errores de Firebase Auth
  String _handleFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'La contraseña es muy débil';
      case 'email-already-in-use':
        return 'El email ya está registrado';
      case 'user-not-found':
        return 'Usuario no encontrado';
      case 'wrong-password':
        return 'Contraseña incorrecta';
      case 'invalid-email':
        return 'Email inválido';
      case 'user-disabled':
        return 'Usuario deshabilitado';
      default:
        return 'Error: ${e.message}';
    }
  }

  /// Obtener usuario actual
  User? get currentUser => _auth.currentUser;

  /// Stream del estado de autenticación
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}

