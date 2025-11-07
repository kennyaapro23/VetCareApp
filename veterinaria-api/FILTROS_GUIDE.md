# 🔍 Guía de Filtros y Búsquedas - API Veterinaria

## 📋 Filosofía de Filtrado

### ✅ **Backend (Recomendado)**
- Filtros complejos con JOIN
- Búsquedas en texto
- Rangos de fechas
- Paginación eficiente
- Mejor rendimiento

### ❌ **Frontend (No recomendado para grandes datasets)**
- Solo para filtros simples en listas pequeñas
- Datos ya cargados en memoria
- Sin llamadas adicionales al servidor

---

## 🎯 Endpoints con Filtros

### 1. Historial Médico - GET `/api/historial-medico`

#### Filtros Disponibles:

| Parámetro | Tipo | Descripción | Ejemplo |
|-----------|------|-------------|---------|
| `mascota_id` | int | ID de mascota específica | `?mascota_id=5` |
| `veterinario_id` | int | ID del veterinario | `?veterinario_id=2` |
| `tipo` | string | Tipo de consulta | `?tipo=vacuna` |
| `fecha_desde` | date | Fecha inicial (YYYY-MM-DD) | `?fecha_desde=2025-01-01` |
| `fecha_hasta` | date | Fecha final (YYYY-MM-DD) | `?fecha_hasta=2025-12-31` |
| `nombre_mascota` | string | Búsqueda por nombre de mascota | `?nombre_mascota=Max` |
| `nombre_cliente` | string | Búsqueda por nombre de dueño | `?nombre_cliente=Juan` |
| `search` | string | Búsqueda general (diagnóstico, tratamiento, observaciones) | `?search=parvovirus` |

#### Tipos de Historial:
- `consulta`
- `vacuna`
- `procedimiento`
- `control`
- `otro`

#### Ejemplos Flutter:

```dart
// Filtrar por mascota y rango de fechas
final response = await api.get(
  'historial-medico?mascota_id=5&fecha_desde=2025-01-01&fecha_hasta=2025-12-31'
);

// Buscar por nombre de cliente
final response = await api.get(
  'historial-medico?nombre_cliente=Juan Pérez'
);

// Búsqueda general en diagnósticos
final response = await api.get(
  'historial-medico?search=alergia'
);

// Combinar múltiples filtros
final response = await api.get(
  'historial-medico?tipo=vacuna&fecha_desde=2025-01-01&nombre_mascota=Max'
);
```

---

### 2. Citas - GET `/api/citas`

#### Filtros Disponibles:

| Parámetro | Tipo | Descripción | Ejemplo |
|-----------|------|-------------|---------|
| `veterinario_id` | int | ID del veterinario | `?veterinario_id=2` |
| `cliente_id` | int | ID del cliente | `?cliente_id=3` |
| `mascota_id` | int | ID de la mascota | `?mascota_id=5` |
| `fecha` | date | Fecha exacta | `?fecha=2025-01-20` |
| `fecha_desde` | date | Fecha inicial | `?fecha_desde=2025-01-01` |
| `fecha_hasta` | date | Fecha final | `?fecha_hasta=2025-01-31` |
| `estado` | string | Estado de la cita | `?estado=programada` |
| `nombre_mascota` | string | Búsqueda por nombre de mascota | `?nombre_mascota=Luna` |
| `nombre_cliente` | string | Búsqueda por nombre de cliente | `?nombre_cliente=María` |
| `nombre_veterinario` | string | Búsqueda por nombre de veterinario | `?nombre_veterinario=García` |
| `search` | string | Búsqueda general (motivo, notas) | `?search=vacunación` |

#### Estados de Cita:
- `programada`
- `confirmada`
- `en_curso`
- `completada`
- `cancelada`

#### Ejemplos Flutter:

```dart
// Citas del día
final response = await api.get(
  'citas?fecha=${DateTime.now().toIso8601String().split('T')[0]}'
);

// Citas de un veterinario en un rango de fechas
final response = await api.get(
  'citas?veterinario_id=2&fecha_desde=2025-01-01&fecha_hasta=2025-01-31'
);

// Buscar citas por mascota
final response = await api.get(
  'citas?nombre_mascota=Max'
);

// Citas pendientes de un cliente
final response = await api.get(
  'citas?cliente_id=3&estado=programada'
);

// Búsqueda general
final response = await api.get(
  'citas?search=vacuna antirrábica'
);
```

---

### 3. Mascotas - GET `/api/mascotas`

#### Filtros Disponibles:

| Parámetro | Tipo | Descripción | Ejemplo |
|-----------|------|-------------|---------|
| `cliente_id` | int | Filtrar por dueño | `?cliente_id=3` |
| `especie` | string | Filtrar por especie | `?especie=perro` |
| `search` | string | Búsqueda por nombre | `?search=Max` |

#### Especies:
- `perro`
- `gato`
- `ave`
- `reptil`
- `otro`

#### Ejemplos Flutter:

```dart
// Mascotas de un cliente
final response = await api.get('mascotas?cliente_id=3');

// Buscar todas las mascotas llamadas "Max"
final response = await api.get('mascotas?search=Max');

// Solo perros
final response = await api.get('mascotas?especie=perro');
```

---

### 4. Servicios - GET `/api/servicios`

#### Filtros Disponibles:

| Parámetro | Tipo | Descripción | Ejemplo |
|-----------|------|-------------|---------|
| `tipo` | string | Tipo de servicio | `?tipo=vacuna` |
| `search` | string | Búsqueda por nombre o código | `?search=antirrábica` |
| `precio_min` | decimal | Precio mínimo | `?precio_min=50` |
| `precio_max` | decimal | Precio máximo | `?precio_max=200` |

#### Tipos de Servicio:
- `vacuna`
- `tratamiento`
- `baño`
- `consulta`
- `cirugía`
- `otro`

#### Ejemplos Flutter:

```dart
// Solo vacunas
final response = await api.get('servicios?tipo=vacuna');

// Servicios entre $50 y $200
final response = await api.get('servicios?precio_min=50&precio_max=200');

// Buscar por nombre
final response = await api.get('servicios?search=antirrábica');
```

---

### 5. Notificaciones - GET `/api/notificaciones`

#### Filtros Disponibles:

| Parámetro | Tipo | Descripción | Ejemplo |
|-----------|------|-------------|---------|
| `leida` | boolean | Filtrar por leídas/no leídas | `?leida=false` |
| `tipo` | string | Tipo de notificación | `?tipo=recordatorio_cita` |

#### Tipos de Notificación:
- `recordatorio_cita`
- `cita_creada`
- `cita_cancelada`
- `cita_modificada`
- `vacuna_proxima`
- `resultado_disponible`
- `mensaje_veterinario`
- `otro`

#### Ejemplos Flutter:

```dart
// Solo no leídas
final response = await api.get('notificaciones?leida=false');

// Solo recordatorios de cita
final response = await api.get('notificaciones?tipo=recordatorio_cita');
```

---

### 6. Facturas - GET `/api/facturas`

#### Filtros Disponibles:

| Parámetro | Tipo | Descripción | Ejemplo |
|-----------|------|-------------|---------|
| `estado` | string | Estado de factura | `?estado=pendiente` |
| `fecha_desde` | date | Fecha inicial de emisión | `?fecha_desde=2025-01-01` |
| `fecha_hasta` | date | Fecha final de emisión | `?fecha_hasta=2025-12-31` |
| `numero_factura` | string | Búsqueda por número | `?numero_factura=FAC-2025` |

#### Estados de Factura:
- `pendiente`
- `pagado`
- `anulado`

#### Ejemplos Flutter:

```dart
// Facturas pendientes
final response = await api.get('facturas?estado=pendiente');

// Facturas del mes
final response = await api.get(
  'facturas?fecha_desde=2025-01-01&fecha_hasta=2025-01-31'
);

// Buscar factura por número
final response = await api.get('facturas?numero_factura=FAC-2025-00001');
```

---

## 🎨 Componente de Filtros en Flutter

### Ejemplo Genérico:

```dart
class FiltrosWidget extends StatefulWidget {
  final Function(Map<String, String>) onApplyFilters;

  FiltrosWidget({required this.onApplyFilters});

  @override
  _FiltrosWidgetState createState() => _FiltrosWidgetState();
}

class _FiltrosWidgetState extends State<FiltrosWidget> {
  final _searchController = TextEditingController();
  DateTime? _fechaDesde;
  DateTime? _fechaHasta;
  String? _selectedTipo;

  void _aplicarFiltros() {
    Map<String, String> filtros = {};

    if (_searchController.text.isNotEmpty) {
      filtros['search'] = _searchController.text;
    }

    if (_fechaDesde != null) {
      filtros['fecha_desde'] = _fechaDesde!.toIso8601String().split('T')[0];
    }

    if (_fechaHasta != null) {
      filtros['fecha_hasta'] = _fechaHasta!.toIso8601String().split('T')[0];
    }

    if (_selectedTipo != null) {
      filtros['tipo'] = _selectedTipo!;
    }

    widget.onApplyFilters(filtros);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Campo de búsqueda
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            labelText: 'Buscar',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        
        SizedBox(height: 16),
        
        // Selector de fechas
        Row(
          children: [
            Expanded(
              child: TextButton.icon(
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (date != null) {
                    setState(() => _fechaDesde = date);
                  }
                },
                icon: Icon(Icons.calendar_today),
                label: Text(_fechaDesde != null
                    ? 'Desde: ${DateFormat('dd/MM/yyyy').format(_fechaDesde!)}'
                    : 'Fecha inicial'),
              ),
            ),
            Expanded(
              child: TextButton.icon(
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (date != null) {
                    setState(() => _fechaHasta = date);
                  }
                },
                icon: Icon(Icons.calendar_today),
                label: Text(_fechaHasta != null
                    ? 'Hasta: ${DateFormat('dd/MM/yyyy').format(_fechaHasta!)}'
                    : 'Fecha final'),
              ),
            ),
          ],
        ),
        
        SizedBox(height: 16),
        
        // Dropdown de tipo
        DropdownButtonFormField<String>(
          value: _selectedTipo,
          decoration: InputDecoration(labelText: 'Tipo'),
          items: [
            DropdownMenuItem(value: 'vacuna', child: Text('Vacuna')),
            DropdownMenuItem(value: 'consulta', child: Text('Consulta')),
            DropdownMenuItem(value: 'procedimiento', child: Text('Procedimiento')),
          ],
          onChanged: (value) {
            setState(() => _selectedTipo = value);
          },
        ),
        
        SizedBox(height: 16),
        
        // Botones
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _aplicarFiltros,
                child: Text('Aplicar Filtros'),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                    _fechaDesde = null;
                    _fechaHasta = null;
                    _selectedTipo = null;
                  });
                  widget.onApplyFilters({});
                },
                child: Text('Limpiar'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
```

### Uso del Widget:

```dart
class HistorialScreen extends StatefulWidget {
  @override
  _HistorialScreenState createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  final _api = ApiService();
  List<HistorialMedico> _historial = [];
  bool _loading = false;
  bool _showFilters = false;

  Future<void> _loadHistorial([Map<String, String>? filtros]) async {
    setState(() => _loading = true);
    
    // Construir query params
    String queryParams = '';
    if (filtros != null && filtros.isNotEmpty) {
      queryParams = '?' + filtros.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');
    }
    
    try {
      final response = await _api.get('historial-medico$queryParams');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _historial = (data['data'] as List)
              .map((json) => HistorialMedico.fromJson(json))
              .toList();
        });
      }
    } catch (e) {
      print('Error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadHistorial();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Historial Médico'),
        actions: [
          IconButton(
            icon: Icon(_showFilters ? Icons.filter_list_off : Icons.filter_list),
            onPressed: () {
              setState(() => _showFilters = !_showFilters);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (_showFilters)
            Card(
              margin: EdgeInsets.all(16),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: FiltrosWidget(
                  onApplyFilters: (filtros) {
                    _loadHistorial(filtros);
                    setState(() => _showFilters = false);
                  },
                ),
              ),
            ),
          Expanded(
            child: _loading
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _historial.length,
                    itemBuilder: (context, index) {
                      final item = _historial[index];
                      return ListTile(
                        title: Text(item.mascota.nombre),
                        subtitle: Text(item.diagnostico ?? ''),
                        trailing: Text(
                          DateFormat('dd/MM/yyyy').format(item.fecha),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
```

---

## 📊 Paginación

Todos los endpoints retornan datos paginados:

```json
{
  "data": [...],
  "current_page": 1,
  "last_page": 5,
  "per_page": 20,
  "total": 100,
  "next_page_url": "http://api.com/api/historial-medico?page=2",
  "prev_page_url": null
}
```

### Cargar más páginas:

```dart
final response = await api.get('historial-medico?page=2&mascota_id=5');
```

---

## ✅ Resumen

### ✅ **Haz en Backend:**
- Filtros complejos con JOIN
- Búsquedas en texto (`LIKE`)
- Rangos de fechas
- Filtros combinados

### 📱 **Haz en Frontend:**
- UI de filtros
- Validación de campos
- Construcción de query params
- Mostrar resultados

### 🚫 **NO hagas en Frontend:**
- Traer todos los datos y filtrar localmente
- Queries SQL
- Lógica de paginación

---

## 📞 Soporte

Para más detalles sobre endpoints específicos, consulta [API_DOCUMENTATION.md](API_DOCUMENTATION.md).
