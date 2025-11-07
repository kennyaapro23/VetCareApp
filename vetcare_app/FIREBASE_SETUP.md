# 🔥 Configuración de Firebase para VetCareApp

## 📋 Pasos para Configurar Firebase

### 1. Crear Proyecto en Firebase Console

1. Ve a [Firebase Console](https://console.firebase.google.com)
2. Haz clic en **"Agregar proyecto"**
3. Nombre del proyecto: `VetCare` (o el que prefieras)
4. Habilita Google Analytics (opcional)
5. Crea el proyecto

### 2. Agregar App Android

1. En Firebase Console, haz clic en el ícono de Android
2. **Android package name**: `com.example.vetcare_app`
3. **App nickname**: `VetCareApp` (opcional)
4. Descarga el archivo `google-services.json`
5. **Coloca `google-services.json` en**: `android/app/google-services.json`

### 3. Habilitar Firebase Cloud Messaging (FCM)

1. En Firebase Console, ve a **"Cloud Messaging"**
2. Copia el **Server Key** (lo necesitarás para el backend Laravel)

### 4. Configurar `firebase_options.dart`

**Opción A - Automática (Recomendada):**

Instala FlutterFire CLI:
```cmd
dart pub global activate flutterfire_cli
flutterfire configure
```

Esto generará automáticamente `lib/firebase_options.dart` con tus valores reales.

**Opción B - Manual:**

1. En Firebase Console, ve a **Project Settings** (⚙️)
2. Baja hasta **"Your apps"**
3. Selecciona tu app Android
4. Copia los valores y pégalos en `lib/firebase_options.dart`:

```dart
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'TU_API_KEY_AQUI',
  appId: '1:123456789:android:abcdef123456',
  messagingSenderId: '123456789',
  projectId: 'tu-proyecto-id',
  storageBucket: 'tu-proyecto-id.appspot.com',
);
```

### 5. Configurar Backend Laravel para Enviar Notificaciones

En tu backend Laravel, necesitas el **Server Key** de Firebase:

**`.env` de Laravel:**
```env
FCM_SERVER_KEY=tu_server_key_aqui
```

**Ejemplo de código Laravel para enviar notificación:**

```php
use Illuminate\Support\Facades\Http;

function sendPushNotification($fcmToken, $title, $body, $data = []) {
    $serverKey = env('FCM_SERVER_KEY');
    
    $response = Http::withHeaders([
        'Authorization' => 'key=' . $serverKey,
        'Content-Type' => 'application/json',
    ])->post('https://fcm.googleapis.com/fcm/send', [
        'to' => $fcmToken,
        'notification' => [
            'title' => $title,
            'body' => $body,
            'sound' => 'default',
        ],
        'data' => $data,
    ]);
    
    return $response->json();
}

// Uso:
$user = auth()->user();
$fcmToken = $user->fcm_tokens()->latest()->first()->token;
sendPushNotification($fcmToken, 'Nueva Cita', 'Tienes una cita mañana a las 10:00 AM');
```

### 6. Verificar Archivos Modificados

✅ **Archivos que YA actualicé:**
- `android/app/build.gradle.kts` → Plugin de Google Services + dependencias Firebase
- `android/build.gradle.kts` → Classpath de Google Services
- `android/app/src/main/AndroidManifest.xml` → Permisos + configuración FCM
- `lib/main.dart` → Inicialización de Firebase
- `lib/firebase_options.dart` → Configuración (placeholder, necesitas valores reales)
- `lib/services/notification_service.dart` → Manejo completo de notificaciones

### 7. Probar Notificaciones

**Desde Firebase Console:**

1. Ve a **Cloud Messaging** en Firebase Console
2. Haz clic en **"Send your first message"**
3. Título: "Prueba"
4. Texto: "Esta es una notificación de prueba"
5. Selecciona tu app
6. Haz clic en **"Send test message"**
7. Pega el FCM Token que aparece en los logs de Flutter (cuando ejecutas la app)

**Ver el Token en la app:**

Cuando ejecutes `flutter run`, verás en la consola:
```
✅ Firebase inicializado correctamente
FCM Token: eAbCdEf123...
```

Copia ese token y úsalo para pruebas.

### 8. Ejecutar la App

```cmd
cd C:\Users\kenny\vetcare_app
flutter pub get
flutter run
```

## 🔔 Flujo Completo de Notificaciones

1. **Usuario inicia sesión** → Flutter guarda FCM token en el backend
2. **Backend crea una cita** → Laravel envía notificación push usando FCM
3. **Flutter recibe notificación** → Se guarda localmente y se muestra
4. **Usuario ve notificaciones** → En `NotificacionesScreen`
5. **Usuario cierra sesión** → Flutter elimina FCM token del backend

## 🐛 Solución de Problemas

### Error: "google-services.json not found"
- Descarga `google-services.json` de Firebase Console
- Colócalo en: `android/app/google-services.json`

### Error: "Default FirebaseApp is not initialized"
- Verifica que `firebase_options.dart` tenga valores reales
- O usa `flutterfire configure`

### No recibo notificaciones
1. Verifica que el token FCM se guardó en el backend (revisa logs)
2. Usa Firebase Console para enviar notificación de prueba
3. Verifica permisos en `AndroidManifest.xml`
4. En Android 13+, acepta el permiso de notificaciones cuando la app lo solicite

### Token es null
- Espera unos segundos después de iniciar la app
- Verifica conexión a internet
- Reinstala la app: `flutter clean && flutter run`

## 📱 Test Rápido

1. Ejecuta la app: `flutter run`
2. Copia el FCM Token de los logs
3. Ve a Firebase Console > Cloud Messaging
4. Envía mensaje de prueba con ese token
5. Deberías ver la notificación en tu dispositivo/emulador

## ✅ Checklist Final

- [ ] Proyecto creado en Firebase Console
- [ ] App Android agregada a Firebase
- [ ] `google-services.json` descargado y colocado en `android/app/`
- [ ] `firebase_options.dart` configurado (con `flutterfire configure` o manual)
- [ ] `flutter pub get` ejecutado
- [ ] App ejecutándose sin errores de Firebase
- [ ] Token FCM visible en logs
- [ ] Notificación de prueba recibida
- [ ] Backend Laravel configurado con Server Key

---

**¡Todo listo!** La app ahora está configurada para recibir notificaciones push de Firebase. 🎉

