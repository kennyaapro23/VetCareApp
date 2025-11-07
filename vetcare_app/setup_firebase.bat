@echo off
echo ========================================
echo Configuracion Rapida de Firebase
echo ========================================
echo.

cd /d "%~dp0"

echo Paso 1: Instalando FlutterFire CLI...
call dart pub global activate flutterfire_cli

echo.
echo Paso 2: Configurando Firebase...
echo IMPORTANTE: Cuando te pregunte, selecciona tu proyecto de Firebase
echo.
call flutterfire configure

echo.
echo ========================================
echo Configuracion completada!
echo ========================================
echo.
echo Archivos generados:
echo - lib/firebase_options.dart (con tus valores reales)
echo.
echo Siguiente paso:
echo 1. Descarga google-services.json de Firebase Console
echo 2. Colocalo en: android/app/google-services.json
echo 3. Ejecuta: flutter run
echo.
pause

