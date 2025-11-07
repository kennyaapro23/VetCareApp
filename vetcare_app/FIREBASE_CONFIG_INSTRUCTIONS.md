# 🔥 CONFIGURACIÓN DE FIREBASE - INSTRUCCIONES COMPLETAS

## ⚠️ IMPORTANTE: DEBES CONFIGURAR FIREBASE ANTES DE EJECUTAR LA APP

La aplicación ya tiene todo el código de integración con Firebase, pero necesitas configurar tu proyecto de Firebase y descargar los archivos de configuración.

---

## 📋 PASO 1: Crear Proyecto en Firebase Console

1. Ve a: https://console.firebase.google.com/
2. Click en **"Agregar proyecto"**
3. Nombre del proyecto: `vetcare-app` (o el que prefieras)
4. Habilita Google Analytics (opcional pero recomendado)
5. Click en **"Crear proyecto"**

---

## 📱 PASO 2: Configurar App Android

### 2.1 Registrar App Android en Firebase

1. En Firebase Console, click en el ícono de **Android** 🤖
2. **Package name**: `com.example.vetcare_app` (debe coincidir con tu app)
   - Verifica en: `android/app/build.gradle.kts` → `applicationId`
3. **App nickname**: VetCare Android (opcional)
4. Click en **"Registrar app"**

### 2.2 Descargar google-services.json

1. Firebase te mostrará un botón **"Descargar google-services.json"**
2. Descarga el archivo
3. **Colócalo en:** `android/app/google-services.json`
   ```
   vetcare_app/
   └── android/
       └── app/
           └── google-services.json  ← AQUÍ
   ```

### 2.3 Verificar configuración de Gradle

Ya está configurado en el código, pero verifica:

**android/build.gradle.kts** debe tener:
```gradle
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
```

**android/app/build.gradle.kts** debe tener:
```gradle
plugins {
    id("com.google.gms.google-services")  // Ya está ✅
}
```

---

## 🍎 PASO 3: Configurar App iOS (Opcional)

### 3.1 Registrar App iOS en Firebase

1. En Firebase Console, click en el ícono de **iOS** 🍎
2. **iOS bundle ID**: `com.example.vetcareApp`
   - Verifica en: `ios/Runner.xcodeproj/project.pbxproj`
3. Click en **"Registrar app"**

### 3.2 Descargar GoogleService-Info.plist

1. Descarga el archivo **GoogleService-Info.plist**
2. Abre Xcode: `open ios/Runner.xcworkspace`
3. Arrastra el archivo a la carpeta **Runner** en Xcode
4. ✅ Marca **"Copy items if needed"**
5. ✅ Marca **"Add to targets: Runner"**

---

## 🔑 PASO 4: Habilitar Autenticación en Firebase

### 4.1 Habilitar Email/Password

1. En Firebase Console → **Authentication**
2. Click en **"Comenzar"**
3. Click en **"Email/Password"**
4. ✅ Habilitar **"Email/contraseña"**
5. Click en **"Guardar"**

### 4.2 Habilitar Google Sign-In (Opcional)

1. En **Authentication** → **Sign-in method**
2. Click en **"Google"**
3. ✅ Habilitar
4. Selecciona tu email de soporte
5. Click en **"Guardar"**

**Para Android:**
- Descarga el **SHA-1** de tu proyecto:
  ```bash
  cd android
  ./gradlew signingReport
  ```
- Copia el SHA-1 y agrégalo en Firebase Console → Project Settings → Android app

---

## 📬 PASO 5: Configurar Cloud Messaging (FCM)

### 5.1 Habilitar FCM

1. En Firebase Console → **Cloud Messaging**
2. Ya está habilitado automáticamente ✅

### 5.2 Obtener Server Key (Para Laravel)

1. Ve a: **Project Settings** ⚙️
2. Click en **"Cloud Messaging"**
3. Copia el **"Server key"**
4. **Guarda este key para configurar tu backend Laravel**

---

## 🔧 PASO 6: Actualizar firebase_options.dart

### Opción A: Usar FlutterFire CLI (Recomendado)

```bash
# Instalar FlutterFire CLI
dart pub global activate flutterfire_cli

# Ejecutar desde la raíz del proyecto
flutterfire configure
```

Esto generará automáticamente el archivo `lib/firebase_options.dart` con tus claves reales.

### Opción B: Configurar manualmente

Edita `lib/firebase_options.dart` con los valores de tu Firebase Console:

1. Ve a: **Project Settings** ⚙️ → **General**
2. En "Your apps" verás tus apps registradas
3. Copia los valores y reemplázalos en `firebase_options.dart`:

```dart
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'TU_API_KEY_AQUI',           // De Firebase Console
  appId: 'TU_APP_ID_AQUI',             // De Firebase Console
  messagingSenderId: 'TU_SENDER_ID',   // De Firebase Console
  projectId: 'tu-project-id',          // De Firebase Console
  storageBucket: 'tu-project.appspot.com',
);
```

---

## ✅ PASO 7: Instalar Dependencias

```bash
cd C:\Users\kenny\vetcare_app
flutter pub get
```

---

## 🧪 PASO 8: Probar la Configuración

### Verificar que todo está correcto:

```bash
flutter run
```

Deberías ver en la consola:
```
✅ Firebase inicializado correctamente
```

Si ves un error:
```
⚠️ Error al inicializar Firebase: ...
```

Verifica que:
- ✅ `google-services.json` está en `android/app/`
- ✅ Los valores en `firebase_options.dart` son correctos
- ✅ Has ejecutado `flutter pub get`

---

## 📝 RESUMEN DE ARCHIVOS NECESARIOS

### ✅ Archivos que YA ESTÁN configurados:
- `lib/services/firebase_service.dart` ✅
- `lib/services/api_service.dart` (con métodos Firebase) ✅
- `lib/main.dart` (inicializa Firebase) ✅
- `android/app/build.gradle.kts` (plugin configurado) ✅
- `pubspec.yaml` (dependencias agregadas) ✅

### ⚠️ Archivos que DEBES AGREGAR/CONFIGURAR:
- `android/app/google-services.json` ← **DESCARGAR DE FIREBASE**
- `lib/firebase_options.dart` ← **CONFIGURAR CON TUS CLAVES**
- (Opcional) `ios/Runner/GoogleService-Info.plist`

---

## 🚀 PRÓXIMOS PASOS DESPUÉS DE CONFIGURAR

1. Ejecutar `flutter pub get`
2. Verificar que la app compile sin errores
3. Probar registro de usuario con Firebase
4. Verificar que el token se sincroniza con Laravel
5. Probar notificaciones push

---

## 🆘 SOLUCIÓN DE PROBLEMAS

### Error: "google-services.json is missing"
**Solución:** Descarga el archivo de Firebase Console y colócalo en `android/app/`

### Error: "Default FirebaseApp is not initialized"
**Solución:** Verifica que `firebase_options.dart` tenga las claves correctas

### Error: "INVALID_API_KEY"
**Solución:** Verifica que la API Key en `firebase_options.dart` sea correcta

### Las notificaciones no llegan
**Solución:** 
1. Verifica que el token FCM se esté registrando en Laravel
2. Verifica que el Server Key de Firebase esté configurado en Laravel
3. Revisa los logs de Firebase Console

---

## 📚 RECURSOS ÚTILES

- Firebase Console: https://console.firebase.google.com/
- FlutterFire Documentation: https://firebase.flutter.dev/
- Firebase Cloud Messaging: https://firebase.google.com/docs/cloud-messaging

---

**¿Necesitas ayuda? Revisa la documentación o contacta al equipo de desarrollo.**

