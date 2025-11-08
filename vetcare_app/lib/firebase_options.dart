

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'Web no está configurado - Esta app solo funciona en móvil',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        throw UnsupportedError(
          'Esta app solo está configurada para Android/iOS',
        );
      default:
        throw UnsupportedError(
          'Plataforma no soportada',
        );
    }
  }

  // ✅ Configuración para Android (LISTA PARA USAR)
  // Extraída automáticamente de google-services.json
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCUU5TVtktJzFMsClxpvrv2Nu2QgR5N_J0',
    appId: '1:242642212663:android:3bd8d73e544eca24136cb2',
    messagingSenderId: '242642212663',
    projectId: 'vetcareap',
    storageBucket: 'vetcareap.firebasestorage.app',
  );

  // ⚠️ Configuración para iOS (Configurar si usas iPhone)
  // Descarga GoogleService-Info.plist y colócalo en ios/Runner/
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSy...', // Obtener de GoogleService-Info.plist
    appId: '1:242642212663:ios:...', // Obtener de Firebase Console
    messagingSenderId: '242642212663',
    projectId: 'vetcareap',
    storageBucket: 'vetcareap.firebasestorage.app',
    iosBundleId: 'com.example.vetcareApp',
  );
}
