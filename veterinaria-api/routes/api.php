<?php

use App\Http\Controllers\AuthController;
use App\Http\Controllers\FirebaseAuthController;
use App\Http\Controllers\CitaController;
use App\Http\Controllers\QRController;
use App\Http\Controllers\HistorialController;
use App\Http\Controllers\ClienteController;
use App\Http\Controllers\MascotaController;
use App\Http\Controllers\VeterinarioController;
use App\Http\Controllers\ServicioController;
use App\Http\Controllers\NotificacionController;
use App\Http\Controllers\FacturaController;
use App\Http\Controllers\FcmTokenController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

Route::get('/user', function (Request $request) {
    return $request->user();
})->middleware('auth:sanctum');

// Authentication routes (Laravel Sanctum - tradicional)
Route::post('/auth/register', [AuthController::class, 'register']);
Route::post('/auth/login', [AuthController::class, 'login']);
Route::post('/auth/logout', [AuthController::class, 'logout'])->middleware('auth:sanctum');

// Firebase Authentication routes
Route::prefix('firebase')->group(function () {
    Route::post('/verify', [FirebaseAuthController::class, 'verifyAndSync']);
    
    Route::middleware('auth:sanctum')->group(function () {
        Route::get('/profile', [FirebaseAuthController::class, 'getProfile']);
        Route::put('/profile', [FirebaseAuthController::class, 'updateProfile']);
        Route::post('/fcm-token', [FirebaseAuthController::class, 'registerFcmToken']);
        Route::post('/logout', [FirebaseAuthController::class, 'logout']);
    });
});

// QR Code routes (públicas para lectura)
Route::get('/qr/lookup/{token}', [QRController::class, 'lookup'])->name('api.qr.lookup');

// Rutas protegidas con Sanctum
Route::middleware('auth:sanctum')->group(function () {
    
    // FCM Tokens (Firebase Cloud Messaging)        x
    Route::post('/fcm-token', [FcmTokenController::class, 'store']);
    Route::delete('/fcm-token', [FcmTokenController::class, 'destroy']);
    Route::get('/fcm-tokens', [FcmTokenController::class, 'index']);
    Route::delete('/fcm-tokens/all', [FcmTokenController::class, 'destroyAll']);
    
    // Clientes
    Route::apiResource('clientes', ClienteController::class);
    
    // Mascotas
    Route::apiResource('mascotas', MascotaController::class);
    
    // Veterinarios
    Route::apiResource('veterinarios', VeterinarioController::class);
    Route::get('/veterinarios/{id}/disponibilidad', [VeterinarioController::class, 'getDisponibilidad']);
    Route::post('/veterinarios/{id}/disponibilidad', [VeterinarioController::class, 'setDisponibilidad']);
    
    // Citas
    Route::apiResource('citas', CitaController::class);
    
    // Servicios
    Route::apiResource('servicios', ServicioController::class);
    Route::get('/servicios-tipos', [ServicioController::class, 'getTipos']);
    
    // Historial Médico
    Route::get('/historial-medico', [HistorialController::class, 'index']);
    Route::post('/historial-medico', [HistorialController::class, 'store']);
    Route::get('/historial-medico/{id}', [HistorialController::class, 'show']);
    Route::post('/historial-medico/{id}/archivos', [HistorialController::class, 'attachFiles']);
    
    // Notificaciones
    Route::get('/notificaciones', [NotificacionController::class, 'index']);
    Route::get('/notificaciones/tipos', [NotificacionController::class, 'getTipos']);
    Route::get('/notificaciones/unread-count', [NotificacionController::class, 'getUnreadCount']);
    Route::post('/notificaciones/mark-all-read', [NotificacionController::class, 'markAllAsRead']);
    Route::delete('/notificaciones/delete-read', [NotificacionController::class, 'deleteRead']);
    Route::get('/notificaciones/{id}', [NotificacionController::class, 'show']);
    Route::post('/notificaciones/{id}/mark-read', [NotificacionController::class, 'markAsRead']);
    Route::delete('/notificaciones/{id}', [NotificacionController::class, 'destroy']);
    
    // Facturas
    Route::apiResource('facturas', FacturaController::class);
    Route::get('/facturas-estadisticas', [FacturaController::class, 'getEstadisticas']);
    Route::get('/generar-numero-factura', [FacturaController::class, 'generateNumeroFactura']);
    
    // Generar QR Codes
    Route::get('/mascotas/{id}/qr', [QRController::class, 'generateMascotaQR']);
    Route::get('/clientes/{id}/qr', [QRController::class, 'generateClienteQR']);
});
