// Este archivo contiene la configuración de Firebase para tu proyecto
// Reemplaza estos valores con los de tu proyecto Firebase

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // Configuración para Web
  // Ve a: Firebase Console > Project Settings > General > Your apps > Web app
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDemoKey-Replace-With-Your-Real-Key',
    appId: '1:123456789:web:abcdef123456',
    messagingSenderId: '123456789',
    projectId: 'vetcare-app',
    authDomain: 'vetcare-app.firebaseapp.com',
    storageBucket: 'vetcare-app.appspot.com',
    measurementId: 'G-MEASUREMENT_ID',
  );

  // Configuración para Android
  // Ve a: Firebase Console > Project Settings > General > Your apps > Android app
  // O descarga google-services.json y usa FlutterFire CLI
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDemoKey-Replace-With-Your-Real-Android-Key',
    appId: '1:123456789:android:abcdef123456',
    messagingSenderId: '123456789',
    projectId: 'vetcare-app',
    storageBucket: 'vetcare-app.appspot.com',
  );

  // Configuración para iOS
  // Ve a: Firebase Console > Project Settings > General > Your apps > iOS app
  // O descarga GoogleService-Info.plist y usa FlutterFire CLI
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDemoKey-Replace-With-Your-Real-iOS-Key',
    appId: '1:123456789:ios:abcdef123456',
    messagingSenderId: '123456789',
    projectId: 'vetcare-app',
    storageBucket: 'vetcare-app.appspot.com',
    iosBundleId: 'com.example.vetcareApp',
  );
}
