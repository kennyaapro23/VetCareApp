# 🔥 GUÍA COMPLETA: CONFIGURAR FIREBASE EN VETCARE APP

## 📋 RESUMEN
Esta guía te ayudará a configurar Firebase para autenticación y notificaciones push en tu app VetCare.

---

## 🎯 PASO 1: CREAR PROYECTO EN FIREBASE

### 1.1 Ir a Firebase Console
**🔗 LINK:** https://console.firebase.google.com/

### 1.2 Crear nuevo proyecto
1. Click en **"Agregar proyecto"** o **"Add project"**
2. Nombre del proyecto: `VetCare` (o el nombre que prefieras)
3. Click en **"Continuar"**
4. Desactiva Google Analytics si no lo necesitas (puedes activarlo después)
5. Click en **"Crear proyecto"**
6. Espera a que se complete (tarda ~30 segundos)
7. Click en **"Continuar"**

---

## 📱 PASO 2: CONFIGURAR ANDROID

### 2.1 Agregar app Android

1. En la página principal del proyecto, click en el ícono **Android** (robot verde)
2. Llenar el formulario:
   - **Nombre del paquete Android:** `com.example.vetcare_app`
   - **Alias de la app (opcional):** `VetCare`
   - **Certificado de firma SHA-1 (opcional):** Dejar vacío por ahora
3. Click en **"Registrar app"**

### 2.2 Descargar google-services.json

1. Click en **"Descargar google-services.json"**
2. **IMPORTANTE:** Coloca el archivo descargado en:
   ```
   C:\Users\kenny\VetCareApp\vetcare_app\android\app\google-services.json
   ```
3. Verifica que el archivo esté en la ubicación correcta:
   ```
   vetcare_app/
   └── android/
       └── app/
           └── google-services.json  ← AQUÍ
   ```

### 2.3 Completar configuración

1. En Firebase Console, click en **"Siguiente"**
2. Click en **"Siguiente"** de nuevo (los pasos de Gradle ya están configurados)
3. Click en **"Continuar a la consola"**

---

## 🍎 PASO 3: CONFIGURAR iOS (OPCIONAL)

### 3.1 Agregar app iOS

1. En Firebase Console, click en **"Agregar app"** → Seleccionar **iOS**
2. Llenar el formulario:
   - **ID del paquete iOS:** `com.example.vetcareApp`
   - **Alias de la app (opcional):** `VetCare`
   - **ID de App Store (opcional):** Dejar vacío
3. Click en **"Registrar app"**

### 3.2 Descargar GoogleService-Info.plist

1. Click en **"Descargar GoogleService-Info.plist"**
2. Abrir el proyecto en Xcode:
   ```bash
   open ios/Runner.xcworkspace
   ```
3. Arrastrar el archivo `GoogleService-Info.plist` a la carpeta `Runner` en Xcode
4. ✅ Marcar **"Copy items if needed"**
5. Click en **"Finish"**

### 3.3 Completar configuración

1. En Firebase Console, click en **"Siguiente"**
2. Click en **"Continuar a la consola"**

---

## 🔐 PASO 4: HABILITAR AUTENTICACIÓN

### 4.1 Ir a Authentication

1. En el menú lateral de Firebase Console, click en **"Authentication"** (o **"Compilación"** → **"Authentication"**)
2. Click en **"Comenzar"** o **"Get started"**

### 4.2 Habilitar Email/Password

1. En la pestaña **"Sign-in method"** (Método de acceso)
2. Click en **"Email/Password"**
3. Activar el switch **"Habilitar"**
4. Click en **"Guardar"**

### 4.3 (Opcional) Habilitar Google Sign-In

1. Click en **"Google"**
2. Activar el switch **"Habilitar"**
3. Seleccionar un email de soporte del proyecto
4. Click en **"Guardar"**

---

## 🔔 PASO 5: HABILITAR CLOUD MESSAGING

### 5.1 Ir a Cloud Messaging

1. En el menú lateral, click en el ícono **⚙️ (configuración)** → **"Configuración del proyecto"**
2. Ir a la pestaña **"Cloud Messaging"**
3. En la sección **"Cloud Messaging API (Legacy)"**, asegúrate de que esté habilitada
   - Si ves un botón para habilitar, haz click en él
   - Acepta los términos si es necesario

### 5.2 Obtener Server Key (para backend)

1. En la misma sección, busca **"Clave del servidor"** o **"Server key"**
2. Copia esta clave (la necesitarás en tu backend Laravel)
3. Guárdala en un lugar seguro (NO la subas a Git)

---

## 🔑 PASO 6: ACTUALIZAR firebase_options.dart

### 6.1 Obtener configuración de Firebase

1. En Firebase Console → ⚙️ → **"Configuración del proyecto"**
2. Scroll hasta la sección **"Tus apps"**
3. Click en tu app Android
4. Busca la sección **"Configuración del SDK de Firebase"**
5. Copia los valores necesarios

### 6.2 Actualizar archivo

Abre el archivo:
```
C:\Users\kenny\VetCareApp\vetcare_app\lib\firebase_options.dart
```

Y reemplaza los valores con los tuyos:

```dart
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'TU-API-KEY-AQUI',                    // ← Copia de Firebase Console
  appId: '1:123456789:android:abcdef123456',   // ← Copia de Firebase Console
  messagingSenderId: '123456789',               // ← Copia de Firebase Console
  projectId: 'tu-proyecto-id',                  // ← Copia de Firebase Console
  storageBucket: 'tu-proyecto.appspot.com',     // ← Copia de Firebase Console
);
```

**📝 EJEMPLO REAL:**
```dart
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'AIzaSyBXxXxXxXxXxXxXxXxXxXxXxXxXxXxXxXx',
  appId: '1:987654321098:android:1a2b3c4d5e6f7g8h',
  messagingSenderId: '987654321098',
  projectId: 'vetcare-app-2024',
  storageBucket: 'vetcare-app-2024.appspot.com',
);
```

---

## 🧪 PASO 7: PROBAR LA CONFIGURACIÓN

### 7.1 Limpiar y obtener dependencias

Ejecuta en la terminal:
```bash
cd C:\Users\kenny\VetCareApp\vetcare_app
flutter clean
flutter pub get
```

### 7.2 Ejecutar la app

```bash
flutter run
```

### 7.3 Verificar logs

Deberías ver en la consola:
```
✅ Firebase inicializado correctamente
```

Si ves esto, ¡la configuración fue exitosa! 🎉

---

## ❌ SOLUCIÓN DE PROBLEMAS

### Error: "File google-services.json is missing"

**Causa:** El archivo no está en la ubicación correcta.

**Solución:**
1. Verifica que el archivo esté en: `android/app/google-services.json`
2. NO debe estar en `android/google-services.json` (carpeta incorrecta)
3. Reinicia el build: `flutter clean && flutter run`

### Error: "FirebaseOptions have not been configured"

**Causa:** Los valores en `firebase_options.dart` no están actualizados.

**Solución:**
1. Ve a Firebase Console → ⚙️ → Configuración del proyecto
2. Copia los valores correctos de tu app
3. Actualiza `lib/firebase_options.dart`

### Error: "Failed host lookup: 'fonts.gstatic.com'"

**Causa:** El emulador no tiene acceso a Internet para descargar fuentes.

**Solución:**
✅ Ya está solucionado en el código con:
```dart
GoogleFonts.config.allowRuntimeFetching = false;
```

### Error de compilación de Gradle

**Solución:**
```bash
cd android
gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

---

## 📚 RECURSOS ADICIONALES

### Links útiles:

1. **Firebase Console:**
   https://console.firebase.google.com/

2. **Documentación Flutter + Firebase:**
   https://firebase.google.com/docs/flutter/setup

3. **Firebase Authentication:**
   https://firebase.google.com/docs/auth

4. **Firebase Cloud Messaging:**
   https://firebase.google.com/docs/cloud-messaging

5. **FlutterFire (Firebase para Flutter):**
   https://firebase.flutter.dev/

---

## 🔐 SEGURIDAD

### ⚠️ IMPORTANTE: NO SUBIR A GIT

Agrega estos archivos a `.gitignore`:

```gitignore
# Firebase
android/app/google-services.json
ios/Runner/GoogleService-Info.plist
lib/firebase_options.dart

# Claves sensibles
*.env
*.key
```

### 🔒 Para producción:

1. Usa Firebase App Check para proteger tu backend
2. Configura reglas de seguridad en Firestore/Storage
3. Habilita autenticación de dos factores
4. Restringe el uso de API Keys por dominio/bundle ID

---

## ✅ CHECKLIST FINAL

- [ ] ✅ Proyecto creado en Firebase Console
- [ ] ✅ App Android registrada
- [ ] ✅ `google-services.json` descargado y colocado en `android/app/`
- [ ] ✅ Email/Password habilitado en Authentication
- [ ] ✅ Cloud Messaging habilitado
- [ ] ✅ `firebase_options.dart` actualizado con valores reales
- [ ] ✅ App ejecutándose sin errores
- [ ] ✅ Log: "✅ Firebase inicializado correctamente"

---

## 🎉 ¡LISTO!

Si completaste todos los pasos, tu app ahora tiene:
- ✅ Autenticación con Firebase (Email/Password)
- ✅ Notificaciones Push (FCM)
- ✅ Integración completa con backend Laravel

**Próximos pasos:**
1. Configurar el backend Laravel con Firebase Admin SDK
2. Implementar pantallas de login/registro
3. Probar notificaciones push

---

**¿Necesitas ayuda?** Revisa la sección de Solución de Problemas o consulta la documentación oficial de Firebase.

