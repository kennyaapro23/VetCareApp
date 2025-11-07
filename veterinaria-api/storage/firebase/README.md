# Firebase Service Account Credentials

## 📍 Coloca aquí tu archivo JSON de Firebase

### Pasos para obtener el archivo:

1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Selecciona tu proyecto
3. Ve a **Project Settings** (⚙️ icono de configuración arriba a la izquierda)
4. Pestaña **Service accounts**
5. Click en **Generate new private key**
6. Se descargará un archivo JSON (ejemplo: `veterinaria-app-firebase-adminsdk-xxxxx-xxxxxxxxxx.json`)

### 📋 Instrucciones:

**Renombra** el archivo descargado a: `service-account.json`

**Colócalo** en esta carpeta: `storage/firebase/service-account.json`

La ruta completa debe ser:
```
C:\Users\kenny\VetCareApp\veterinaria-api\storage\firebase\service-account.json
```

### ✅ Verificación

Después de colocar el archivo:

1. Verifica que `.env` tenga la variable:
   ```
   FIREBASE_CREDENTIALS="C:/Users/kenny/VetCareApp/veterinaria-api/storage/firebase/service-account.json"
   ```

2. Limpia la caché de Laravel:
   ```powershell
   php artisan config:clear
   php artisan cache:clear
   ```

3. Prueba la conexión con Tinker:
   ```powershell
   php artisan tinker
   ```
   ```php
   >>> $auth = app('firebase.auth');
   >>> $auth instanceof Kreait\Firebase\Contract\Auth; // debe devolver true
   ```

### 🔒 Seguridad

- ✅ Esta carpeta ya está en `.gitignore` - el JSON NO se subirá al repositorio
- ❌ NUNCA compartas este archivo públicamente
- ❌ NO lo subas a GitHub, GitLab, o repositorios públicos
- ✅ En producción, usa variables de entorno o servicios de secrets (Azure Key Vault, AWS Secrets Manager, etc.)

---

**Estado actual:** ⏳ Esperando que coloques el archivo `service-account.json` aquí
