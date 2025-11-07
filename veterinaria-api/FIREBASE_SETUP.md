# 🔥 CONFIGURACIÓN FIREBASE - INSTRUCCIONES

## 📥 1. Obtener credenciales de Firebase

### Paso a paso:

1. **Ir a Firebase Console**: https://console.firebase.google.com/
2. **Seleccionar tu proyecto** (o crear uno nuevo)
3. **Ir a configuración del proyecto** (⚙️ icono arriba)
4. **Pestaña "Cuentas de servicio"**
5. **Click en "Generar nueva clave privada"**
6. **Descargar el archivo JSON**

### 2. Guardar las credenciales

Renombra el archivo descargado a: `firebase-credentials.json`

Guárdalo en: `c:\Users\kenny\veterinaria-api\storage\app\firebase-credentials.json`

## ⚙️ 3. Configurar .env

Agrega estas líneas a tu archivo `.env`:

```env
# Firebase Authentication & Cloud Messaging
FIREBASE_CREDENTIALS=../storage/app/firebase-credentials.json
FIREBASE_DATABASE_URL=https://tu-proyecto.firebaseio.com
FIREBASE_PROJECT_ID=tu-proyecto-id

# FCM Server Key (para notificaciones push)
# Lo encuentras en: Firebase Console > Configuración > Cloud Messaging > Server Key
FCM_SERVER_KEY=tu_server_key_aqui
```

## 🔍 4. Dónde encontrar FCM_SERVER_KEY

1. Firebase Console > Tu proyecto
2. **⚙️ Configuración del proyecto**
3. **Cloud Messaging** (tab)
4. **Server Key** (copiar)

## ✅ 5. Verificar instalación

Ejecuta:
```bash
php artisan tinker
```

Luego:
```php
app('firebase.auth');
// Debe devolver: Kreait\Firebase\Contract\Auth
```

## 🎉 ¡Listo!

Ahora puedes usar Firebase Auth y FCM en tu backend Laravel.
