// Configuración de entorno para desarrollo
class AppConfig {
  // 🔧 CONFIGURACIÓN DE CONEXIÓN AL BACKEND

  // Recomendación por defecto: usar localhost (127.0.0.1) + adb reverse para emulador
  // 1) En Windows (cmd.exe) ejecuta: adb reverse tcp:8000 tcp:8000
  // 2) Inicia Laravel: php artisan serve --host=0.0.0.0 --port=8000
  // 3) Deja baseUrl como 127.0.0.1 (la app en el emulador se conectará al host)
  static const String baseUrl = 'http://127.0.0.1:8000/api/';

  // Alternativas según tu entorno (descomenta la que corresponda):
  // - Android emulator (default Android emulator) suele aceptar 10.0.2.2
  //   static const String baseUrl = 'http://10.0.2.2:8000/api/';
  // - Genymotion usa 10.0.3.2
  //   static const String baseUrl = 'http://10.0.3.2:8000/api/';
  // - Dispositivo físico: usa la IP de tu PC en la red local (ipconfig -> IPv4)
  //   static const String baseUrl = 'http://192.168.x.y:8000/api/';
  // - NO uses direcciones link-local tipo 169.254.x.x salvo que entiendas su origen

  // Configuración de timeouts
  static const Duration requestTimeout = Duration(seconds: 30);
  static const Duration connectTimeout = Duration(seconds: 10);
  static const int maxRetries = 3;

  // Headers estándar
  static Map<String, String> get headers => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

  static Map<String, String> headersWithAuth(String token) => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  // Credenciales de prueba
  static const String testEmail = 'cliente@veterinaria.com';
  static const String testPassword = 'password123';

  // 📝 CÓMO OBTENER TU IP:
  // 1. Abre CMD o PowerShell
  // 2. Ejecuta: ipconfig
  // 3. Busca "Adaptador de LAN inalámbrica Wi-Fi"
  // 4. Copia la "Dirección IPv4" y pégala en baseUrl arriba

  // ⚠️ IMPORTANTE:
  // - Laravel debe correr con: php artisan serve --host=0.0.0.0 --port=8000
  // - Tu PC y emulador/teléfono deben estar en la misma red WiFi (si usas IP local)
}
