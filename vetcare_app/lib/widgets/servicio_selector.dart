import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vetcare_app/models/catalog_service_model.dart';
import 'package:vetcare_app/services/service_service.dart';
import 'package:vetcare_app/services/api_service.dart';
import 'package:vetcare_app/theme/app_theme.dart';

class SelectedServicio {
  final CatalogServiceModel service;
  int cantidad;
  double precioUnitario;
  String? notas;

  SelectedServicio({
    required this.service,
    this.cantidad = 1,
    double? precioUnitario,
    this.notas,
  }) : precioUnitario = precioUnitario ?? service.price;

  double get subtotal => cantidad * precioUnitario;

  Map<String, dynamic> toJsonPivot() => {
        'servicio_id': service.id,
        'cantidad': cantidad,
        'precio_unitario': precioUnitario,
        'notas': notas,
      };
}

class ServicioSelector extends StatefulWidget {
  final List<SelectedServicio> initial;
  final ValueChanged<List<SelectedServicio>>? onChanged;

  const ServicioSelector({super.key, this.initial = const [], this.onChanged});

  @override
  State<ServicioSelector> createState() => _ServicioSelectorState();
}

class _ServicioSelectorState extends State<ServicioSelector> {
  List<CatalogServiceModel> _catalog = [];
  List<SelectedServicio> _selected = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.initial);
    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    setState(() => _isLoading = true);
    try {
      final api = context.read<ApiService>();
      final svc = ServiceService(api);
      final list = await svc.getServices();
      if (mounted) setState(() {
        _catalog = list;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error cargando servicios: $e')));
    }
  }

  void _addService(CatalogServiceModel s) {
    final exists = _selected.any((e) => e.service.id == s.id);
    if (exists) return;
    setState(() {
      _selected.add(SelectedServicio(service: s));
    });
    widget.onChanged?.call(_selected);
  }

  void _removeService(SelectedServicio ss) {
    setState(() => _selected.remove(ss));
    widget.onChanged?.call(_selected);
  }

  double get total => _selected.fold(0.0, (t, e) => t + e.subtotal);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Servicios aplicados', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _isLoading
            ? const Center(child: CircularProgressIndicator())
            : DropdownButtonFormField<CatalogServiceModel>(
                items: _catalog
                    .map((s) => DropdownMenuItem(value: s, child: Text('${s.name}  —  ${s.code}')))
                    .toList(),
                onChanged: (s) {
                  if (s != null) _addService(s);
                },
                decoration: const InputDecoration(labelText: 'Agregar servicio'),
              ),
        const SizedBox(height: 12),
        if (_selected.isEmpty)
          Text('No hay servicios seleccionados', style: TextStyle(color: isDark ? AppTheme.textSecondary : AppTheme.textLight)),
        ..._selected.map((ss) {
          return Container(
            margin: const EdgeInsets.only(top: 8, bottom: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: Text(ss.service.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                    IconButton(onPressed: () => _removeService(ss), icon: const Icon(Icons.close, size: 18))
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: ss.cantidad.toString(),
                        keyboardType: const TextInputType.numberWithOptions(decimal: false),
                        decoration: const InputDecoration(labelText: 'Cantidad'),
                        onChanged: (v) {
                          final n = int.tryParse(v) ?? 1;
                          setState(() => ss.cantidad = n);
                          widget.onChanged?.call(_selected);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        initialValue: ss.precioUnitario.toStringAsFixed(2),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Precio unitario'),
                        onChanged: (v) {
                          final d = double.tryParse(v) ?? ss.service.price;
                          setState(() => ss.precioUnitario = d);
                          widget.onChanged?.call(_selected);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: ss.notas ?? '',
                  decoration: const InputDecoration(labelText: 'Notas (opcional)'),
                  onChanged: (v) {
                    setState(() => ss.notas = v);
                    widget.onChanged?.call(_selected);
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Subtotal', style: TextStyle(color: isDark ? AppTheme.textSecondary : AppTheme.textLight)),
                    Text('\$${ss.subtotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Total servicios', style: TextStyle(fontWeight: FontWeight.w700)),
            Text('\$${total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ],
    );
  }
}

