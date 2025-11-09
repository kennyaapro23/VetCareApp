# Test de Endpoints - Servicios y Citas

## Problema identificado

Hay confusión entre dos conceptos:

1. **Servicios Disponibles (Catálogo)** 
   - Endpoint: `GET /api/servicios`
   - Modelo: `Servicio`
   - Qué es: Lista de servicios que ofrece la veterinaria (ej: "Vacunación", "Consulta", etc.)
   - Usado en: `calendar_appointment_screen.dart` para seleccionar servicios al crear cita

2. **Servicios Aplicados (Historial)**
   - Endpoint: `GET /api/services` o similar
   - Modelo: `ServiceModel`
   - Qué es: Historial de servicios ya aplicados a mascotas específicas
   - Usado en: `servicios_screen.dart` (tab de servicios)

## Solución propuesta

### Para `ServiciosScreen` (la pantalla con tabs):

- **Tab 1 "Catálogo de Servicios"**: debe mostrar servicios disponibles (`Servicio`)
- **Tab 2 "Mis Citas"**: debe mostrar citas del usuario (`AppointmentModel`)

### Pasos para verificar:

1. Ejecuta la app y navega a "Agendar Cita"
2. Revisa los logs en consola:
   - `🔍 Cargando servicios disponibles...`
   - `✅ Servicios cargados: X`
   - O error: `❌ Error cargando servicios: ...`

3. Si dice "0 servicios" o error 404:
   - El backend no tiene servicios en el catálogo
   - Necesitas crear servicios en el backend primero

4. Para crear servicios en el backend (Laravel):
   ```bash
   php artisan tinker
   ```
   ```php
   \App\Models\Servicio::create([
       'codigo' => 'VAC001',
       'nombre' => 'Vacunación Antirrábica',
       'tipo' => 'vacuna',
       'precio' => 50.00,
       'duracion_minutos' => 30,
       'requiere_vacuna_info' => true
   ]);
   
   \App\Models\Servicio::create([
       'codigo' => 'CON001',
       'nombre' => 'Consulta General',
       'tipo' => 'consulta',
       'precio' => 80.00,
       'duracion_minutos' => 45,
       'requiere_vacuna_info' => false
   ]);
   ```

5. Refresca la app y verifica que ahora aparezcan los servicios

## Endpoints a verificar en Postman/Browser:

```
GET http://127.0.0.1:8000/api/servicios
Authorization: Bearer <tu_token>
```

Respuesta esperada:
```json
[
  {
    "id": 1,
    "codigo": "VAC001",
    "nombre": "Vacunación Antirrábica",
    "tipo": "vacuna",
    "precio": 50.00,
    "duracion_minutos": 30,
    "requiere_vacuna_info": true
  }
]
```

## Para verificar citas:

```
GET http://127.0.0.1:8000/api/citas
Authorization: Bearer <tu_token>
```

Respuesta esperada:
```json
[
  {
    "id": 1,
    "mascota_id": 5,
    "veterinario_id": 1,
    "fecha": "2025-11-10T13:30:00.000000Z",
    "motivo": "Control general",
    "estado": "pendiente"
  }
]
```
