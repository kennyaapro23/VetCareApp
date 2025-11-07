# 🔥 GUÍA COMPLETA: FIREBASE AUTHENTICATION + NOTIFICACIONES PUSH

## 📋 ÍNDICE
1. [Configuración Backend Laravel](#configuración-backend-laravel)
2. [Configuración Frontend Flutter](#configuración-frontend-flutter)
3. [Flujo de Autenticación](#flujo-de-autenticación)
4. [Notificaciones Push](#notificaciones-push)
5. [Testing](#testing)

---

## 🔧 CONFIGURACIÓN BACKEND LARAVEL

### 1️⃣ Obtener Credenciales de Firebase

1. Ir a https://console.firebase.google.com/
2. Seleccionar tu proyecto (o crear uno)
3. **⚙️ Configuración del proyecto** > **Cuentas de servicio**
4. Click en **"Generar nueva clave privada"**
5. Descargar el archivo JSON
6. Renombrarlo a: `firebase-credentials.json`
7. Guardarlo en: `storage/app/firebase-credentials.json`

### 2️⃣ Configurar .env

Agregar estas líneas al archivo `.env`:

```env
# Firebase Configuration
FIREBASE_CREDENTIALS=../storage/app/firebase-credentials.json
FIREBASE_DATABASE_URL=https://tu-proyecto.firebaseio.com
FIREBASE_PROJECT_ID=tu-proyecto-id

# FCM Server Key (para notificaciones push)
FCM_SERVER_KEY=tu_server_key_aqui
```

**Para obtener el FCM_SERVER_KEY:**
1. Firebase Console > Tu proyecto
2. ⚙️ Configuración > **Cloud Messaging**
3. Copiar **Server Key**

### 3️⃣ Verificar Instalación

```bash
php artisan tinker
```

Ejecutar:
```php
app('firebase.auth');
// Debe devolver: Kreait\Firebase\Contract\Auth
```

---

## 📱 CONFIGURACIÓN FRONTEND FLUTTER

### 1️⃣ Dependencias

```yaml
# pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0
  shared_preferences: ^2.2.2
  firebase_core: ^2.24.2
  firebase_auth: ^4.15.3
  firebase_messaging: ^14.7.9
  provider: ^6.1.1
```

### 2️⃣ Configurar Firebase en Flutter

**Android:**
1. Descargar `google-services.json`
2. Colocar en: `android/app/google-services.json`

**iOS:**
1. Descargar `GoogleService-Info.plist`
2. Colocar en: `ios/Runner/GoogleService-Info.plist`

### 3️⃣ Firebase Service (Flutter)

```dart
// lib/services/firebase_service.dart
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static const String baseUrl = 'http://10.0.2.2:8000/api';
  
  String? _sanctumToken;
  
  // Obtener usuario actual
  User? get currentUser => _auth.currentUser;
  
  // Stream de cambios de autenticación
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  // 1. Registro con email/contraseña
  Future<Map<String, dynamic>> registerWithEmail({
    required String email,
    required String password,
    required String nombre,
    String? telefono,
    String rol = 'cliente',
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      // Crear usuario en Firebase
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Actualizar el display name
      await userCredential.user?.updateDisplayName(nombre);
      
      // Obtener el ID Token
      String? idToken = await userCredential.user?.getIdToken();
      
      if (idToken == null) {
        throw Exception('No se pudo obtener el token de Firebase');
      }
      
      // Sincronizar con backend Laravel
      final backendResponse = await _syncWithBackend(
        idToken: idToken,
        rol: rol,
        additionalData: {
          ...?additionalData,
          'nombre': nombre,
          'telefono': telefono,
        },
      );
      
      return backendResponse;
      
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    }
  }
  
  // 2. Login con email/contraseña
  Future<Map<String, dynamic>> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      // Login en Firebase
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Obtener el ID Token
      String? idToken = await userCredential.user?.getIdToken();
      
      if (idToken == null) {
        throw Exception('No se pudo obtener el token de Firebase');
      }
      
      // Sincronizar con backend Laravel
      final backendResponse = await _syncWithBackend(idToken: idToken);
      
      // Registrar FCM token
      await _registerFcmToken();
      
      return backendResponse;
      
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    }
  }
  
  // 3. Login con Google (opcional)
  Future<Map<String, dynamic>> loginWithGoogle() async {
    try {
      // Implementar Google Sign-In
      // Necesitas: google_sign_in package
      throw UnimplementedError('Implementar Google Sign-In');
    } catch (e) {
      throw Exception('Error en login con Google: $e');
    }
  }
  
  // 4. Sincronizar con backend Laravel
  Future<Map<String, dynamic>> _syncWithBackend({
    required String idToken,
    String? rol,
    Map<String, dynamic>? additionalData,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/firebase/verify'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode({
        'firebase_token': idToken,
        if (rol != null) 'rol': rol,
        if (additionalData != null) 'additional_data': additionalData,
      }),
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      // Guardar el token de Sanctum
      _sanctumToken = data['sanctum_token'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('sanctum_token', _sanctumToken!);
      
      return data;
    } else {
      throw Exception('Error al sincronizar con backend: ${response.body}');
    }
  }
  
  // 5. Registrar FCM Token en backend
  Future<void> _registerFcmToken() async {
    try {
      // Solicitar permisos
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      
      // Obtener token FCM
      String? fcmToken = await _messaging.getToken();
      
      if (fcmToken != null && _sanctumToken != null) {
        await http.post(
          Uri.parse('$baseUrl/firebase/fcm-token'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $_sanctumToken',
          },
          body: json.encode({
            'fcm_token': fcmToken,
            'device_type': 'android', // o 'ios'
          }),
        );
      }
    } catch (e) {
      print('Error al registrar FCM token: $e');
    }
  }
  
  // 6. Configurar listeners de notificaciones
  void setupNotificationListeners({
    required Function(Map<String, dynamic>) onMessage,
    required Function(Map<String, dynamic>) onMessageOpenedApp,
  }) {
    // Mensaje en foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Mensaje recibido en foreground: ${message.notification?.title}');
      onMessage({
        'title': message.notification?.title,
        'body': message.notification?.body,
        'data': message.data,
      });
    });
    
    // Mensaje abrió la app
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('App abierta desde notificación');
      onMessageOpenedApp({
        'title': message.notification?.title,
        'body': message.notification?.body,
        'data': message.data,
      });
    });
    
    // Mensaje cuando la app estaba cerrada
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        onMessageOpenedApp({
          'title': message.notification?.title,
          'body': message.notification?.body,
          'data': message.data,
        });
      }
    });
  }
  
  // 7. Obtener perfil del usuario
  Future<Map<String, dynamic>> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('sanctum_token');
    
    if (token == null) {
      throw Exception('No hay sesión activa');
    }
    
    final response = await http.get(
      Uri.parse('$baseUrl/firebase/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error al obtener perfil: ${response.body}');
    }
  }
  
  // 8. Actualizar perfil
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('sanctum_token');
    
    if (token == null) {
      throw Exception('No hay sesión activa');
    }
    
    final response = await http.put(
      Uri.parse('$baseUrl/firebase/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(data),
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error al actualizar perfil: ${response.body}');
    }
  }
  
  // 9. Logout
  Future<void> logout() async {
    try {
      // Logout del backend
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('sanctum_token');
      
      if (token != null) {
        await http.post(
          Uri.parse('$baseUrl/firebase/logout'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
      }
      
      // Logout de Firebase
      await _auth.signOut();
      
      // Limpiar token local
      await prefs.remove('sanctum_token');
      _sanctumToken = null;
      
    } catch (e) {
      print('Error en logout: $e');
    }
  }
  
  // Manejo de errores de Firebase
  String _handleFirebaseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'La contraseña es muy débil';
      case 'email-already-in-use':
        return 'El email ya está registrado';
      case 'invalid-email':
        return 'Email inválido';
      case 'user-not-found':
        return 'Usuario no encontrado';
      case 'wrong-password':
        return 'Contraseña incorrecta';
      default:
        return 'Error de autenticación: ${e.message}';
    }
  }
}
```

---

## 🔐 FLUJO DE AUTENTICACIÓN

### Diagrama de Flujo:

```
1. Usuario → Firebase Auth (Email/Password)
   ↓
2. Firebase → ID Token (JWT)
   ↓
3. Flutter → Backend Laravel (POST /api/firebase/verify + ID Token)
   ↓
4. Laravel → Verifica Token con Firebase Admin SDK
   ↓
5. Laravel → Busca/Crea Usuario en MySQL (con firebase_uid)
   ↓
6. Laravel → Genera Sanctum Token
   ↓
7. Flutter → Guarda Sanctum Token
   ↓
8. Flutter → Usa Sanctum Token para todos los endpoints
```

### Código de Ejemplo:

```dart
// Registro
final firebaseService = FirebaseService();

try {
  final result = await firebaseService.registerWithEmail(
    email: 'juan@example.com',
    password: 'password123',
    nombre: 'Juan Pérez',
    telefono: '1234567890',
    rol: 'cliente',
    additionalData: {
      'direccion': 'Calle 123',
    },
  );
  
  print('Usuario registrado: ${result['user']['nombre']}');
  print('Token Sanctum: ${result['sanctum_token']}');
  
} catch (e) {
  print('Error: $e');
}

// Login
try {
  final result = await firebaseService.loginWithEmail(
    email: 'juan@example.com',
    password: 'password123',
  );
  
  print('Login exitoso: ${result['user']['nombre']}');
  
} catch (e) {
  print('Error: $e');
}
```

---

## 🔔 NOTIFICACIONES PUSH

### Backend: Enviar Notificación

El helper ya está configurado en `app/helpers.php`:

```php
// Uso en cualquier controlador
$cliente = Cliente::find(1);
$fcmToken = $cliente->user->fcm_tokens()->latest()->first()?->token;

if ($fcmToken) {
    sendPushNotification(
        $fcmToken,
        'Nueva Cita Confirmada',
        'Tu cita está programada para ' . $cita->fecha
    );
}
```

### Frontend: Recibir Notificaciones

```dart
// En main.dart
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Mensaje en background: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _firebaseService = FirebaseService();
  
  @override
  void initState() {
    super.initState();
    _setupNotifications();
  }
  
  void _setupNotifications() {
    _firebaseService.setupNotificationListeners(
      onMessage: (notification) {
        // Mostrar notificación local o actualizar UI
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(notification['title'] ?? 'Notificación'),
          ),
        );
      },
      onMessageOpenedApp: (notification) {
        // Navegar a la pantalla correspondiente
        print('App abierta desde notificación: ${notification['data']}');
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Veterinaria App',
      home: StreamBuilder<User?>(
        stream: _firebaseService.authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return HomeScreen();
          } else {
            return LoginScreen();
          }
        },
      ),
    );
  }
}
```

---

## 🧪 TESTING

### Test de Conexión Backend

```bash
php artisan tinker
```

```php
// Verificar Firebase Auth
$auth = app('firebase.auth');
dd($auth);

// Verificar helper de notificaciones
sendPushNotification(
    'test_token',
    'Test',
    'Mensaje de prueba'
);
```

### Test de Conexión Flutter

```dart
void testFirebaseAuth() async {
  final service = FirebaseService();
  
  // Test de registro
  try {
    final result = await service.registerWithEmail(
      email: 'test@example.com',
      password: 'password123',
      nombre: 'Test User',
      rol: 'cliente',
    );
    print('✅ Registro exitoso');
    print('Usuario: ${result['user']}');
  } catch (e) {
    print('❌ Error: $e');
  }
  
  // Test de login
  try {
    final result = await service.loginWithEmail(
      email: 'test@example.com',
      password: 'password123',
    );
    print('✅ Login exitoso');
    print('Token: ${result['sanctum_token']}');
  } catch (e) {
    print('❌ Error: $e');
  }
}
```

---

## 📊 ENDPOINTS DISPONIBLES

### Firebase Auth

```
POST   /api/firebase/verify           # Verificar token y sincronizar usuario
GET    /api/firebase/profile          # Obtener perfil (requiere auth)
PUT    /api/firebase/profile          # Actualizar perfil (requiere auth)
POST   /api/firebase/fcm-token        # Registrar FCM token (requiere auth)
POST   /api/firebase/logout           # Cerrar sesión (requiere auth)
```

### Auth Tradicional (sigue disponible)

```
POST   /api/auth/register             # Registro tradicional
POST   /api/auth/login                # Login tradicional
POST   /api/auth/logout               # Logout (requiere auth)
```

---

## ✅ CHECKLIST DE IMPLEMENTACIÓN

### Backend
- [x] Firebase Admin SDK instalado
- [x] Credenciales de Firebase guardadas
- [x] .env configurado
- [x] Migración firebase_uid ejecutada
- [x] Middleware FirebaseAuth creado
- [x] FirebaseAuthController creado
- [x] Helper de notificaciones push
- [x] Rutas API configuradas

### Frontend
- [ ] Firebase configurado en Flutter
- [ ] FirebaseService implementado
- [ ] Login/Register screens
- [ ] Manejo de estado (Provider/Bloc)
- [ ] Listeners de notificaciones
- [ ] Test de conexión exitoso

---

## 🎉 ¡SISTEMA COMPLETO!

Ahora tienes:
- ✅ Autenticación Firebase integrada con Laravel
- ✅ Sincronización automática de usuarios
- ✅ Tokens de Sanctum para API
- ✅ Notificaciones push con FCM
- ✅ Doble autenticación (Firebase + Sanctum tradicional)

**¡El backend está listo para recibir peticiones de Flutter!** 🚀
