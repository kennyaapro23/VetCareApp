# 🎯 CAMBIOS NECESARIOS EN FRONTEND FLUTTER

## 📦 PASO 1: Agregar Dependencias (pubspec.yaml)

Abrir `pubspec.yaml` y agregar:

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Firebase Core (REQUERIDO)
  firebase_core: ^3.6.0
  firebase_auth: ^5.3.1
  firebase_messaging: ^15.1.3
  
  # HTTP para comunicación con Laravel
  http: ^1.2.0
  
  # (Opcional) Para Google Sign-In
  google_sign_in: ^6.2.1
  
  # (Opcional) Para notificaciones locales
  flutter_local_notifications: ^17.2.3
```

Ejecutar:
```bash
flutter pub get
```

---

## 🔧 PASO 2: Configurar Firebase en Flutter

### Android (android/app/google-services.json)

1. Ir a Firebase Console → Tu Proyecto
2. Click en ⚙️ → Configuración del proyecto
3. En "Tus apps" → Click en Android (ícono robot)
4. Descargar `google-services.json`
5. Colocarlo en: `android/app/google-services.json`

### Android Build.gradle

**Archivo:** `android/build.gradle`

```gradle
buildscript {
    dependencies {
        // ... otras dependencias
        classpath 'com.google.gms:google-services:4.4.0'  // 👈 AGREGAR
    }
}
```

**Archivo:** `android/app/build.gradle`

```gradle
// Al final del archivo
apply plugin: 'com.google.gms.google-services'  // 👈 AGREGAR
```

### iOS (ios/Runner/GoogleService-Info.plist)

1. En Firebase Console → Tu Proyecto
2. Click en ⚙️ → Configuración del proyecto
3. En "Tus apps" → Click en iOS (ícono Apple)
4. Descargar `GoogleService-Info.plist`
5. Abrir Xcode → Runner → Arrastrar archivo a Runner folder
6. ✅ Marcar "Copy items if needed"

---

## 📁 PASO 3: Crear Estructura de Archivos

```
lib/
├── main.dart
├── services/
│   ├── firebase_service.dart          👈 CREAR
│   └── api_service.dart                👈 CREAR
├── models/
│   └── user_model.dart                 👈 CREAR
└── screens/
    ├── login_screen.dart               👈 MODIFICAR/CREAR
    ├── register_screen.dart            👈 MODIFICAR/CREAR
    └── home_screen.dart                👈 MODIFICAR/CREAR
```

---

## 🔥 PASO 4: Código Completo de los Servicios

### 4.1 FirebaseService (services/firebase_service.dart)

```dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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
      throw _handleFirebaseError(e);
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
      throw _handleFirebaseError(e);
    }
  }

  /// Login con Google
  Future<Map<String, dynamic>> loginWithGoogle() async {
    try {
      // Nota: Requiere configuración adicional de Google Sign-In
      // Ver FIREBASE_AUTH_GUIDE.md para detalles completos
      
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

      print('✅ Sesión cerrada correctamente');
    } catch (e) {
      print('❌ Error al cerrar sesión: $e');
      throw e;
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
      print('✅ Permisos de notificaciones concedidos');

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
      print('📩 Notificación recibida (foreground): ${message.notification?.title}');
      _showLocalNotification(message);
    });

    // Background (app en segundo plano)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📱 Notificación tocada (background): ${message.notification?.title}');
      _handleNotificationClick(message);
    });

    // Terminated (app cerrado)
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        print('🚀 App abierto desde notificación: ${message.notification?.title}');
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
    // Implementar navegación según el tipo de notificación
    final data = message.data;
    
    if (data['type'] == 'cita') {
      // Navegar a pantalla de citas
      print('Navegar a cita ID: ${data['cita_id']}');
    } else if (data['type'] == 'mascota') {
      // Navegar a pantalla de mascotas
      print('Navegar a mascota ID: ${data['mascota_id']}');
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
        print('✅ Token FCM registrado: $fcmToken');
      }
    } catch (e) {
      print('❌ Error al registrar token FCM: $e');
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
```

### 4.2 ApiService (services/api_service.dart)

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // 🔧 CAMBIAR ESTA URL A TU SERVIDOR
  static const String baseUrl = 'http://10.0.2.2:8000/api'; // Android Emulator
  // static const String baseUrl = 'http://localhost:8000/api'; // iOS Simulator
  // static const String baseUrl = 'https://tu-dominio.com/api'; // Producción

  /// Verificar token Firebase y sincronizar con Laravel
  Future<Map<String, dynamic>> verifyAndSync({
    required String firebaseToken,
    String? nombre,
    String? email,
    String? rol,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/firebase/verify'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'firebase_token': firebaseToken,
          if (nombre != null) 'nombre': nombre,
          if (email != null) 'email': email,
          if (rol != null) 'rol': rol,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Error al verificar token');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Registrar token FCM
  Future<void> registerFcmToken({
    required String sanctumToken,
    required String fcmToken,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/firebase/fcm-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $sanctumToken',
        },
        body: jsonEncode({'fcm_token': fcmToken}),
      );

      if (response.statusCode != 200) {
        print('❌ Error al registrar FCM token: ${response.body}');
      }
    } catch (e) {
      print('❌ Error: $e');
    }
  }

  /// Obtener perfil del usuario
  Future<Map<String, dynamic>> getProfile(String sanctumToken) async {
    final response = await http.get(
      Uri.parse('$baseUrl/firebase/profile'),
      headers: {
        'Authorization': 'Bearer $sanctumToken',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al obtener perfil');
    }
  }

  /// Actualizar perfil
  Future<Map<String, dynamic>> updateProfile({
    required String sanctumToken,
    String? nombre,
    String? telefono,
    String? direccion,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/firebase/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $sanctumToken',
      },
      body: jsonEncode({
        if (nombre != null) 'nombre': nombre,
        if (telefono != null) 'telefono': telefono,
        if (direccion != null) 'direccion': direccion,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al actualizar perfil');
    }
  }

  /// Cerrar sesión
  Future<void> logout(String sanctumToken) async {
    await http.post(
      Uri.parse('$baseUrl/firebase/logout'),
      headers: {
        'Authorization': 'Bearer $sanctumToken',
        'Accept': 'application/json',
      },
    );
  }
}
```

---

## 📱 PASO 5: Pantallas de Login y Registro

### 5.1 Login Screen (screens/login_screen.dart)

```dart
import 'package:flutter/material.dart';
import '../services/firebase_service.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor completa todos los campos')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _firebaseService.loginWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Guardar token Sanctum (usa SharedPreferences o secure_storage)
      // await storage.write(key: 'sanctum_token', value: result['sanctum_token']);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Bienvenido ${result['user']['nombre']}')),
      );

      // Navegar a Home
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      final result = await _firebaseService.loginWithGoogle();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Bienvenido ${result['user']['nombre']}')),
      );

      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Iniciar Sesión')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Contraseña',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            SizedBox(height: 24),
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _login,
                    child: Text('Iniciar Sesión'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 50),
                    ),
                  ),
            SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _isLoading ? null : _loginWithGoogle,
              icon: Icon(Icons.login),
              label: Text('Continuar con Google'),
              style: OutlinedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/register'),
              child: Text('¿No tienes cuenta? Regístrate'),
            ),
          ],
        ),
      ),
    );
  }
}
```

### 5.2 Register Screen (screens/register_screen.dart)

```dart
import 'package:flutter/material.dart';
import '../services/firebase_service.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _register() async {
    if (_nombreController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor completa todos los campos')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _firebaseService.registerWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        nombre: _nombreController.text.trim(),
        rol: 'cliente',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Registro exitoso')),
      );

      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Registro')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _nombreController,
              decoration: InputDecoration(
                labelText: 'Nombre completo',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Contraseña',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            SizedBox(height: 24),
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _register,
                    child: Text('Registrarse'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 50),
                    ),
                  ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('¿Ya tienes cuenta? Inicia sesión'),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 🚀 PASO 6: Inicializar Firebase en main.dart

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 🔥 Inicializar Firebase
  await Firebase.initializeApp();
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Veterinaria App',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/login',
      routes: {
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/home': (context) => HomeScreen(),
      },
    );
  }
}
```

---

## ✅ RESUMEN DE CAMBIOS

| Paso | Acción | Archivo |
|------|--------|---------|
| 1 | Agregar dependencias | `pubspec.yaml` |
| 2 | Configurar Firebase Android | `android/app/google-services.json` |
| 2 | Configurar Firebase iOS | `ios/Runner/GoogleService-Info.plist` |
| 3 | Crear FirebaseService | `lib/services/firebase_service.dart` |
| 3 | Crear ApiService | `lib/services/api_service.dart` |
| 4 | Crear LoginScreen | `lib/screens/login_screen.dart` |
| 4 | Crear RegisterScreen | `lib/screens/register_screen.dart` |
| 5 | Inicializar Firebase | `lib/main.dart` |

---

## 🔧 CONFIGURACIÓN IMPORTANTE

### En `ApiService.baseUrl`:

```dart
// Para Android Emulator
static const String baseUrl = 'http://10.0.2.2:8000/api';

// Para iOS Simulator
static const String baseUrl = 'http://localhost:8000/api';

// Para dispositivo físico (mismo WiFi)
static const String baseUrl = 'http://192.168.1.X:8000/api';

// Para producción
static const String baseUrl = 'https://tu-dominio.com/api';
```

---

## 🧪 PROBAR LA INTEGRACIÓN

### 1. Registro:
```dart
// En RegisterScreen, completar formulario
// → Firebase crea usuario
// → Laravel recibe token
// → Laravel crea registro en MySQL
// → Retorna token Sanctum
// → Registra token FCM
```

### 2. Login:
```dart
// En LoginScreen, ingresar credenciales
// → Firebase autentica
// → Laravel verifica token
// → Retorna token Sanctum
// → Registra token FCM
```

### 3. Notificaciones:
```dart
// Desde Laravel, enviar notificación:
sendPushNotification($fcmToken, 'Título', 'Mensaje');

// → Firebase envía notificación
// → App recibe y muestra notificación local
```

---

## 📚 PRÓXIMOS PASOS

1. ✅ Implementar estos cambios
2. ✅ Probar registro y login
3. ✅ Verificar notificaciones push
4. 📱 Implementar pantallas específicas (citas, mascotas, etc.)
5. 🔒 Agregar persistencia de sesión (SharedPreferences/Secure Storage)

---

## 💡 RECOMENDACIONES

- **Usar paquete `flutter_secure_storage`** para guardar el token Sanctum
- **Implementar auto-login** si el token existe y es válido
- **Manejar expiración de tokens** con refresh automático
- **Agregar loading states** en todas las operaciones async
- **Implementar manejo de errores** robusto

---

¿Necesitas ayuda con algún paso específico? 🚀
