@echo off
echo ========================================
echo Instalando dependencias de VetCareApp
echo ========================================
echo.

cd /d "%~dp0"

echo Ejecutando flutter pub get...
flutter pub get

echo.
echo ========================================
echo Instalacion completada!
echo ========================================
echo.
echo Ahora puedes ejecutar la app con:
echo flutter run
echo.
pause

