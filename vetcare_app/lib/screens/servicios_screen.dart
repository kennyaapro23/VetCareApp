import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vetcare_app/providers/auth_provider.dart';
import 'package:vetcare_app/models/service_model.dart';
import 'package:vetcare_app/services/vet_service_service.dart';
import 'package:intl/intl.dart';

class ServiciosScreen extends StatefulWidget {
  const ServiciosScreen({super.key});

  @override
  State<ServiciosScreen> createState() => _ServiciosScreenState();
}

class _ServiciosScreenState extends State<ServiciosScreen> {
  List<ServiceModel> _services = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    setState(() => _loading = true);
    try {
      final auth = context.read<AuthProvider>();
      final service = VetServiceService(auth.api);
      final data = await service.getServices();
      setState(() => _services = data);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _createService() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const _CreateServiceDialog(),
    );
    if (result != null) {
      setState(() => _loading = true);
      try {
        final auth = context.read<AuthProvider>();
        final service = VetServiceService(auth.api);
        await service.createService(result);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Servicio creado exitosamente'), backgroundColor: Colors.green),
        );
        _loadServices();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      } finally {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Servicios Veterinarios'),
        actions: [
          IconButton(onPressed: _loadServices, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _services.isEmpty
              ? const Center(child: Text('No hay servicios registrados'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _services.length,
                  itemBuilder: (context, i) => _ServiceCard(service: _services[i]),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createService,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Servicio'),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final ServiceModel service;

  const _ServiceCard({required this.service});

  IconData _getIcon(String type) {
    final t = type.toLowerCase();
    if (t.contains('vacun')) return Icons.vaccines;
    if (t.contains('baño') || t.contains('bath')) return Icons.shower;
    if (t.contains('cort') || t.contains('groom')) return Icons.cut;
    if (t.contains('consult') || t.contains('control')) return Icons.medical_services;
    return Icons.pets;
  }

  Color _getColor(String type) {
    final t = type.toLowerCase();
    if (t.contains('vacun')) return Colors.blue;
    if (t.contains('baño') || t.contains('bath')) return Colors.cyan;
    if (t.contains('cort') || t.contains('groom')) return Colors.purple;
    if (t.contains('consult') || t.contains('control')) return Colors.green;
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr = service.date != null ? DateFormat('dd/MM/yyyy').format(service.date!) : 'Sin fecha';
    final color = _getColor(service.type);
    final icon = _getIcon(service.type);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(service.type, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  if (service.description != null && service.description!.isNotEmpty)
                    Text(service.description!, style: theme.textTheme.bodySmall),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(dateStr, style: theme.textTheme.bodySmall),
                      if (service.cost != null) ...[
                        const SizedBox(width: 16),
                        const Icon(Icons.attach_money, size: 14, color: Colors.grey),
                        Text('\$${service.cost!.toStringAsFixed(2)}', style: theme.textTheme.bodySmall),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateServiceDialog extends StatefulWidget {
  const _CreateServiceDialog();

  @override
  State<_CreateServiceDialog> createState() => _CreateServiceDialogState();
}

class _CreateServiceDialogState extends State<_CreateServiceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _petIdC = TextEditingController();
  final _descC = TextEditingController();
  final _costC = TextEditingController();
  String _serviceType = 'Vacunación';
  DateTime? _selectedDate;

  @override
  void dispose() {
    _petIdC.dispose();
    _descC.dispose();
    _costC.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecciona la fecha del servicio')));
      return;
    }
    Navigator.pop(context, {
      'mascota_id': _petIdC.text.trim(),
      'tipo_servicio': _serviceType,
      'descripcion': _descC.text.trim(),
      'fecha': _selectedDate!.toIso8601String(),
      'costo': double.tryParse(_costC.text.trim()) ?? 0.0,
    });
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = _selectedDate != null ? DateFormat('dd/MM/yyyy').format(_selectedDate!) : 'Seleccionar';

    return AlertDialog(
      title: const Text('Nuevo Servicio'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _petIdC,
                decoration: const InputDecoration(labelText: 'ID Mascota'),
                validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _serviceType,
                items: const [
                  DropdownMenuItem(value: 'Vacunación', child: Text('Vacunación')),
                  DropdownMenuItem(value: 'Baño', child: Text('Baño')),
                  DropdownMenuItem(value: 'Corte de pelo', child: Text('Corte de pelo')),
                  DropdownMenuItem(value: 'Control general', child: Text('Control general')),
                  DropdownMenuItem(value: 'Otro', child: Text('Otro')),
                ],
                onChanged: (v) => setState(() => _serviceType = v ?? 'Vacunación'),
                decoration: const InputDecoration(labelText: 'Tipo de servicio'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descC,
                decoration: const InputDecoration(labelText: 'Descripción'),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _costC,
                decoration: const InputDecoration(labelText: 'Costo'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text(dateStr),
                onTap: _pickDate,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(onPressed: _submit, child: const Text('Crear')),
      ],
    );
  }
}

