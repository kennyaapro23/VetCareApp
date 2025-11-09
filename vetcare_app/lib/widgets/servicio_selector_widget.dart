import 'package:flutter/material.dart';

/// Widget reutilizable para seleccionar múltiples servicios, editar cantidad,
/// precio unitario y notas por servicio. Devuelve la lista de servicios
/// seleccionados mediante callbacks.
///
/// Modelo interno esperado:
/// {
///   "id": int,
///   "nombre": String,
///   "precio": double,
/// }

class ServicioSeleccionado {
  final int id;
  final String nombre;
  int cantidad;
  double precioUnitario;
  String notas;

  ServicioSeleccionado({
    required this.id,
    required this.nombre,
    this.cantidad = 1,
    required this.precioUnitario,
    this.notas = '',
  });

  Map<String, dynamic> toJson() => {
        'servicio_id': id,
        'cantidad': cantidad,
        'precio_unitario': precioUnitario,
        'notas': notas,
      };
}

class ServicioSelectorWidget extends StatefulWidget {
  final List<Map<String, dynamic>> serviciosDisponibles;
  final List<ServicioSeleccionado>? initialSelected;
  final ValueChanged<List<ServicioSeleccionado>>? onChanged;

  const ServicioSelectorWidget({
    Key? key,
    required this.serviciosDisponibles,
    this.initialSelected,
    this.onChanged,
  }) : super(key: key);

  @override
  _ServicioSelectorWidgetState createState() => _ServicioSelectorWidgetState();
}

class _ServicioSelectorWidgetState extends State<ServicioSelectorWidget> {
  final List<ServicioSeleccionado> _seleccionados = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialSelected != null) {
      _seleccionados.addAll(widget.initialSelected!);
    }
  }

  void _notify() {
    widget.onChanged?.call(List.unmodifiable(_seleccionados));
    setState(() {});
  }

  double get total => _seleccionados.fold(
      0.0, (s, e) => s + (e.cantidad * e.precioUnitario));

  void _toggleServicio(Map<String, dynamic> servicio) {
    final id = servicio['id'] as int;
    final existingIndex = _seleccionados.indexWhere((s) => s.id == id);
    if (existingIndex >= 0) {
      _seleccionados.removeAt(existingIndex);
    } else {
      final precio = (servicio['precio'] is num) ? (servicio['precio'] as num).toDouble() : 0.0;
      _seleccionados.add(ServicioSeleccionado(
        id: id,
        nombre: servicio['nombre'] ?? servicio['nombre'] ?? 'Servicio',
        precioUnitario: precio,
      ));
    }
    _notify();
  }

  Widget _buildServicioTile(Map<String, dynamic> servicio) {
    final id = servicio['id'] as int;
    final selected = _seleccionados.any((s) => s.id == id);
    final precio = (servicio['precio'] is num) ? (servicio['precio'] as num).toDouble() : 0.0;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      leading: Checkbox(
        value: selected,
        onChanged: (_) => _toggleServicio(servicio),
      ),
      title: Text(servicio['nombre'] ?? 'Servicio'),
      subtitle: Text('Precio base: ${precio.toStringAsFixed(2)}'),
      trailing: selected
          ? IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showEditDialog(servicio),
            )
          : null,
      onTap: () => _toggleServicio(servicio),
    );
  }

  void _showEditDialog(Map<String, dynamic> servicio) {
    final id = servicio['id'] as int;
    final index = _seleccionados.indexWhere((s) => s.id == id);
    if (index < 0) return; // seguridad

    final sel = _seleccionados[index];
    final cantidadCtrl = TextEditingController(text: sel.cantidad.toString());
    final precioCtrl = TextEditingController(text: sel.precioUnitario.toStringAsFixed(2));
    final notasCtrl = TextEditingController(text: sel.notas);

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Editar: ${sel.nombre}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: cantidadCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Cantidad'),
              ),
              TextField(
                controller: precioCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Precio unitario'),
              ),
              TextField(
                controller: notasCtrl,
                minLines: 1,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Notas (opcional)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final cantidad = int.tryParse(cantidadCtrl.text) ?? sel.cantidad;
              final precio = double.tryParse(precioCtrl.text) ?? sel.precioUnitario;
              sel.cantidad = cantidad > 0 ? cantidad : 1;
              sel.precioUnitario = precio >= 0 ? precio : 0.0;
              sel.notas = notasCtrl.text;
              _notify();
              Navigator.of(context).pop();
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Servicios disponibles', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Container(
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(6),
          ),
          child: ListView.separated(
            itemCount: widget.serviciosDisponibles.length,
            itemBuilder: (context, index) => _buildServicioTile(widget.serviciosDisponibles[index]),
            separatorBuilder: (_, __) => const Divider(height: 1),
          ),
        ),
        const SizedBox(height: 12),
        Text('Servicios seleccionados', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (_seleccionados.isEmpty)
          const Text('No hay servicios seleccionados')
        else
          ..._seleccionados.map((s) => Card(
                margin: const EdgeInsets.symmetric(vertical: 4.0),
                child: ListTile(
                  title: Text(s.nombre),
                  subtitle: Text('Cantidad: ${s.cantidad} • Precio: ${s.precioUnitario.toStringAsFixed(2)}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () {
                          if (s.cantidad > 1) s.cantidad--;
                          _notify();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () {
                          s.cantidad++;
                          _notify();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () {
                          _seleccionados.removeWhere((e) => e.id == s.id);
                          _notify();
                        },
                      ),
                    ],
                  ),
                ),
              )),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: Text('Total: ${total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
