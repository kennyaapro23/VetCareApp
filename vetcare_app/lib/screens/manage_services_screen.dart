import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vetcare_app/services/service_service.dart';
import 'package:vetcare_app/models/catalog_service_model.dart';
import 'package:vetcare_app/services/api_service.dart';
import 'package:vetcare_app/theme/app_theme.dart';

class ManageServicesScreen extends StatefulWidget {
  const ManageServicesScreen({super.key});

  @override
  State<ManageServicesScreen> createState() => _ManageServicesScreenState();
}

class _ManageServicesScreenState extends State<ManageServicesScreen> {
  List<CatalogServiceModel> _services = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    setState(() => _isLoading = true);
    try {
      final api = context.read<ApiService>();
      final service = ServiceService(api);
      final list = await service.getServices();
      if (mounted) setState(() {
        _services = list;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cargando servicios: $e')),
      );
    }
  }

  Future<void> _showServiceForm({CatalogServiceModel? model}) async {
    final codeCtrl = TextEditingController(text: model?.code ?? '');
    final nameCtrl = TextEditingController(text: model?.name ?? '');
    final descCtrl = TextEditingController(text: model?.description ?? '');
    final priceCtrl = TextEditingController(text: model?.price.toString() ?? '0.0');
    final taxCtrl = TextEditingController(text: model?.taxPercent.toString() ?? '0.0');

    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(model == null ? 'Crear Servicio' : 'Editar Servicio'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: codeCtrl,
                  decoration: const InputDecoration(labelText: 'Código'),
                  validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Descripción (opcional)'),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: priceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Precio'),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Requerido';
                    if (double.tryParse(v) == null) return 'Número inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: taxCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Impuesto %'),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Requerido';
                    if (double.tryParse(v) == null) return 'Número inválido';
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('CANCELAR')),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final api = context.read<ApiService>();
              final service = ServiceService(api);
              final data = {
                'code': codeCtrl.text.trim(),
                'name': nameCtrl.text.trim(),
                'description': descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                'price': double.tryParse(priceCtrl.text.trim()) ?? 0.0,
                'tax_percent': double.tryParse(taxCtrl.text.trim()) ?? 0.0,
              };

              try {
                if (model == null) {
                  await service.createService(data);
                } else {
                  await service.updateService(model.id.toString(), data);
                }
                Navigator.of(context).pop(true);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('GUARDAR'),
          ),
        ],
      ),
    );

    if (result == true) _loadServices();
  }

  Future<void> _confirmDelete(CatalogServiceModel model) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Eliminar servicio "${model.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCELAR')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('ELIMINAR')),
        ],
      ),
    );

    if (ok == true) {
      try {
        final api = context.read<ApiService>();
        final service = ServiceService(api);
        await service.deleteService(model.id.toString());
        _loadServices();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo eliminar: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Servicios'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadServices,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _services.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final s = _services[index];
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkCard : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(child: Icon(Icons.medical_services, color: AppTheme.primaryColor)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  const SizedBox(width: 8),
                                  Text('(${s.code})', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                              if (s.description != null && s.description!.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(s.description!, style: TextStyle(color: isDark ? AppTheme.textSecondary : AppTheme.textLight)),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('\$${s.price.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                IconButton(
                                  onPressed: () => _showServiceForm(model: s),
                                  icon: const Icon(Icons.edit, size: 20),
                                ),
                                IconButton(
                                  onPressed: () => _confirmDelete(s),
                                  icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                                ),
                              ],
                            ),
                          ],
                        )
                      ],
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showServiceForm(),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }
}
